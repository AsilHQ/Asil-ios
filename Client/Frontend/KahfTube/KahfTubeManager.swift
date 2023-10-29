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
    private static var webView: WKWebView?
    @Published var haramChannels: [Channel] = [Channel]()
    @Published var haramChannelsMap: [[String: Any]] = [[String: Any]]()
    @Published var channelsFetched: Bool = false
    @Published var newUserRefreshNeeded = false
    @Published var myQueue = Queue<ReplaceVideo>()
    @Published var videosList = [ReplaceVideo]()
    
    public func startKahfTube(view: UIView, webView: WKWebView, vc: UIViewController) {
        KahfTubeManager.webView = webView
        print("Kahf Tube: User is on a YouTube page")
        if Preferences.KahfTube.isOn.value {
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
            if email != Preferences.KahfTube.email.value || Preferences.KahfTube.imageURL.value != imgSrc {
                KahfTubeManager.shared.newUserRefreshNeeded = true
                self.closeVideoPreviews()
                webRepository.authSession(email: email, name: name) { dict, error in
                    if let dict = dict, let token = dict["token"] {
                        self.login(email: email, token: token, imgSrc: imgSrc, name: name)
                    } else {
                        self.logout()
                    }
                }
            } else {
                print("Kahf Tube: Already signed-in \(Preferences.KahfTube.token.value )")
                KahfTubeManager.shared.newUserRefreshNeeded = false
                closeVideoPreviews()
            }
        } else {
            logout()
            print("Kahf Tube: Anonymous user")
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
        if let script = self.loadUserScript(named: "KahfTubeEmail") {
            erik.evaluate(javaScript: script) { (obj, err) -> Void in
                if let error = err {
                    switch error {
                    case ErikError.javaScriptError(let message):
                        print(message)
                    default:
                        print("\(error)")
                    }
                } else {
                    print("Kahf Tube: KahfTubeEmail.js worked successfully")
                }
            }
        }
    }
    
    func closeVideoPreviews() {
        Erik.sharedInstance.visit(url: URL(string: "https://m.youtube.com/select_site")!) { object, error in
            if let script = self.loadUserScript(named: "KahfTubeCloseVideoPreview") {
                Erik.sharedInstance.evaluate(javaScript: script) { (obj, err) -> Void in
                    if let error = err {
                        switch error {
                        case ErikError.javaScriptError(let message):
                            print(message)
                        default:
                            print("\(error)")
                        }
                    } else {
                        print("Kahf Tube: KahfTubeCloseVideoPreview.js worked successfully")
                    }
                }
            }
        }
    }
    
    // MARK: - Unsubscribe Funcs
    func getHaramChannels() {
        haramChannelsMap.removeAll(keepingCapacity: false)
        Erik.visit(url: URL(string: "https://m.youtube.com/feed/channels")!) { object, error in
            if let error = error {
                print("Kahf Tube: \(error)")
            } else {
                if let script = self.loadUserScript(named: "KahfTubeChannelScript") {
                    Erik.evaluate(javaScript: KahfJSGenerator.shared.getChannelStarterJS() + script) { object, error in
                        if let error = error {
                            print("Kahf Tube: \(error)")
                        } else {
                            print("Kahf Tube: KahfTubeChannelScript.js worked successfully")
                        }
                    }
                }
            }
        }
    }
    
    func askUserToUnsubscribe(channels: [[String: Any]]? = nil) {
        haramChannels.removeAll(keepingCapacity: false)
        haramChannelsMap.removeAll(keepingCapacity: false)
        if let channels = channels {
            channels.forEach { dict in
                  if let isHaram = dict["isHaram"] as? Bool, isHaram,
                  let name = dict["name"] as? String,
                  let thumbnail = dict["thumbnail"] as? String,
                  let isUnsubscribed = dict["isUnsubscribed"] as? Bool,
                  let id = dict["id"] as? String {
                      haramChannels.append(Channel(id: id, name: name, thumbnail: thumbnail, isHaram: isHaram, isUnsubscribed: isUnsubscribed))
                  }
           }
           haramChannelsMap = channels
        }
       channelsFetched.toggle()
   }
    
    func unsubscribe() {
        var urlRequest = URLRequest(url: URL(string: "https://www.youtube.com/")!)
        urlRequest.addValue( UserAgent.desktop, forHTTPHeaderField: "User-Agent")
        Erik.sharedInstance.layoutEngine.changeAgent(agentType: UserAgent.desktop)
        Erik.load(urlRequest: urlRequest) {  object, error in
            if let error = error {
                print("Kahf Tube: \(error)")
            } else {
                if let script = self.loadUserScript(named: "KahfTubeUnsubscribe") {
                    Erik.evaluate(javaScript: KahfJSGenerator.shared.getUnsubscribeStarterJS(haramChannel: self.haramChannelsMap) + script) { object, error in
                        if let error = error {
                            print("Kahf Tube: \(error)")
                        } else {
                            print("Kahf Tube: KahfTubeUnsubscribe.js worked successfully")
                            Erik.sharedInstance.layoutEngine.changeAgent(agentType: UserAgent.mobile)
                        }
                    }
                }
            }
        }
    }
    
    func loadYtScript(id: String) {
        Erik.visit(url: URL(string: "https://m.youtube.com//watch?v=\(id)")!) { object, error in
            if let script = self.loadUserScript(named: "KahfTubeYtData") {
                Erik.evaluate(javaScript: script) { object, error in
                    if let error = error {
                        print("Kahf Tube: \(error)")
                    } else {
                        Erik.sharedInstance.layoutEngine.changeAgent(agentType: UserAgent.mobile)
                    }
                }
            }
        }
    }
    
    func ytCompletion(lengthSeconds: String, url: String, viewCount: String) {
        if var video = myQueue.dequeue() {
            video.thumbnail = url
            video.timeline = lengthSeconds
            video.views = "\(viewCount) views"
            do {
                let encoder = JSONEncoder()
                let jsonData = try encoder.encode(video)
                
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    let jsString = """
                        window.apiResponses["\(video.href)"].metaData = \(jsonString);
                        globalCallbackFunction("\(video.href)");
                    """
                    
                    KahfTubeManager.webView?.evaluateSafeJavaScript(functionName: jsString, contentWorld: .page, asFunction: false) { object, error in
                        if let error = error {
                            print("Kahf Tube:** Filter \(error)")
                        }
                    }
                }
            } catch {
                print("Error encoding to JSON: \(error)")
            }

            videosList.append(video)
        }
    }
    
    func loadUserScript(named: String) -> String? {
      guard let path = Bundle.module.path(forResource: named, ofType: "js"),
            let source: String = try? String(contentsOfFile: path) else {
          print("Failed to Load Script: \(named).js")
        assertionFailure("Failed to Load Script: \(named).js")
        return nil
      }
      return source
    }
    
    func finishUnsubscribeSession() {
        haramChannelsMap.removeAll(keepingCapacity: false)
        channelsFetched.toggle()
    }
    
    func logout() {
        Preferences.KahfTube.email.value = nil
        Preferences.KahfTube.username.value = nil
        Preferences.KahfTube.imageURL.value = nil
        Preferences.KahfTube.token.value = "296|y4AAmzzmIPN4rXydWoFBs60XWMIg58rA8aVhjp30"
    }
    
    func login(email: String, token: String, imgSrc: String, name: String) {
        Preferences.KahfTube.email.value = email
        Preferences.KahfTube.username.value = name
        Preferences.KahfTube.imageURL.value = imgSrc
        Preferences.KahfTube.token.value = token
    }
}

struct Queue<Element> {
    private var elements: [ReplaceVideo] = []
    
    var isEmpty: Bool {
        return elements.isEmpty
    }
    
    mutating func enqueue(_ element: ReplaceVideo) {
        elements.append(element)
        if elements.count == 1 {
            KahfTubeManager.shared.loadYtScript(id: element.id)
        }
    }
    
    mutating func dequeue() -> ReplaceVideo? {
        guard !isEmpty else {
            return nil
        }
        
        let removedElement = elements.removeFirst()
        
        if let element = elements.first {
            KahfTubeManager.shared.loadYtScript(id: element.id)
            return removedElement
        } else {
            return nil
        }
    }
    
    func peek() -> ReplaceVideo? {
        return elements.first
    }
}
