// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import WebKit
import BraveCore
import BraveShared
import Data

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
          } else {
              print("Safegaze: " + message)
          }
    }
  }
}

