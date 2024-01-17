// Copyright 2023 The Asil Browser Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

enum KahftubeGender: Int {
    case all = 1
    case male = 2
    case female = 3
    case child = 4
    case exceptChild = -4
    
    var localizedString: String {
        switch self {
            case .all: return "All"
            case .male: return "Male"
            case .female: return "Female"
            case .child: return "Child"
            case .exceptChild: return "Except"
        }
    }
}

enum KahftubeMode: Int {
    case haram = 0
    case practicingMuslim = 1
    case liberalMuslim = 2
    case moderateMuslim = 3
    
    var localizedString: String {
        switch self {
            case .haram: return "Haram"
            case .practicingMuslim: return "Practicing Muslim"
            case .liberalMuslim: return "Liberal Muslim"
            case .moderateMuslim: return "Moderate Muslim"
        }
    }
}
