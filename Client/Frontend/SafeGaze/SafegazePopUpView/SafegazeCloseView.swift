// Copyright 2024 The Kahf Browser Authors. All rights reserved.
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

struct SafegazeCloseView: View {
    @Binding var isOpened: Bool
    @State var url: URL?
    var body: some View {
        VStack {
            headerView.padding(.top, 20)
            
            contentStack.padding(.top, 21)
            
            toggleView.padding(.top, 11)
            
            descriptionView.padding(.top, 30)
        }
    }
    
    private var headerView: some View {
        HStack {
            
            ResizableImageView(image: Image(braveSystemName: "sg.logo.off"), width: 44, height: 40).padding(.leading, 18)
            
            Spacer()
        }
    }
    
    private var contentStack: some View {
        HStack {
            VStack {
                SafegazeHostView(url: url)
            }
            .padding(.leading, 18)
            
            /*Text("Sinful acts showing")
                .font(Font.custom("Outfit", size: 12).weight(.medium))
                .foregroundColor(Color(red: 0.36, green: 0.36, blue: 0.36))
                .frame(width: 69)
                .padding(.trailing, 14)
            
            SafegazeCircleCountView(count: 34).padding(.trailing, 15)*/
            
        }.frame(height: 66)
            .background(Color.white)
            .cornerRadius(10)
            .padding(.horizontal, 18)
            .shadow(color: Color(red: 0.49, green: 0.52, blue: 0.56).opacity(0.12), radius: 2.5, x: 0, y: 1)
    }
    
    private var descriptionView: some View {
        ZStack {
            Text(Strings.safegazeTakeControlTitle)
                .font(FontHelper.quicksand(size: 12, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundColor(Color(red: 0.27, green: 0.27, blue: 0.27))
            
                .frame(width: 302, alignment: .top)
        }
        .padding(.horizontal, 17)
        .frame(height: 73)
        .background(Color(red: 0.93, green: 0.93, blue: 0.94))
        .cornerRadius(10)
        .shadow(color: Color(red: 0.82, green: 0.82, blue: 0.82).opacity(0.09), radius: 2.34375, x: 0, y: 3.125)
    }
    
    private var toggleView: some View {
        Button {
            isOpened.toggle()
        } label: {
            ResizableImageView(image: Image(braveSystemName: "safegaze.turn.on"), width: 122, height: 136)
        }
    }
}

#if DEBUG
struct SafegazeCloseView_Previews: PreviewProvider {
    static var previews: some View {
        SafegazeCloseView(isOpened: .constant(false))
    }
}
#endif
