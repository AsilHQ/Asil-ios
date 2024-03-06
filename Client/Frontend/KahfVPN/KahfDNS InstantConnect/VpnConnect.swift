//
//  KahfDNS_InstantConnectApp.swift
//  KahfDNS InstantConnect
//
//  Created by Mehdi with ♥ / hi@mehssi.com
//  on 15/02/2024.
//

import Foundation
import NetworkExtension
import KeychainAccess

public class VpnConnect {
    struct VpnServiceDetailsStruct {
        let name: String
    }
    
    struct VpnDetailsStruct {
        let serverAddress: String
        let sharedSecret: String
        let username: String
        let password: String
    }
    
    struct KeychainDetailsStruct {
        let serviceName: String
        let keySharedSecret: String
        let keyUsername: String
        let keyPassword: String
    }
    
    let vpnServiceDetails = VpnServiceDetailsStruct(
        name: "KahfDNS VPN"
    )
    
    let vpnDetails = VpnDetailsStruct(
        serverAddress: "146.190.201.161",
        sharedSecret: "KahfDns-shared", // case-sensitive
        username: "kahf", // case-sensitive
        password: "KahfDns-p" // case-sensitive
    )
    
    let keychainDetails = KeychainDetailsStruct(
        serviceName: "com.halalz.kahfdns",
        keySharedSecret: "sharedSecret",
        keyUsername: "username",
        keyPassword: "password"
    )
    
    var retried = false
    
    init() {
        print("VPNConnect: init()")
        
        // store vpn details in keychain.
        let keychain = Keychain(service: keychainDetails.serviceName).accessibility(.always)
        
        // these values are provided by server and is used to authenticate user.
        keychain[keychainDetails.keySharedSecret] = vpnDetails.sharedSecret
        keychain[keychainDetails.keyUsername] = vpnDetails.username
        keychain[keychainDetails.keyPassword] = vpnDetails.password
        
        // initialize vpn manager to receive callbacks
        let VpnManager = NEVPNManager.shared()
        VpnManager.loadFromPreferences { (error) -> Void in
            if error != nil {
                print("VPNConnect: init() - Unable to initialize vpn manager.")
            }
        }
    }
    
    private func _makeProtocol() -> NEVPNProtocol {
        print("VPNConnect: _makeProtocol()")
        
        // get username, shared secret and password from keychain
        let keychain = Keychain(service: keychainDetails.serviceName).accessibility(.always)
        let username: String = keychain[keychainDetails.keyUsername]!
        let refSharedSecret = keychain[attributes: keychainDetails.keySharedSecret]?.persistentRef
        let refPassword = keychain[attributes: keychainDetails.keyPassword]?.persistentRef
        
        // setup vpn protocol
        let vpnProtocol = NEVPNProtocolIPSec()
        vpnProtocol.serverAddress = vpnDetails.serverAddress
        vpnProtocol.username = username
        vpnProtocol.authenticationMethod = NEVPNIKEAuthenticationMethod.sharedSecret
        vpnProtocol.sharedSecretReference = refSharedSecret
        vpnProtocol.passwordReference = refPassword
        vpnProtocol.useExtendedAuthentication = true
        vpnProtocol.disconnectOnSleep = false
        vpnProtocol.localIdentifier = ""
        vpnProtocol.remoteIdentifier = ""
        
        return vpnProtocol
    }
    
    /**
        errorCallback(string: errorMessage, displayError: bool)
     */
    func connect(errorCallback: @escaping (String, Bool) -> Void) {
        print("VPNConnect: connect()")
        
        let VpnManager = NEVPNManager.shared()
        
        VpnManager.loadFromPreferences { (error) -> Void in
            if error != nil {
                print("VPNConnect: connect() - VPN Preferences load error (1)")
                print(error ?? "Unknown error")
                errorCallback("Unable to connect with VPN (error: 1)", true)
            } else {
                print("VPNConnect: connect() - Preferences loaded (1)", true)

                VpnManager.protocolConfiguration = self._makeProtocol()
                VpnManager.localizedDescription = self.vpnServiceDetails.name
                VpnManager.isEnabled = true
                VpnManager.isOnDemandEnabled = true
                
                VpnManager.saveToPreferences(completionHandler: { (error) -> Void in
                    if error != nil {
                        print("VPNConnect: connect() - VPN Preferences save error")
                        print(error ?? "Unknown error")
                        errorCallback("Unable to connect with VPN (error: 2)", true)
                    } else {
                        print("VPNConnect: connect() - Preferences saved")

                        // there is a bug where we hve to load two times.
                        VpnManager.loadFromPreferences(completionHandler: { (error) in
                            if error != nil {
                                print("VPNConnect: VPN Preferences load error (2)")
                                print(error ?? "Unknown error")
                                errorCallback("Unable to connect with VPN (error: 3)", true)
                            } else {
                                print("VPNConnect: connect() - Preferences loaded (2)")
                                print("VPNConnect: connect() - Connecting...")
                                
                                do {
                                    // START THE CONNECTION...
                                    try VpnManager.connection.startVPNTunnel()
                                    print("VPNConnect: connect() - connected.")
                                } catch {
                                    // let nsError = error as NSError
                                    // let errorCode = nsError.code
                                    
                                    var displayError = true
                                    if !self.retried {
                                        // we are going to retry, so don't show error now.
                                        displayError = false
                                    }
                                    
                                    print("VPNConnect: connect() - Connection error.")
                                    print("Error: \(error.localizedDescription)")
                                    errorCallback("Unable to connect with VPN (error: 4) \(error.localizedDescription)", displayError)
                                    
                                    if !self.retried {
                                        // retry once.
                                        self.retried = true
                                        self.connect(errorCallback: errorCallback)
                                    }
                                }
                            }
                        })
                    }
                })
            }
        }
    }
    
    func disconnect() {
        print("VPNConnect: disconnect()")
        NEVPNManager.shared().connection.stopVPNTunnel()
    }
    
    func isVPNConnected() -> Bool {
        if NEVPNManager.shared().connection.status == .connected {
           return true
        } else {
           return false
        }
    }

}
