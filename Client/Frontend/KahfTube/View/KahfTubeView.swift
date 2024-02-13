// Copyright 2023 The Kahf Browser Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import Storage
import SnapKit
import Shared
import BraveShared
import Data
import BraveUI
import UIKit
import Growth
import BraveCore

public struct KahfTubeView: View {
    @ObservedObject private var token = Preferences.KahfTube.token
    @State var isOpened: Bool
    @State var url: URL?
    var updateView: (() -> Void)?
    var tab: Tab
    // in iOS 15, PresentationMode will be available in SwiftUI hosted by UIHostingController
    // but for now we'll have to manage this ourselves
    var reloadWebView: (() -> Void)?
    
    private enum VisibleScreen: Equatable {
        case onboarding
        case profile
        case closed
    }
    
    private var visibleScreen: VisibleScreen {
        if !isOpened {
            return .closed
        } else if Preferences.KahfTube.username.value == nil || Preferences.KahfTube.username.value == "" {
            return .onboarding
        } else {
            return .profile
        }
    }

    public var body: some View {
        VStack {
            switch visibleScreen {
            case .closed:
                VStack {
                    Spacer()
                    
                    Text("Open to use")
                        .padding(.bottom, 20)
                    
                    KahfTubeMenuButton(kafhTubeIsOn: $isOpened)
                    
                    Spacer()
                }
                .frame(height: 300)
            case .profile:
                KahfTubeProfileView(isOpened: $isOpened, reloadWebView: reloadWebView)
                .frame(minHeight: 600)
            case .onboarding:
                VStack {
                    Text("Explore this feature after signing to Youtube")
                }.frame(height: 300)
            }
        }
        .cornerRadius(20)
        .shadow(color: Color(red: 0.09, green: 0.12, blue: 0.27).opacity(0.08), radius: 20, x: 0, y: 8)
        .onChange(of: isOpened) { newValue in
            Preferences.KahfTube.isOn.value = newValue
            updateView?()
        }
    }
    
    @MainActor static func redirect(url: URL?, updateView: (() -> Void)?, reloadWebView: (() -> Void)?, tab: Tab) -> UIView {
        let popupView = KahfTubeView(isOpened: Preferences.KahfTube.isOn.value, url: url, updateView: updateView, tab: tab, reloadWebView: reloadWebView)
        return UIHostingController(rootView: popupView).view
    }
}
