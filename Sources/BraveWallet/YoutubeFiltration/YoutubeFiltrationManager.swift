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
        if let email = dict["email"] as? String, let name = dict["name"] as? String, let imgSrc = dict["imgSrc"] as? String {
            if email != Preferences.YoutubeFiltration.email.value || Preferences.YoutubeFiltration.token.value == nil || Preferences.YoutubeFiltration.token.value == ""  {
                print("Youtube Filtration: Successfully signed-in")
                authSession(email: email, name: name) { dict, error in
                    if let dict = dict, let token = dict["token"]  {
                        Preferences.YoutubeFiltration.email.value = email
                        Preferences.YoutubeFiltration.username.value = name
                        Preferences.YoutubeFiltration.imageURL.value = imgSrc
                        Preferences.YoutubeFiltration.token.value = token
                    } else {
                        print("Youtube Filtration: Auth failed")
                    }
                }
            } else {
                print("Youtube Filtration: Already signed-in")
            }
        } else {
            print("Youtube Filtration: Anonymous user")
        }
    }
    
    func authSession(email: String, name: String, completion: @escaping ([String: String]?, Error?) -> Void) {
        register(email: email, name: name) { dict, error in
            if error != nil {
                self.login(email: email) { dict, error in
                    if let dict = dict {
                        completion(dict, nil)
                    } else {
                        completion(nil, nil)
                    }
                }
            } else if let dict = dict {
                completion(dict, nil)
            } else { // The email has already been taken.
                self.login(email: email) { dict, error in
                    if let dict = dict {
                        completion(dict, nil)
                    } else {
                        completion(nil, nil)
                    }
                }
            }
        }
    }
    
    func login(email: String, name: String? = nil, completion: @escaping ([String: String]?, Error?) -> Void) {
        let parameters = ["email": email]
        let url = URL(string: "https://api.kahf.ai/api/v1/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil, error)
                return
            }
            do {
                if let dataDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    var responseDict = [String: String]()
                    if let token = dataDict["token"] as? String {
                        responseDict["token"] = token
                        if let data = dataDict["data"] as? [String: Any] {
                            if let name = data["name"] as? String {
                                responseDict["name"] = name
                            }
                            if let email = data["email"] as? String {
                                responseDict["email"] = email
                            }
                        }
                        completion(responseDict, nil)
                    } else {
                        completion(nil, nil)
                    }
                } else {
                    completion(nil, nil)
                }
            } catch {
                completion(nil, error)
            }
        }
        task.resume()
    }
    
    func register(email: String, name: String? = nil, completion: @escaping ([String: String]?, Error?) -> Void) {
        let parameters = ["email": email, "name": name]
        let url = URL(string: "https://api.kahf.ai/api/v1/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil, error)
                return
            }
            do {
                if let dataDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    var responseDict = [String: String]()
                    if let token = dataDict["token"] as? String {
                        responseDict["token"] = token
                        if let data = dataDict["data"] as? [String: Any] {
                            if let name = data["name"] as? String {
                                responseDict["name"] = name
                            }
                            if let email = data["email"] as? String {
                                responseDict["email"] = email
                            }
                        }
                        completion(responseDict, nil)
                    } else {
                        completion(nil, nil)
                    }
                } else {
                    completion(nil, nil)
                }
            } catch {
                completion(nil, error)
            }
        }
        task.resume()
    }
}
