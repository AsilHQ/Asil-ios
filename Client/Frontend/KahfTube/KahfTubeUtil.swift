// Copyright 2023 The Asil Browser Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

class KahfTubeUtil {
    
    static let shared = KahfTubeUtil()
    
    func jsFileToCode(path: String, completion: @escaping(String?) -> Void) {
        guard let filePath = Bundle.main.path(forResource: path, ofType: "js") else {
            print("Kahf Tube: Failed to find \(path).js file")
            completion(nil)
            return
        }
        
        do {
            let jsCode = try String(contentsOfFile: filePath)
            completion(jsCode)
        } catch {
            print("Kahf Tube: Failed to read \(path).js file")
            completion(nil)
        }
    }
}
