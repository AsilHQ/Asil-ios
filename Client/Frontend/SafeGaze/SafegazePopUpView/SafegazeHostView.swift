//
//  SafegazeHostView.swift
//  SwiftUI_DEsigner
//
//  Created by Cem Sertkaya on 19.01.2024.
//

import SwiftUI

struct SafegazeHostView: View {
    @State var url: URL?
    var body: some View {
        HStack {
            ResizableImageView(image: Image(braveSystemName: "sg.popup.globe"), width: 12, height: 12)
            
            Text(url?.absoluteString ?? "")
                .font(Font.custom("Quicksand", size: 14).weight(.medium))
                .foregroundColor(.black)
            
            Spacer()
        }
    }
}
