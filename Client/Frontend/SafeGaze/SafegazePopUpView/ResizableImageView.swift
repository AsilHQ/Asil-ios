// Copyright 2024 The Kahf Browser Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI

struct ResizableImageView: View {
    var imageName: String?
    var image: Image?
    var width: CGFloat
    var height: CGFloat
    
    var body: some View {
        if let imageName = imageName {
            Image(systemName: imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: width, height: height)
        } else if let image = image {
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: width, height: height)
        } else {
            Text("")
        }
       
    }
}
