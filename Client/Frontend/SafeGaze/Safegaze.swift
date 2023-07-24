// Copyright 2023 The Asil Browser Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

public enum Safegaze {
  case AllOff
  case Open

  public var globalPreference: Bool {
    switch self {
    case .AllOff:
      return false
    case .Open:
      return true
    }
  }
}
