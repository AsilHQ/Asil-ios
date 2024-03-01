// Copyright 2023 The Kahf Browser Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveShared

class KahfJSGenerator {
    
    static let shared = KahfJSGenerator()
    
    func getFilterJS() -> String {
        return """
                new MutationObserver(async (mutationList, observer) => {
                  if (!mode || !gender) {
                    mode = \(Preferences.KahfTube.mode.value);
                    gender = \(Preferences.KahfTube.gender.value);
                    token = "\(Preferences.KahfTube.token.value)";
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
    }

    func getChannelStarterJS() -> String {
        return """
         let mode = \(Preferences.KahfTube.mode.value);
         let gender = \(Preferences.KahfTube.gender.value);
         let token = "\(Preferences.KahfTube.token.value)";
        """
    }
    
    func getUnsubscribeStarterJS(haramChannel: [[String: Any]]) -> String {
        let newHaramChannel = haramChannel.map { data in
            return data["id"] ?? ""
        }
        do {
            let jsonArrayString = newHaramChannel.map { "\"\($0)\"" }.joined(separator: ",")
            let jsCommand = "var channel_ids = JSON.parse(decodeURIComponent('[\(jsonArrayString)]'));"
            return jsCommand
        } catch {
            print(error)
            return ""
        }
    }
}
