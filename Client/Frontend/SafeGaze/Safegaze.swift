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
    
    public func downloadAndSaveJavaScriptFile() {
        let remoteHostFileURL = URL(string: "https://raw.githubusercontent.com/AsilHQ/Android/js_code_release/node_modules/%40duckduckgo/privacy-dashboard/build/app/safe_gaze_v2.js")!
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let localFileURL = documentsURL.appendingPathComponent("SafegazeScript.js")
        
        // Create the download task
        let task = URLSession.shared.dataTask(with: remoteHostFileURL) { data, response, error in
            if let error = error {
                print("Failed to download file: \(error)")
                return
            }
            
            guard let data = data else {
                print("No data downloaded.")
                return
            }
            
            do {
                // Write the downloaded data to the file
                try data.write(to: localFileURL)
                print("SafegazeManager: JavaScript file downloaded and saved successfully.")
            } catch {
                print("SafegazeManager: Failed to save JavaScript file: \(error)")
            }
        }
        
        // Start the download task
        task.resume()
    }
}
