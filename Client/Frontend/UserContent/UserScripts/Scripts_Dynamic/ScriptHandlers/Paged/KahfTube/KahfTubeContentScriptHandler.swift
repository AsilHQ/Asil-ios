// Copyright 2023 The Asil Browser Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import WebKit
import BraveCore
import BraveShared
import Data

class KahftubeContentScriptHandler: TabContentScript {
  private struct RequestBlockingDTO: Decodable {
    struct RequestBlockingDTOData: Decodable, Hashable {
      let resourceType: AdblockEngine.ResourceType
      let resourceURL: String
      let sourceURL: String
    }
    
    let securityToken: String
    let data: RequestBlockingDTOData
  }
  
  static let scriptName = "KahfTubeMain"
  static let scriptId = UUID().uuidString
  static let messageHandlerName = "kahfTubeMessageHandler"
  static let scriptSandbox: WKContentWorld = .page
  static let userScript: WKUserScript? = {
    guard var script = loadUserScript(named: scriptName) else {
      return nil
    }
    guard var cssScript = loadUserStyle(named: "content", cssStyleName: "kahfTubeStyle") else {
      return nil
    }
    let newScript = cssScript + KahfJSGenerator.shared.getFilterJS() + script
    return WKUserScript.create(source: secureScript(handlerName: messageHandlerName,
                                                    securityToken: scriptId,
                                                    script: newScript),
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
      assertionFailure("Invalid security token. Fix the `KahfTubeMain.js` script")
      replyHandler(false, nil)
      return
    }
    
    if let dict = message.body as? [String: Any], let message = dict["state"] as? String {
      print("Kahf Tube: " + message)
    }
  }
}
