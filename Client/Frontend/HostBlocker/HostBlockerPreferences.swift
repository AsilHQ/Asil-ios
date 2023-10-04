// Copyright 2023 The Asil Browser Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveShared

extension Preferences {
  public final class HostBlocker {
    public static let installationDate = Option<Date?>(key: "hostBlocker.installation-date", default: nil)
  }
}
