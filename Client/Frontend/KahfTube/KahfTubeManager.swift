// Copyright 2023 The Asil Browser Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import WebKit
import BraveShared

public class KahfTubeManager: ObservableObject {
    public static let shared = KahfTubeManager()
    private let webRepository = KahfTubeWebRepository.shared
    private let util = KahfTubeUtil.shared
    private static var webView: WKWebView?
    @Published var haramChannels: [Channel] = [Channel]()
    @Published var haramChannelsMap: Dictionary<String, Any> = Dictionary<String, Any>()
    @Published var channelsFetched: Bool = false
    @Published var newUserRefreshNeeded = false
    
    
    public func startKahfTube(view: UIView, webView: WKWebView, vc: UIViewController) {
        KahfTubeManager.webView = webView
        if let url = webView.url?.absoluteString, url.contains("youtube.com") {
            print("Kahf Tube: User is on a YouTube page")
            if Preferences.KahfTube.isOn.value {
                self.filter(webView: webView)
                getUserInformationsFromYoutube(view: view, webView: webView)
            } else {
                let refreshAlert = UIAlertController(title: "Kahf Tube", message: "Kahf Tube wants your permission to access your Youtube email and name to use Youtube Fitration feature.", preferredStyle: UIAlertController.Style.alert)

                refreshAlert.addAction(UIAlertAction(title: "Allow", style: .default, handler: { (action: UIAlertAction!) in
                    Preferences.KahfTube.isOn.value = true
                    self.getUserInformationsFromYoutube(view: view, webView: webView)
                }))

                refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                    Preferences.KahfTube.isOn.value = false
                }))
                
