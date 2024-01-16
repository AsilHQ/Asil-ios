// Copyright 2022 The Asil Browser Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import WebKit
import BraveCore
import BraveShared
import Data
import Vision
import CoreMedia

class SafegazeContentScriptHandler: TabContentScript {
    private struct RequestBlockingDTO: Decodable {
        struct RequestBlockingDTOData: Decodable, Hashable {
            let resourceType: AdblockEngine.ResourceType
            let resourceURL: String
            let sourceURL: String
        }
        
        let securityToken: String
        let data: RequestBlockingDTOData
    }
    
    static let scriptName = "SafegazeScript"
    static let scriptId = UUID().uuidString
    static let messageHandlerName = "safegazeMessageHandler"
    static let scriptSandbox: WKContentWorld = .page
    static let userScript: WKUserScript? = {
        guard var script = loadUserScript(named: scriptName) else {
            return nil
        }
        
        return WKUserScript.create(source: secureScript(handlerName: messageHandlerName,
                                                        securityToken: scriptId,
                                                        script: script),
                                   injectionTime: .atDocumentEnd,
                                   forMainFrameOnly: false,
                                   in: scriptSandbox)
    }()
    
    private weak var tab: Tab?
    var request: VNCoreMLRequest?
    var visionModel: VNCoreMLModel?
    
    init(tab: Tab) {
        self.tab = tab
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let tab = tab, let currentTabURL = tab.webView?.url else {
            assertionFailure("Should have a tab set")
            return
        }
        
        if !verifyMessage(message: message) {
            assertionFailure("Invalid security token. Fix the `safegaze.js` script")
            replyHandler(false, nil)
            return
        }
        
        if let dict = message.body as? [String: Any], let message = dict["state"] as? String {
            if message == "replaced" {
                BraveGlobalShieldStats.shared.safegazeCount += 1
                tab.contentBlocker.stats = tab.contentBlocker.stats.adding(safegazeCount: 1)
            } else if message.contains("coreML") {
                let messageArray = message.components(separatedBy: "/-/")
                if messageArray.count == 3 {
                    if let url = URL(string: messageArray[1]) {
                        if #available(iOS 15.0, *) {
                            downloadAndProcessImage(from: url) { isExist in
                                let jsString =
                                """
                                    (function() {
                                        safegazeOnDeviceModelHandler(\(isExist),\(messageArray[2]));
                                    })();
                                """
                                    
                                tab.webView?.evaluateSafeJavaScript(functionName: jsString, contentWorld: .page, asFunction: false) { object, error in
                                    if let error = error {
                                        print("SafegazeContentScriptHandler coreML script\(error)")
                                    }
                                }
                            }
                        } else {
                            print("do nothing")
                        }
                    }
                   
                }
            } else {
                print("Safegaze: " + message)
            }
        }
    }
    
    @available(iOS 15.0, *)
    func downloadAndProcessImage(from imageURL: URL, completion: @escaping (Bool) -> Void) {
        // Capture start time for downloading
        let downloadStartTime = DispatchTime.now()

        // Use a background queue for network operations
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Download the image asynchronously
                let imageData = try Data(contentsOf: imageURL)
                
                // Capture end time for downloading
                let downloadEndTime = DispatchTime.now()

                let imageHandler = VNImageRequestHandler(data: imageData)

                var humanCount = 0
                var faceCount = 0

                // Capture start time for processing
                let processingStartTime = DispatchTime.now()

                let humanRequest = VNDetectHumanRectanglesRequest { request, error in
                    // Process the results for human detection
                    if let humanObservations = request.results as? [VNHumanObservation] {
                        humanCount = humanObservations.count
                    }
                }
                humanRequest.usesCPUOnly = true

                let faceRequest = VNDetectFaceRectanglesRequest { request, error in
                    // Process the results for face detection
                    if let faceObservations = request.results as? [VNFaceObservation] {
                        faceCount = faceObservations.count
                    }
                }
                faceRequest.usesCPUOnly = true

                // Perform the requests on the image handler
                try? imageHandler.perform([humanRequest, faceRequest])

                // Capture end time for processing
                let processingEndTime = DispatchTime.now()

                // Notify on the main queue when the background tasks are completed
                DispatchQueue.main.async {
                    /* Calculate the downloading duration
                    let downloadNanoseconds = downloadEndTime.uptimeNanoseconds - downloadStartTime.uptimeNanoseconds
                    let downloadSeconds = Double(downloadNanoseconds) / 1_000_000_000

                    // Calculate the processing duration
                    let processingNanoseconds = processingEndTime.uptimeNanoseconds - processingStartTime.uptimeNanoseconds
                    let processingSeconds = Double(processingNanoseconds) / 1_000_000_000

                    print("**Image downloading completed in \(downloadSeconds) seconds.")
                    print("**Both human and face detection completed in \(processingSeconds) seconds.") */

                    completion(humanCount + faceCount > 0 )
                }

            } catch {
                print("Error downloading or processing image: \(error.localizedDescription)")
            }
        }
    }
}

