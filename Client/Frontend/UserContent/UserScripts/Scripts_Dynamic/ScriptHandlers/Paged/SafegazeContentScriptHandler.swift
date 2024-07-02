// Copyright 2022 The Kahf Browser Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import WebKit
import BraveCore
import BraveShared
import Data
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
        let scriptSetup = "window.blurIntensity = \(Preferences.Safegaze.blurIntensity.value);"
        guard var script = loadUserScript(named: scriptName) else {
            return nil
        }
        
        return WKUserScript.create(source: secureScript(handlerName: messageHandlerName,
                                                        securityToken: scriptId,
                                                        script: scriptSetup + script),
                                   injectionTime: .atDocumentEnd,
                                   forMainFrameOnly: false,
                                   in: scriptSandbox)
    }()
    
    private weak var tab: Tab?
    let nsfwDetector = NsfwDetector()
    let genderDetector = GenderDetector()

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
        // Use a background queue for network operations
        DispatchQueue.global(qos: .userInitiated).async {
            self.asyncDownloadImage(from: imageURL) { imageData in
                guard let imageData = imageData else {
                    DispatchQueue.main.async {
                        completion(true)
                    }
                    return
                }

                guard let image = UIImage(data: imageData) else {
                    return
                }
                
                if let prediction = self.nsfwDetector.isNsfw(bitmap: image) {

                    if prediction.isSafe() {
                        print("**NSFW: isSafe")
                        
                        self.genderDetector.predict(image: image, data: imageData) { prediction in
                            print("Gender prediction \(prediction.hasFemale)")
                        }
                    } else {
                        print("**NSFW: isNotSafe")
                    }
                } else {
                    print("**NSFW Failed to get prediction.")
                }

                // Notify on the main queue when the background tasks are completed
                DispatchQueue.main.async {
                    completion(true)
                }
            }
        }
    }

    func asyncDownloadImage(from imageURL: URL, completion: @escaping (Data?) -> Void) {
        URLSession.shared.dataTask(with: imageURL) { data, _, error in
            if let error = error {
                print("Error downloading image: \(error.localizedDescription)")
                completion(nil)
            } else {
                completion(data)
            }
        }.resume()
    }
    
    func asyncDownloadAndConvertToBase64(for imageStrings: [String], completion: @escaping ([String?]) -> Void) {
        let dispatchGroup = DispatchGroup()
        var base64Strings: [String?] = []

        for imageURLString in imageStrings {
            guard let imageURL = URL(string: imageURLString) else {
                // Invalid URL string, append nil to the result
                base64Strings.append(nil)
                continue
            }

            dispatchGroup.enter()

            asyncDownloadImage(from: imageURL) { data in
                defer {
                    dispatchGroup.leave()
                }

                if let imageData = data {
                    let base64String = imageData.base64EncodedString()
                    base64Strings.append(base64String)
                } else {
                    // Failed to download image, append nil to the result
                    base64Strings.append(nil)
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            completion(base64Strings)
        }
    }
}

