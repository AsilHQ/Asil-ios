// Copyright 2024 The Asil Browser Authors. All rights reserved.
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

struct SafegazePopUpView: View {
    @State var isOpened: Bool
    @State var value: Float = Preferences.Safegaze.blurIntensity.value
    @State var url: URL?
    @State var lifetimeAvoidedContentCount: Int = BraveGlobalShieldStats.shared.safegazeCount
    var updateView: (() -> Void)?
    var updateBlurIntensity: (() -> Void)?
    var shieldsSettingsChanged: (() -> Void)?
    var tab: Tab 
    
    var body: some View {
        
        VStack {
            if isOpened {
                SafegazeOpenView(value: $value, isOn: $isOpened, url: url, domainAvoidedContentCount: tab.contentBlocker.stats.safegazeCount, lifetimeAvoidedContentCount: lifetimeAvoidedContentCount)
            } else {
                SafegazeCloseView(isOpened: $isOpened, url: url)
            }
        
            reportView.padding(.top, 20).padding(.bottom, 31)
        }.background(
            LinearGradient(
                stops: [
                    Gradient.Stop(color: Color(red: 0.98, green: 0.99, blue: 0.99), location: 0.00),
                    Gradient.Stop(color: Color(red: 1, green: 0.98, blue: 0.99), location: 1.00),
                ],
                startPoint: UnitPoint(x: 0.5, y: 0),
                endPoint: UnitPoint(x: 0.5, y: 1)
            )
        )
        .cornerRadius(20)
        .shadow(color: Color(red: 0.09, green: 0.12, blue: 0.27).opacity(0.08), radius: 20, x: 0, y: 8)
        .onChange(of: isOpened) { newValue in
            updateSafegaze(isOpened: newValue)
            shieldsSettingsChanged?()
            updateView?()
        }
        .onChange(of: value) { newValue in
            value = newValue
        }
        .onDisappear() {
            Preferences.Safegaze.blurIntensity.value = value
            if isOpened {
                updateBlurIntensity?()
            }
        }
    }
    
    private var reportView: some View {
        Button {
            guard let url = URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSeaW7PjI-K3yqZZ4gpuXbbx5qOFxAwILLy5uy7PTerXfdzFqw/viewform") else { return }
            UIApplication.shared.open(url)
        } label: {
            HStack {
                ResizableImageView(image: Image(braveSystemName: "sg.popup.bug"), width: 16, height: 16)
                
                Text("Please report any bugs or suggestions to ")
                    .font(Font.custom("Inter", size: 12))
                    .foregroundColor(Color(red: 0.27, green: 0.27, blue: 0.27))
                +
                Text("this form")
                    .font(Font.custom("Inter", size: 12))
                    .foregroundColor(Color(uiColor: UIColor(red: 0.06, green: 0.7, blue: 0.79, alpha: 1)))
            }.padding(.horizontal, 33)
        }
    }
    
    @MainActor static func redirect(url: URL?, updateView: (() -> Void)?, updateBlurIntensity: (() -> Void)?, shieldsSettingsChanged: (() -> Void)?, tab: Tab) -> UIView {
        var domain: Domain?
        var isOpened: Bool = false
        if let url = url {
            let isPrivateBrowsing = PrivateBrowsingManager.shared.isPrivateBrowsing
            domain = Domain.getOrCreate(forUrl: url, persistent: !isPrivateBrowsing)
            if let domain = domain {
                isOpened = !domain.isSafegazeAllOff(url: url, ignoredDomains: SafegazeManager.ignoredDomains)
            } else {
                isOpened = true
            }
        } else {
            isOpened = false
        }
        let popupView = SafegazePopUpView(isOpened: isOpened, url: url, updateView: updateView, updateBlurIntensity: updateBlurIntensity, shieldsSettingsChanged: shieldsSettingsChanged, tab: tab)
        return UIHostingController(rootView: popupView).view
        
    }
    
    func updateSafegaze(isOpened: Bool) {
        guard let url = url else { return }
        Domain.setSafegaze(
            forUrl: url,
            isOn: isOpened,
            isPrivateBrowsing: PrivateBrowsingManager.shared.isPrivateBrowsing
        )
    }
}

#if DEBUG
struct SafegazePopUpView_Previews: PreviewProvider {
    static var previews: some View {
        SafegazePopUpView(isOpened: true, tab: Tab(configuration: WKWebViewConfiguration()))
    }
}
#endif
