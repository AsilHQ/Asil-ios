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
    
    private func getEmail(erik: Erik) {
        guard let filePath = Bundle.main.path(forResource: "email", ofType: "js") else {
            print("Failed to find script.js file")
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
                    print("successfull")
                }
            }
        } catch {
            print("Failed to read script.js file")
        }
    }

    public func getUserInformationsFromYoutube(view: UIView, webView: WKWebView) {
        
        if let url = webView.url?.absoluteString, url.contains("youtube.com") {
            // User is on a YouTube page
            print("User is on a YouTube page")
            let hiddenView = WKWebView(frame: view.bounds)
            hiddenView.isHidden = true
            view.addSubview(hiddenView)
            let erik = Erik(webView: hiddenView)
            erik.visit(url: URL(string: "https://m.youtube.com")!) { object, error in
                self.getEmail(erik: erik)
            }
        } else {
            // User is not on a YouTube page
            print("User is not on a YouTube page")
        }
    }
    
    func saveYoutubeInformations(dict: [String: Any]) {
        if let name = dict["name"] as? String {
            Preferences.YoutubeFiltration.username.value = name
        }
        if let imgSrc = dict["imgSrc"] as? String {
            Preferences.YoutubeFiltration.imageURL.value = imgSrc
        }
        if let email = dict["email"] as? String {
            Preferences.YoutubeFiltration.email.value = email
        }
    }
    
}
