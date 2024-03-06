//
//  ContentView.swift
//  KahfDNS InstantConnect
//
//  Created by Mehdi with ♥ / hi@mehssi.com
//  on 15/02/2024.
//

import SwiftUI
import NetworkExtension

struct KahfDNSContentView: View {
    let companyUrl = "https://halalz.co"
    
    let background = Color(hex: 0xF4E6FF)
    let backgroundCompany = Color(hex: 0xF8EFFF)
    
    let VpnConnectObject = VpnConnect()
    let vpnStatusNotification = NotificationCenter.default.publisher(for: NSNotification.Name.NEVPNStatusDidChange)
    
    let api = KahfDNSApi()

    @State var connected = false
    @State var connecting = false
    @State var connectSwitch = false
    @State var error: String?
    @State var totalBlacklistHosts: String?
    @State var bottomBanner: Banner?
    @State var showBottomBanner = false
    
    // view
    var body: some View {
        ZStack(alignment: .top) {
    
            // version
            VStack {
                ScrollView {
                    
                    // company
                    TopBannerView()
                        .frame(minWidth: 0, maxWidth: .infinity, maxHeight: 40)
                        .background(background)

                    // logo
                    Image(uiImage: UIImage(named: "instant-connect", in: .module, compatibleWith: nil)!)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300)
                        .padding(.top, 30)
                    
                    Image(.logo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300)
                        .padding(.top, 0)
                
                    if connecting {
                        // connecting...
                        ProgressView()
                            .tint(Color.gray)
                            .padding(.top, 30)
                    } else {
                        if error != nil {
                            // error
                            Text(error!)
                                .foregroundStyle(.red)
                                .font(.system(size: 14))
                                .padding(.top, 20)
                                .padding(.bottom, -10)
                                .multilineTextAlignment(.center)
                        }
                        
                        Toggle("", isOn: $connectSwitch)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .scaleEffect(CGSize(width: 2.5, height: 2.5))
                            .padding(.top, 40)
                            .tint(.purple)
                            .environment(\.colorScheme, .light)
                            .onChange(of: self.connectSwitch, perform: { status in
                                print("Connect switch (toggle) event.")

                                if status {
                                    if !connected {
                                        connectButtonPressed()
                                    }
                                } else {
                                    if connected {
                                        disconnectButtonPressed()
                                    }
                                }
                            })
                            .onHover { inside in
                                onHover(inside: inside)
                            }
                        
                        if !connected {
                            // not connected
                            
                            Text("Disconnected")
                                .padding(.top, 35)
                                .font(.system(size: 20))
                                // .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .foregroundColor(Color.black)
                            
                            if error == nil {
                                Text("You're not protected from Haram websites.")
                                    .font(.system(size: 15))
                                    .italic()
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(Color.black)
                            }
                        } else {
                            // connected.
                            Text("Connected")
                                .padding(.top, 35)
                                .font(.system(size: 20))
                                // .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .foregroundColor(Color.black)
                            
                            if totalBlacklistHosts != nil {
                                Text("You're protected from \(totalBlacklistHosts!) Haram websites.")
                                    .font(.system(size: 15))
                                    .italic()
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(Color.black)
                            }
                            
                            // verify button
                            (
                                Text("Verify protection: ")
                                .foregroundColor(Color.black)
                                + Text("https://check.kahfdns.com").underline()
                            )
                            .onHover { inside in
                                onHover(inside: inside)
                            }
                            .padding(.top, 20)
                            .padding(.bottom, -30)
                            .font(.system(size: 12))
                            .multilineTextAlignment(.center)
                        }
                    }
                    
                }
                .padding(.leading, 10)
                .padding(.trailing, 10)
                
                #if os(iOS)
                    if showBottomBanner {
                        if let bottomBanner = bottomBanner {
                            BannerView(bottomBanner: bottomBanner)
                        }
                    }
                #else
                #endif
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
        }
        .frame(
            maxWidth: .infinity, minHeight: 480.0,
            maxHeight: .infinity
        )
        .background(background)
        .onAppear(perform: onAppear)
        .onDisappear(perform: onDisappear)
        .onReceive(vpnStatusNotification) { (data) in
            self.onVpnStatusChanged(data: data)
        }
        .animation(.easeInOut, value: connecting)
        .animation(.easeInOut, value: connected)
        .animation(.easeInOut, value: totalBlacklistHosts)
        .animation(.easeInOut, value: error)
        .animation(.easeInOut, value: showBottomBanner)
    }
    
    func setTotalBlacklistHosts() {
        api.getTotalBlacklistHosts { success, errorMessage, total in
            if success {
                totalBlacklistHosts = total
            } else {
                error = errorMessage
            }
        }
    }
    
    func connectButtonPressed() {
        error = nil // clear error.
        connecting = true
        connected = false
        
        // connect vpn
        VpnConnectObject.retried = false
        VpnConnectObject.connect(errorCallback: connectErrorCallback)
    }
    
    func connectErrorCallback(connectError: String, showError: Bool) {
        print("Connect error: \(connectError)")
        if showError {
            error = "Configuration error. Have you deleted VPN configuration in settings? Try connecting again."
        }
    }
    
    func disconnectButtonPressed() {
        error = nil // clear error.
        
        let VpnConnectObject = VpnConnect()
        VpnConnectObject.disconnect()
    }
    
    func onAppear() {
        print("Appeared")
        connected = VpnConnectObject.isVPNConnected()
        connectSwitch = VpnConnectObject.isVPNConnected()
        // set bottom banner
        setBottomBanner()
    }
    
    func onDisappear() {
        print("Disappeared")
    }
    
    func setBottomBanner() {
        api.getBottomBanner { success, errorMessage, banner in
            if success {
                bottomBanner = banner
                showBottomBanner = true
            } else {
                print("setBottomBanner: \(errorMessage ?? "Unknown")")
            }
        }
    }
    
    func onVpnStatusChanged(data: Notification) {
        print("onVpnStatusChanged")
        if let neVpnConnection = data.object as? NEVPNConnection {
            vpnStatusChanged(status: neVpnConnection.status)
        }
    }
    
    func vpnStatusChanged(status: NEVPNStatus) {
        switch status {
        case NEVPNStatus.invalid:
            print("vpnStatusChanged: Invalid")
            error = "The associated VPN configuration doesn’t exist in the Network Extension preferences or isn’t enabled."
            connected = false
            connecting = false
        case NEVPNStatus.disconnected:
            print("vpnStatusChanged: Disconnected")
            if connecting && VpnConnectObject.retried {
                error = "Unable to communicate with server."
            }
            connected = false
            connecting = false
        case NEVPNStatus.connecting:
            print("vpnStatusChanged: Connecting")
            connecting = true
            connected = false
        case NEVPNStatus.connected:
            print("vpnStatusChanged: Connected")
            connecting = false
            connected = true
            connectSwitch = true
            
            // set total blacklist hosts
            setTotalBlacklistHosts()
            
        case NEVPNStatus.reasserting:
            print("vpnStatusChanged: Reasserting")
            connecting = true
            connected = false
        case NEVPNStatus.disconnecting:
            print("vpnStatusChanged: Disconnecting")
            connecting = true
            connected = false
        @unknown default:
            print("vpnStatusChanged: Unknown status")
            connecting = false
            connected = false
        }
        
        if !connecting && !connected {
            connectSwitch = false
        }
    }
    
    func onHover(inside: Bool) {
        #if os(macOS)
            if inside {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        #else
        #endif
    }
    
    @MainActor static func redirect() -> UIView {
        let popupView = KahfDNSContentView()
        return UIHostingController(rootView: popupView).view
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}
