// Copyright 2023 The Kahf Browser Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import BraveShared
import BraveCore

public class HostBlockerManager: ObservableObject {
    
    public static let shared = HostBlockerManager()
    
    public func fetchAndOverwriteHostFile() {
        if let latestInstallationDate = Preferences.HostBlocker.installationDate.value {
            let calendar = Calendar.current
            let currentDate = Date()
            
            let components = calendar.dateComponents([.day], from: latestInstallationDate, to: currentDate)
            
            if let daysAgo = components.day {
                print("HostBlockerManager: The installation date was \(daysAgo) days ago.")
                if daysAgo > 6 {
                    download()
                }
            }
            
        } else {
            download()
        }
    }
    
    private func download() {
        let remoteHostFileURL = URL(string: "https://storage.asil.co/hosts")!

        DispatchQueue.global(qos: .background).async {
            if let localHostFilePath = Bundle.module.path(forResource: "hosts", ofType: "txt") {
                if let remoteHostFileData = try? Data(contentsOf: remoteHostFileURL) {
                    do {
                        try remoteHostFileData.write(to: URL(fileURLWithPath: localHostFilePath))
                        DispatchQueue.main.async {
                            print("HostBlockerManager: Host file downloaded and overwritten successfully.")
                            Preferences.HostBlocker.installationDate.value = Date()
                        }
                    } catch {
                        DispatchQueue.main.async {
                            print("HostBlockerManager: Error writing to the local host file: \(error)")
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        print("HostBlockerManager: Error downloading the remote host file.")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    print("HostBlockerManager: Local host file not found.")
                }
            }
        }
    }
}
