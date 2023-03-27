// Copyright 2023 The Asil Browser Authors. All rights reserved.
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
  @ObservedObject private var kafhTubeIsOn = Preferences.KahfTube.isOn

  var dismiss: () -> Void

  var body: some View {
    HStack {
      MenuItemFactory.button(for: .kafhTube, completion: dismiss)
      Spacer()
      Toggle("", isOn: $kafhTubeIsOn.value)
        .labelsHidden()
        .toggleStyle(SwitchToggleStyle(tint: .accentColor))
        .onChange(of: kafhTubeIsOn.value) { value in
            KahfTubeManager.shared.reload()
        }
    }
    .padding(.trailing, 14)
    .frame(maxWidth: .infinity, minHeight: 48.0)
  }
}

