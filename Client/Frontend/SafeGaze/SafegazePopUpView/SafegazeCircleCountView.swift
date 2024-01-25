//
//  SafegazeCircleCountView.swift
//  SwiftUI_DEsigner
//
//  Created by Cem Sertkaya on 20.01.2024.
//

import SwiftUI

struct SafegazeCircleCountView: View {
    var count: Int
    
    var body: some View {
        ZStack {
            Image("Ellipse 18")
                .frame(width: 36, height: 36)
                .background(Color(red: 0.97, green: 0.91, blue: 0.87))
            
            Text("34")
                .font(Font.custom("Quicksand", size: 14).weight(.bold))
                .multilineTextAlignment(.center)
                .foregroundColor(Color(red: 1, green: 0, blue: 0))
        }
        .cornerRadius(18)
    }
}
