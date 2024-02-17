// Copyright 2023 The Kahf Browser Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI

struct KahfTubeSuccessfulView: View {
    var body: some View {
        ZStack {
            Color.white
            VStack {
                Image("kahf-tubemoon-clear-fill", bundle: Bundle.module).foregroundColor(Color(UIColor(colorString: "#A242FF")))
                    .frame(width: 140.0, height: 140.0)
                    .padding(.top, 62)
                    .padding(.bottom, 20)
                
                Text(Strings.kahftubeUnsubscribeSuccessfulTitle1)
                Text(Strings.kahftubeUnsubscribeSuccessfulTitle2).padding(.bottom, 42)
                
                Button {
                    KahfTubeManager.shared.finishUnsubscribeSession()
                } label: {
                    Text(Strings.kahftubeUnsubscribeSuccessfulAlrightTitle).foregroundColor(Color.white)
                }.frame(width: 175, height: 50.0).background(Color(UIColor(colorString: "#A242FF"))).cornerRadius(10.0).padding(.bottom, 42)
            }.padding(.horizontal, 16)
        }.frame(maxHeight: 372.0).cornerRadius(5.0).padding(.horizontal, 20).cornerRadius(5.0)
    }
}

#if DEBUG
struct KahfTubeSuccessfulView_Previews: PreviewProvider {
    static var previews: some View {
        KahfTubeSuccessfulView()
    }
}
#endif
