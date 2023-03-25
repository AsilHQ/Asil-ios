//
//  YoutubeFiltrationManager.swift
//  ScrapperExample
//
//  Created by Cem Sertkaya on 21.03.2023.
//

import Foundation
import UIKit
import WebKit
import BraveShared

public class YoutubeFiltrationManager {
    public static var shared = YoutubeFiltrationManager()
    private let webRepository = YoutubeFiltrationWebRepository()
    
    private func getEmail(erik: Erik) {
        guard let filePath = Bundle.main.path(forResource: "email", ofType: "js") else {
            print("Youtube Filtration: Failed to find email.js file")
            return
        }
        
        do {
            let jsCode = try String(contentsOfFile: filePath)
            erik.evaluate(javaScript: jsCode) { (obj, err) -> Void in
                if let error = err {
                    switch error {
                    case ErikError.javaScriptError(let message):
                        print(message)
                    default:
                        print("\(error)")
                    }
                } else {
                    print("Youtube Filtration: Script worked successfully")
                }
            }
        } catch {
            print("Failed to read email.js file")
        }
    }
    
    public func getUserInformationsFromYoutube(view: UIView, webView: WKWebView) {
        if let url = webView.url?.absoluteString, url.contains("youtube.com") {
            print("Youtube Filtration: User is on a YouTube page")
            let hiddenView = WKWebView(frame: view.bounds)
            hiddenView.isHidden = true
            view.addSubview(hiddenView)
            let erik = Erik(webView: hiddenView)
            erik.visit(url: URL(string: "https://m.youtube.com")!) { object, error in
                self.getEmail(erik: erik)
                self.filter(webView: webView)
            }
        } else {
            print("Youtube Filtration: User is not on a YouTube page")
        }
    }
    
    func saveYoutubeInformations(dict: [String: Any]) {
        if let email = dict["email"] as? String, let name = dict["name"] as? String, let imgSrc = dict["imgSrc"] as? String {
            if email != Preferences.YoutubeFiltration.email.value || Preferences.YoutubeFiltration.token.value == nil || Preferences.YoutubeFiltration.token.value == "" {
                print("Youtube Filtration: Successfully signed-in")
                webRepository.authSession(email: email, name: name) { dict, error in
                    if let dict = dict, let token = dict["token"] {
                        Preferences.YoutubeFiltration.email.value = email
                        Preferences.YoutubeFiltration.username.value = name
                        Preferences.YoutubeFiltration.imageURL.value = imgSrc
                        Preferences.YoutubeFiltration.token.value = token
                    } else {
                        print("Youtube Filtration: Auth failed")
                    }
                }
            } else {
                print("Youtube Filtration: Already signed-in \(Preferences.YoutubeFiltration.token.value ?? "non-Token")")
            }
        } else {
            print("Youtube Filtration: Anonymous user")
        }
    }
    
    func filter(webView: WKWebView) {
        guard let filePath = Bundle.main.path(forResource: "main", ofType: "js") else {
            print("Youtube Filtration: Failed to find main.js file")
            return
        }
        
        do {
            let jsCode = try String(contentsOfFile: filePath)
            // swiftlint:disable:next safe_javascript
            webView.evaluateJavaScript(jsCode) {[unowned self] (object, error) -> Void in
                if let error = error {
                    print(error)
                } else {
                    print("Youtube Filtration: main.js executed")
                }
            }
        } catch {
            print("Failed to read main.js file")
        }
    }
}
