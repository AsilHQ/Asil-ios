// Copyright 2023 The Kahf Browser Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import SwiftUI
import BraveUI
import BraveShared

/// A menu button that provides a shortcut to toggling Night Mode
struct KahfTubeMenuButton: View {
  @Binding var kafhTubeIsOn: Bool

  var body: some View {
    VStack {
      Text("KahfTube")
      Spacer()
        Toggle("", isOn: $kafhTubeIsOn)
        .labelsHidden()
        .toggleStyle(SwitchToggleStyle(tint: Color(UIColor(colorString: "#A242FF"))))
        .onChange(of: kafhTubeIsOn) { value in
            KahfTubeManager.shared.reload()
        }
    }
    .frame(maxWidth: .infinity)
    .frame(height: 48)
  }
}

