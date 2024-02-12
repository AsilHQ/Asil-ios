// Copyright 2023 The Kahf Browser Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import Foundation
import UIKit
import BraveCore
import Introspect
import BraveUI
import BraveShared

public struct KahfTubeView: View {
    @ObservedObject private var token = Preferences.KahfTube.token
    // in iOS 15, PresentationMode will be available in SwiftUI hosted by UIHostingController
    // but for now we'll have to manage this ourselves
    var dismissAction: (() -> Void)?
    
    private enum VisibleScreen: Equatable {
        case onboarding
        case profile
    }
    
    private var visibleScreen: VisibleScreen {
        if Preferences.KahfTube.username.value == nil || Preferences.KahfTube.username.value == "" {
            return .onboarding
        } else {
            return .profile
        }
    }
    
    @ToolbarContentBuilder
    private var dismissButtonToolbarContents: some ToolbarContent {
      ToolbarItemGroup(placement: .cancellationAction) {
        Button(action: {
            dismissAction?()
        }) {
          Image("wallet-dismiss", bundle: .module)
            .renderingMode(.template)
            .foregroundColor(Color.black)
        }
      }
    }

    public var body: some View {
        ZStack {
            switch visibleScreen {
            case .profile:
                UIKitNavigationView {
                    KahfTubeProfileView(dismissAction: dismissAction)
                }
                .transition(.move(edge: .bottom))
            case .onboarding:
                Text("Explore this feature after signing to Youtube")
            }
        }
    }
}

#if DEBUG
struct YoutubeFiltrationView_Previews: PreviewProvider {
    static var previews: some View {
        KahfTubeView()
    }
}
#endif
