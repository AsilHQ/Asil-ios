// Copyright 2023 The Asil Browser Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import WebKit
import BraveShared

public class KahfTubeManager {
    public static var shared = KahfTubeManager()
    private let webRepository = KahfTubeWebRepository()
    private static var webView: WKWebView?
    
    private func getEmail(erik: Erik) {
        guard let filePath = Bundle.main.path(forResource: "email", ofType: "js") else {
            print("Kahf Tube: Failed to find email.js file")
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
                    print("Kahf Tube: email.js worked successfully")
                }
            }
        } catch {
            print("Kahf Tube: Failed to read email.js file")
        }
    }
    
    public func startKahfTube(view: UIView, webView: WKWebView, vc: UIViewController) {
        KahfTubeManager.webView = webView
        if let url = webView.url?.absoluteString, url.contains("youtube.com") {
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
        } else {
            print("Kahf Tube: User is not on a YouTube page")
        }
    }
    
    func getUserInformationsFromYoutube(view: UIView, webView: WKWebView) {
        let hiddenView = WKWebView(frame: view.bounds)
        hiddenView.isHidden = true
        view.addSubview(hiddenView)
        let erik = Erik(webView: hiddenView)
        erik.visit(url: URL(string: "https://m.youtube.com")!) { object, error in
            self.getEmail(erik: erik)
            self.filter(webView: webView)
        }
    }
    
    func saveYoutubeInformations(dict: [String: Any]) {
        if let email = dict["email"] as? String, let name = dict["name"] as? String, let imgSrc = dict["imgSrc"] as? String {
            if email != Preferences.KahfTube.email.value || Preferences.KahfTube.token.value == nil || Preferences.KahfTube.token.value == "" {
                print("Kahf Tube: Successfully signed-in")
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
            }
        } else {
            print("Kahf Tube: Anonymous user")
        }
    }
    
    func filter(webView: WKWebView) {
        guard let filePath = Bundle.main.path(forResource: "main", ofType: "js") else {
            print("Kahf Tube: Failed to find main.js file")
            return
        }
        
        do {
            if let token = Preferences.KahfTube.token.value {
                let jsCode = try String(contentsOfFile: filePath)
                let jsCode1 = """
                        new MutationObserver(async (mutationList, observer) => {
                          if (!mode || !gender) {
                            mode = "\(Preferences.KahfTube.mode.value ?? 0)";
                            gender = "\(Preferences.KahfTube.gender.value ?? 0)";
                            token = "\(token)";
                          }


                          console.log(location.href);
                          if (location.href == "https://m.youtube.com/?noapp=1") {
                            email = null;
                            isSigninClicked = false;
                            isButtonClicked = false;
                            window.flutter_inappwebview.callHandler("shouldRestart", "svg");
                          }

                          const reelSections = document.getElementsByTagName("ytm-reel-shelf-renderer");
                          for (let index = 0; index < reelSections.length; index++) {
                            const element = reelSections[index];
                            element?.remove();
                          }

                          updateFeaturedVideo();
                          updateCardVideo();
                          updateCompactVideoList();
                          updateMediaItemList();
                        }).observe(document.getElementById("app"), {
                          attributes: true,
                          subtree: true,
                          characterData: false,
                          childList: true,
                        });
               """
                webView.evaluateSafeJavaScript(functionName: jsCode1, contentWorld: .page, asFunction: false) { object, error in
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
        } catch {
            print("Kahf Tube: Failed to read main.js file")
        }
    }
    
    public func reload() {
        DispatchQueue.main.async {
            KahfTubeManager.webView?.reload()
            print("Kahf Tube: Reload ----------------------------------------------------------------")
        }
    }
}
