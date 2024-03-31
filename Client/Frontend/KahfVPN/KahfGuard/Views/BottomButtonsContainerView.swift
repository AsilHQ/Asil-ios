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

    @State var buttonHoveredShare = false
    @State var buttonHoveredCommunity = false
    @State var buttonHoveredContact = false
    @State var buttonHoveredPatreon = false
            
    var body: some View {
        VStack {
            HStack(spacing: 0) {
                // share button
                BottomButtonView(title: "Share Kahf Guard", icon: .iconShareSvg, iconHover: .iconShareHoverSvg, borderColor: buttonBorderColor, mustShowText: false, action: {
                    openURL(URL(string: "https://www.facebook.com/sharer/sharer.php?u=https%3A%2F%2Fkahfguard.com%2F&amp;src=sdkpreparse")!)
                }, hovered: { inside in
                    buttonHoveredShare = inside
                })
                .padding(.trailing, 5)
                
                // join button
                BottomButtonView(title: "Join our Community", icon: .iconCommunitySvg, iconHover: .iconCommunityHoverSvg, borderColor: buttonBorderColor, mustShowText: false, action: {
                    openURL(URL(string: "https://kahf.community/")!)
                }, hovered: { inside in
                    buttonHoveredCommunity = inside
                })
                .padding(.trailing, 5)
                
                // contact button
                BottomButtonView(title: "Contact us", icon: .iconMailSvg, iconHover: .iconMailHoverSvg, borderColor: buttonBorderColor, mustShowText: false, action: {
                    openURL(URL(string: "https://kahfguard.com/support/")!)
                }, hovered: { inside in
                    buttonHoveredContact = inside
                })
                
                // support project button
                Spacer()
                BottomButtonView(title: "Support this Project", icon: .iconPatreonSvg, iconHover: .iconPatreonHoverSvg, borderColor: buttonBorderColor2, mustShowText: (!buttonHoveredShare && !buttonHoveredCommunity && !buttonHoveredContact && !buttonHoveredPatreon),
                action: {
                    openURL(URL(string: "https://www.patreon.com/KahfGuard")!)
                }, hovered: {
                    inside in
                    buttonHoveredPatreon = inside
                })
            }
            .padding(.bottom, 10)
            .padding(.leading, 12)
            .padding(.trailing, 12)
            .animation(.easeInOut, value: buttonHoveredShare)
            .animation(.easeInOut, value: buttonHoveredCommunity)
            .animation(.easeInOut, value: buttonHoveredContact)
            .animation(.easeInOut, value: buttonHoveredPatreon)
        }
        .transition(.move(edge: .bottom))
    }
}

#Preview {
    BottomButtonsContainerView()
        .frame(width: 500, height: 50)
}
