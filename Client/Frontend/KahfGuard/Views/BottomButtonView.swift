//
//  BottomButtonView.swift
//  Kahf Guard
//
//  Created by Mehdi with ♥ / hi@mehssi.com
//

import SwiftUI

struct BottomButtonView: View {
    let title: String
    let titleColor: Color
    let icon: ImageResource
    let iconAccent: ImageResource
    let borderColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(icon)
                .resizable()
                .frame(width: 24, height: 24)
            
            if title != "" {
                Text(title)
                    .fixedSize()
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundStyle(titleColor)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
        .padding(.leading, 10)
        .padding(.trailing, 10)
        .background(.white)
        .buttonStyle(.borderless)
        .cornerRadius(5)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(borderColor, lineWidth: 1)
        )
    }
    
}
