// Copyright 2023 The Kahf Browser Authors. All rights reserved.
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
            case .all: return Strings.kahftubeGenderAllTitle
            case .male: return Strings.kahftubeGenderMaleTitle
            case .female: return Strings.kahftubeGenderFemaleTitle
            case .child: return Strings.kahftubeGenderChildTitle
            case .exceptChild: return Strings.kahftubeGenderExceptTitle
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
            case .haram: return Strings.kahftubeReligionHaramTitle
            case .practicingMuslim: return Strings.kahftubeReligionPracticingMuslimTitle
            case .liberalMuslim: return Strings.kahftubeReligionLiberalMuslimTitle
            case .moderateMuslim: return Strings.kahftubeReligionModerateMuslimTitle
        }
    }
}
