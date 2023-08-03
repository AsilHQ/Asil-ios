// Copyright 2023 The Asil Browser Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import WebKit
import BraveShared

public class SafegazeManager: ObservableObject {
    public static let shared = SafegazeManager()
    private let webRepository = KahfTubeWebRepository.shared
    private let util = KahfTubeUtil.shared
    private static var webView: WKWebView?
    
    public func startSafegaze(webView: WKWebView) {
        webView.configuration.userContentController.addUserScript(SafegazeContentScriptHandler.userScript ?? WKUserScript())
    }
}
