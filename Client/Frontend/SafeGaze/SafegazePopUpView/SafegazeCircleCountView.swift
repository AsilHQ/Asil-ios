// Copyright 2024 The Asil Browser Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI

struct SafegazeCircleCountView: View {
    @State var count: Int
    
    var body: some View {
        ZStack {
            Image("Ellipse 18")
                .frame(width: 36, height: 36)
                .background(Color(red: 0.97, green: 0.91, blue: 0.87))
            
            Text(String(count))
                .font(FontHelper.quicksand(size: 14, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(Color(red: 1, green: 0, blue: 0))
        }
        .cornerRadius(18)
    }
}
