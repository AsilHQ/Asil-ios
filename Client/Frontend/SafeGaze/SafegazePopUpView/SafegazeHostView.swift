// Copyright 2024 The Asil Browser Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI

struct SafegazeHostView: View {
    @State var url: URL?
    var body: some View {
        HStack {
            ResizableImageView(image: Image(braveSystemName: "sg.popup.globe"), width: 12, height: 12)
            
            Text(url?.absoluteString ?? "")
                .font(FontHelper.quicksand(size: 14, weight: .medium))
                .foregroundColor(.black)
            
            Spacer()
        }
    }
}
