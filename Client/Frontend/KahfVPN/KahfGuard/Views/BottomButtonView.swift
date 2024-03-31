//
//  BottomButtonView.swift
//  Kahf Guard
//
//  Created by Mehdi with ♥ / hi@mehssi.com
//

import SwiftUI

struct BottomButtonView: View {
    let buttonHoverColor = Color(hex: 0x54b73e)
    
    @State var showText = false
    let title: String
    let icon: ImageResource
    let iconHover: ImageResource
    let borderColor: Color
    let mustShowText: Bool
    let action: () -> Void
    let hovered: ((_ inside: Bool) -> Void)?
    
    var body: some View {
        Button(action: action) {
            Image(!showText ? icon : iconHover)
                .resizable()
                .frame(width: 20, height: 20)
                .padding(.trailing, 5)
            
            Text(title)
                .fixedSize()
                .font(.custom("Poppins-Regular", size: 14))
                .opacity(!showText && !mustShowText ? 0 : 1)
                .foregroundColor(!showText ? borderColor : .white)
        }
        .padding(15)
        .frame(width: !showText && !mustShowText ? 50 : nil, height: 40, alignment: .leading)
        .background(!showText ? .white : buttonHoverColor)
        .buttonStyle(.borderless)
        .onHover { inside in
            showText = inside
            if let hovered = hovered {
                hovered(inside)
            }
        }
        .clipped()
        .cornerRadius(5)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(borderColor, lineWidth: 1)
        )
        .animation(.easeInOut, value: showText)
        .animation(.easeInOut, value: mustShowText)
    }
    
}

#Preview {
    BottomButtonView(title: "N/A", icon: .iconMailSvg, iconHover: .iconMailHoverSvg, borderColor: .gray, mustShowText: false, action: { }, hovered: nil)
        .frame(width: 200, height: 50)
}
