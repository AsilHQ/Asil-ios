//
//  ContentView.swift
//  SwiftUI_DEsigner
//
//  Created by Cem Sertkaya on 18.01.2024.
//

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
    @State var value: Double = 10.0
    @State var url: URL?
    var updateView: (() -> Void)?
    
    var body: some View {
        
        VStack {
            if isOpened {
                SafegazeOpenView(value: $value, isOn: $isOpened, url: url)
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
            updateView?()
        }
    }
    
    private var reportView: some View {
        HStack {
            ResizableImageView(image: Image(braveSystemName: "sg.popup.bug"), width: 16, height: 16)
            
            Text("Please report any bugs or suggestions to this form")
                .font(Font.custom("Inter", size: 12))
                .multilineTextAlignment(.center)
                .foregroundColor(Color(red: 0.27, green: 0.27, blue: 0.27))
        }.padding(.horizontal, 33)
    }
    
    @MainActor static func redirect(url: URL?, updateView: (() -> Void)?) -> UIView {
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
        return UIHostingController(rootView: SafegazePopUpView(isOpened: isOpened, url: url, updateView: updateView)).view
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
        SafegazePopUpView(isOpened: true)
    }
}
#endif
