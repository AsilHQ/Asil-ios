//
//  BottomButtonsView.swift
//  Kahf Guard
//
//  Created by Mehdi with ♥ / hi@mehssi.com
//

import SwiftUI

struct BottomButtonsContainerView: View {
    @Environment(\.openURL) var openURL
    
    let buttonBorderColor = Color(hex: 0xEEEEEE)
    let buttonBorderColor2 = Color(hex: 0x40c533)
            
    var body: some View {
        VStack {
            HStack(spacing: 0){
                HStack {
                    //share button
                    BottomButtonView(title: "", titleColor: .gray, icon: .iconShareSvg, iconAccent: .iconCommunityHoverSvg, borderColor: buttonBorderColor, action: {
                        let AV = UIActivityViewController(activityItems: ["https://apps.apple.com/tr/app/kahf-guard-block-haram-content/id6479974796"], applicationActivities: nil)
                        let activeScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
                        let rootViewController = (activeScene?.windows ?? []).first(where: { $0.isKeyWindow })?.rootViewController
                        // for iPad. if condition is optional.
                        if UIDevice.current.userInterfaceIdiom == .pad {
                            AV.popoverPresentationController?.sourceView = rootViewController?.view
                            AV.popoverPresentationController?.sourceRect = .zero
                        }
                        rootViewController?.present(AV, animated: true, completion: nil)
                    })
                    .padding(.trailing, 2)
                    
                    //join button
                    BottomButtonView(title: "", titleColor: .gray, icon: .iconCommunitySvg, iconAccent: .iconCommunityHoverSvg, borderColor: buttonBorderColor, action: {
                        openURL(URL(string: "https://kahf.community/")!)
                    })
                    .padding(.trailing, 2)
                    
                    //contact button
                    BottomButtonView(title: "", titleColor: .gray, icon: .iconMailSvg, iconAccent: .iconMailHoverSvg, borderColor: buttonBorderColor, action: {
                        openURL(URL(string: "https://kahfguard.com/support/")!)
                    })
                }
                
                //support project button
                Spacer()
                BottomButtonView(title: "Support Project", titleColor: buttonBorderColor2, icon: .iconPatreonSvg, iconAccent: .iconPatreonHoverSvg, borderColor: buttonBorderColor2, action: {
                    openURL(URL(string: "https://www.patreon.com/KahfGuard")!)
                })
            }
            .padding(.bottom, 10)
            .padding(.leading, 12)
            .padding(.trailing, 12)
        }
        .transition(.move(edge: .bottom))
        //.frame(minWidth: nil, maxWidth: .infinity, minHeight: nil, maxHeight: 50, alignment: .center)
        //.background(.red)
    }
}

#Preview {
    BottomButtonsContainerView()
        .frame(width: 500, height: 50)
}
