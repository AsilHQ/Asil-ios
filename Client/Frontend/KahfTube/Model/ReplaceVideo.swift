// Copyright 2023 The Asil Browser Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

struct ReplaceVideo: Codable {
    let id: String
    let href: String
    var thumbnail: String?
    var timeline: String?
    var views: String?
    
    init(id: String, href: String) {
        self.id = id
        self.href = href
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(thumbnail, forKey: .thumbnail)
        try container.encode(timeline, forKey: .timeline)
        try container.encode(views, forKey: .views)
    }
    
    enum CodingKeys: String, CodingKey {
           case id
           case href
           case thumbnail
           case timeline
           case views
    }
}
