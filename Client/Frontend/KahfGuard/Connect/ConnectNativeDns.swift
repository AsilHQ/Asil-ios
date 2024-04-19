//
//  InternalVpnConnect.swift
//  Kahf Guard
//
//  Created by Mehdi with ♥ / hi@mehssi.com
//

import Foundation
import NetworkExtension

public class ConnectNativeDns {
    public func getServerIpAndDohAddress() -> (ip: String, doh: String) {
        let youtubeSafeSearchDisabled = UserDefaults.standard.bool(forKey: StorageKeys.YOUTUBE_SAFE_SEARCH_DISABLED)
        
        //since we have both servers on same router we are using reserved and floating ip of same server.
        //otherwise ios just ignores the setting if ip is same.
        if (!youtubeSafeSearchDisabled){
            //use default server
            return (ip: "146.190.201.161", doh: "https://sp-dns-doh.kahfguard.com/dns-query")
        } else {
            //use no-youtube-safe-search server
            return (ip: "68.183.239.70", doh: "https://sp-dns-doh-yt.kahfguard.com/dns-query")
        }
    }
    
    private func _prepareDnsManager() -> NEDNSSettingsManager {
        let serverIpAndDoh = getServerIpAndDohAddress()
        let dnsSettingsManager = NEDNSSettingsManager.shared()
        
        let dohSettings = NEDNSOverHTTPSSettings(servers: [ serverIpAndDoh.ip ])
        dohSettings.serverURL = URL(string:  serverIpAndDoh.doh)
        dnsSettingsManager.dnsSettings = dohSettings
        dnsSettingsManager.onDemandRules = [NEOnDemandRuleConnect()]
        
        print(serverIpAndDoh)
        
        return dnsSettingsManager
    }
    
    public func connect(completion: @escaping (_ success: Bool, _ errorMessage: String?) -> Void){
        var dnsSettingsManager = _prepareDnsManager()
        
        dnsSettingsManager.loadFromPreferences { loadError in
            if let loadError = loadError {
                print("ConnectNativeDns: connect: loadError: \(loadError.localizedDescription)")
                completion(false, loadError.localizedDescription)
                return //stop processing
            }
            
            dnsSettingsManager = self._prepareDnsManager()
            dnsSettingsManager.saveToPreferences { saveError in
                if let saveError = saveError {
                    print("ConnectNativeDns: connect: saveError: \(saveError.localizedDescription)")
                    completion(false, saveError.localizedDescription)
                } else {
                    print("ConnectNativeDns: connect: Success")
                    completion(true, nil)
                }
                return //stop processing
            }
        }
    }
    
    public func disconnect(completion: @escaping (_ success: Bool, _ errorMessage: String?) -> Void){
        let dnsSettingsManager = _prepareDnsManager()

        dnsSettingsManager.removeFromPreferences { error in
            if let error = error {
                print("ConnectNativeDns: disconnect: Error: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
            } else {
                print("ConnectNativeDns: disconnect: Success")
                completion(true, nil)
            }
            return //stop processing
        }
    }
    
    public func check(completion: @escaping (_ connected: Bool) -> Void) -> Void {
        let dnsSettingsManager = _prepareDnsManager()
        
        dnsSettingsManager.loadFromPreferences { _ in
            completion(dnsSettingsManager.isEnabled)
        }
    }
}