                vc.present(refreshAlert, animated: true, completion: nil)
            }
        } else {
            print("Kahf Tube: User is not on a YouTube page")
        }
    }
    
    func getUserInformationsFromYoutube(view: UIView, webView: WKWebView) {
        let hiddenView = WKWebView(frame: CGRect(width: view.bounds.width, height: view.bounds.height - 100))
        hiddenView.isHidden = true
        view.addSubview(hiddenView)
        let erik = Erik(webView: hiddenView)
        Erik.sharedInstance = erik
        erik.visit(url: URL(string: "https://m.youtube.com/")!) { object, error in
            self.getEmail(erik: erik)
        }
    }
    
    func saveYoutubeInformations(dict: [String: Any]) {
        if let email = dict["email"] as? String, let name = dict["name"] as? String, let imgSrc = dict["imgSrc"] as? String {
            if email != Preferences.KahfTube.email.value || Preferences.KahfTube.token.value == nil || Preferences.KahfTube.token.value == "" {
                KahfTubeManager.shared.newUserRefreshNeeded = true
                self.closeVideoPreviews()
                webRepository.authSession(email: email, name: name) { dict, error in
                    if let dict = dict, let token = dict["token"] {
                        Preferences.KahfTube.email.value = email
                        Preferences.KahfTube.username.value = name
                        Preferences.KahfTube.imageURL.value = imgSrc
                        Preferences.KahfTube.token.value = token
                    } else {
                        print("Kahf Tube: Auth failed")
                    }
                }
            } else {
                print("Kahf Tube: Already signed-in \(Preferences.KahfTube.token.value ?? "non-Token")")
                KahfTubeManager.shared.newUserRefreshNeeded = false
                closeVideoPreviews()
            }
        } else {
            print("Kahf Tube: Anonymous user")
        }
    }
    
    private func filter(webView: WKWebView) {
        util.jsFileToCode(path: "main") { code in
            if let jsCode = code {
                webView.evaluateSafeJavaScript(functionName: KahfJSGenerator.shared.getFilterJS(), contentWorld: .page, asFunction: false) { object, error in
                    if let error = error {
                        print("Kahf Tube: \(error)")
                    } else {
                        webView.evaluateSafeJavaScript(functionName: jsCode, contentWorld: .page, asFunction: false) {(object, error) -> Void in
                            if let error = error {
                                print("Kahf Tube: \(error)")
                            } else {
                                print("Kahf Tube: main.js executed")
                            }
                        }
                    }
                }
            }
        }
    }
    
    public func reload() {
        DispatchQueue.main.async {
            KahfTubeManager.webView?.reload()
            print("Kahf Tube: Reload ----------------------------------------------------------------")
        }
    }
    
    public func refreshYoutube() {
        DispatchQueue.main.async {
            KahfTubeManager.webView?.load(URLRequest(url: URL(string: "https://m.youtube.com/")!))
        }
    }
    
    // MARK: - Email&Login&Settings Funcs
    private func getEmail(erik: Erik) {
        util.jsFileToCode(path: "email") { code in
            if let jsCode = code {
                erik.evaluate(javaScript: jsCode) { (obj, err) -> Void in
                    if let error = err {
                        switch error {
                        case ErikError.javaScriptError(let message):
                            print(message)
                        default:
                            print("\(error)")
                        }
                    } else {
                        print("Kahf Tube: email.js worked successfully")
                    }
                }
            }
        }
    }
    
    func closeVideoPreviews() {
        Erik.sharedInstance.visit(url: URL(string: "https://m.youtube.com/select_site")!) { object, error in
            self.util.jsFileToCode(path: "closeVideoPreview") { code in
                if let jsCode = code {
                    Erik.sharedInstance.evaluate(javaScript: jsCode) { (obj, err) -> Void in
                        if let error = err {
                            switch error {
                            case ErikError.javaScriptError(let message):
                                print(message)
                            default:
                                print("\(error)")
                            }
                        } else {
                            print("Kahf Tube: closeVideoPreview.js worked successfully")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Unsubscribe Funcs
    func getHaramChannels() {
        haramChannels.removeAll(keepingCapacity: false)
        haramChannelsMap.removeAll(keepingCapacity: false)
        Erik.visit(url: URL(string: "https://m.youtube.com/feed/channels")!) { object, error in
            if let error = error {
                print("Kahf Tube: \(error)")
            } else {
                self.util.jsFileToCode(path: "channel") { code in
                    if let jsCode = code {
                        Erik.evaluate(javaScript: KahfJSGenerator.shared.getChannelStarterJS() + jsCode) { object, error in
                            if let error = error {
                                print("Kahf Tube: \(error)")
                            } else {
                                print("Kahf Tube: channel.js worked successfully")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func askUserToUnsubscribe(channels: [String: Any]) {
         haramChannels.removeAll(keepingCapacity: false)
         haramChannelsMap.removeAll(keepingCapacity: false)
         channels.forEach { pair in
            if let value = pair.value as? [String: Any],
               let isHaram = value["isHaram"] as? Bool, isHaram,
               let name = value["name"] as? String, let thumbnail = value["thumbnail"] as? String {
                haramChannels.append(Channel(name: name, thumbnail: thumbnail))
                haramChannelsMap[pair.key] = pair.value
            }
        }
        channelsFetched.toggle()
    }
    
    func unsubscribe() {
        Erik.visit(url: URL(string: "https://m.youtube.com/feed/channels")!) { object, error in
            if let error = error {
                print("Kahf Tube: \(error)")
            } else {
                self.util.jsFileToCode(path: "unsubscribe") { code in
                    if let jsCode = code {
                        Erik.evaluate(javaScript: KahfJSGenerator.shared.getUnsubscribeStarterJS(haramChannel: self.haramChannelsMap) + jsCode) { object, error in
                            if let error = error {
                                print("Kahf Tube: \(error)")
                            } else {
                                print("Kahf Tube: unsubscribe.js worked successfully")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func finishUnsubscribeSession() {
        haramChannels.removeAll(keepingCapacity: false)
        haramChannelsMap.removeAll(keepingCapacity: false)
        channelsFetched.toggle()
    }
}

struct Channel: Identifiable, Hashable, Encodable {
    var id = UUID()
    var name: String
    var thumbnail: String
    var isHaram: Bool?
    var isUnsubscribed: Bool?
}
