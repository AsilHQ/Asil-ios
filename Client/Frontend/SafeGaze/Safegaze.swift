// Copyright 2023 The Kahf Browser Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import BraveShared
import BraveCore

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

public class SafegazeManager {
    public static let shared = SafegazeManager()
    public static var ignoredDomains =  [String]()
    
    init() {
        updateIgnoredDomains()
    }
    
    private func updateIgnoredDomains() {
        guard let path = Bundle.module.path(forResource: "safegazeIgnore", ofType: "txt") else {
            return
        }
        
        do {
            let source: String = try String(contentsOfFile: path)
            let lines = source.components(separatedBy: .newlines)
            
            for line in lines {
                
                if line.contains("#") || line.isEmpty {
                  continue
                }
                
                SafegazeManager.ignoredDomains.append(line)
            }
            print("Ignored Domains \(SafegazeManager.ignoredDomains)")
        } catch {
            print("Error reading safegazeIgnore.txt")
        }
    }
    
    public func fetchAndOverwriteSafegazeIgnoreFile() {
        if let latestInstallationDate = Preferences.Safegaze.installationDate.value {
            let calendar = Calendar.current
            let currentDate = Date()
            
            let components = calendar.dateComponents([.day], from: latestInstallationDate, to: currentDate)
            
            if let daysAgo = components.day {
                print("SafegazeManager: The installation date was \(daysAgo) days ago.")
                if daysAgo > 6 {
                    download()
                }
            }
            
        } else {
            download()
        }
    }
    
    private func download() {
        let remoteHostFileURL = URL(string: "https://storage.asil.co/safegazeIgnore.txt")!

        DispatchQueue.global(qos: .background).async {
            if let localSafegazeFilePath = Bundle.module.path(forResource: "safegazeIgnore", ofType: "txt") {
                if let remoteSafegazeFileData = try? Data(contentsOf: remoteHostFileURL) {
                    do {
                        try remoteSafegazeFileData.write(to: URL(fileURLWithPath: localSafegazeFilePath))
                        DispatchQueue.main.async {
                            print("SafegazeManager: safegazeIgnore file downloaded and overwritten successfully.")
                            Preferences.Safegaze.installationDate.value = Date()
                        }
                    } catch {
                        DispatchQueue.main.async {
                            print("SafegazeManager: Error writing to the local safegazeIgnore file: \(error)")
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        print("SafegazeManager: Error downloading the remote safegazeIgnore file.")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    print("SafegazeManager: Local safegazeIgnore file not found.")
                }
            }
        }
    }
    
    public func overwriteSafegazeJs() {
        let remoteHostFileURL = URL(string: "https://raw.githubusercontent.com/AsilHQ/Android/js_code_dev/node_modules/%40duckduckgo/privacy-dashboard/build/app/safe_gaze_v2.js")!

        DispatchQueue.global(qos: .background).async {
            if let localSafegazeFilePath = Bundle.module.path(forResource: "SafegazeScript", ofType: "js") {
                if let remoteSafegazeFileData = try? Data(contentsOf: remoteHostFileURL) {
                    do {
                        try remoteSafegazeFileData.write(to: URL(fileURLWithPath: localSafegazeFilePath))
                        DispatchQueue.main.async {
                            print("SafegazeManager: SafegazeScript file downloaded and overwritten successfully.")
                        }
                    } catch {
                        DispatchQueue.main.async {
                            print("SafegazeManager: Error writing to the local SafegazScript file: \(error)")
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        print("SafegazeManager: Error downloading the remote SafegazeScript file.")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    print("SafegazeManager: Local SafegazeScript file not found.")
                }
            }
        }
    }
}
