// Copyright 2023 The Asil Browser Authors. All rights reserved.
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
                    mode = \(Preferences.KahfTube.mode.value ?? 1);
                    gender = \(Preferences.KahfTube.gender.value ?? 0);
                    token = "\(Preferences.KahfTube.token.value ?? "296|y4AAmzzmIPN4rXydWoFBs60XWMIg58rA8aVhjp30")";
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
    
    func getChannelJS() -> String {
        return """
                new MutationObserver(async (mutationList, observer) => {
                          if (!mode || !gender) {
                            mode = \(Preferences.KahfTube.mode.value ?? 1);
                            gender = \(Preferences.KahfTube.gender.value ?? 0);
                            token = "\(Preferences.KahfTube.token.value ?? "296|y4AAmzzmIPN4rXydWoFBs60XWMIg58rA8aVhjp30")";
                          }
                          window.webkit.messageHandlers.logHandler.postMessage("getChannels");
                          const channelList = document.querySelectorAll("div.compact-media-item");
                          if (channelList.length) {
                            length = channelList.length;
                            for (let index = 0; index < channelList.length; index++) {
                              const element = channelList[index];
                              const metadata = element.querySelector(
                                "a.compact-media-item-metadata-content"
                              );
                              const href = metadata.getAttribute("href");
                              if (!channels[href]) {
                                channels[href] = {
                                  isUnsubscribed: false,
                                  thumbnail: `https:${element.querySelector("img")?.lazyData}`,
                                  name: metadata?.children?.item(0)?.textContent,
                                  subscribers: metadata?.children?.item(1)?.children?.item(0)
                                    ?.textContent,
                                  videos: metadata?.children?.item(1)?.children?.item(1)?.textContent,
                                  isHaram: false,
                                };
                              }
                            }
                            // console.log(JSON.stringify(channels));
                          }

                          const channelListOpt = document.querySelectorAll("a.channel-list-item-link");
                          if (channelListOpt.length) {
                            length = channelListOpt.length;
                            for (let index = 0; index < channelListOpt.length; index++) {
                              const element = channelListOpt[index];
                              const href = element.getAttribute("href");
                              if (!channels[href]) {
                                channels[href] = {
                                  isUnsubscribed: false,
                                  thumbnail: `https:${element.querySelector("img")?.lazyData}`,
                                  name: element?.children?.item(1)?.textContent,
                                  isHaram: false,
                                };
                              }
                            }
                            // console.log(JSON.stringify(channels));
                          }
                        }).observe(document, {
                          childList: true,
                          subtree: true,
                        });
                """
    }
}
