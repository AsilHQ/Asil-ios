//
//  KahfGuardContentView.swift
//  KahfDNS InstantConnect
//
//  Created by Mehdi with ♥ / hi@mehssi.com
//  on 15/02/2024.
//

import SwiftUI
import NetworkExtension

struct KahfGuardContentView: View {
    static let background = Color(hex: 0xf2faf1)
    static let accentColor = Color(hex: 0x39b634)
    
    let verifyLink = "https://check.kahfguard.com/"
    
    let vpnConnectObject = VpnConnect()
    let vpnStatusNotification = NotificationCenter.default.publisher(for: NSNotification.Name.NEVPNStatusDidChange)
    
    let api = Api()

    @State var connected = false
    @State var connecting = false
    @State var connectSwitch = false
    @State var error: String?
    @State var totalBlacklistHosts: String?
    @State var bottomBanner: Banner?
    @State var showBottomBanner = false
    
    @State var overVerifyButton = false
    let overVerifyColor = Color(hex: 0x000)
    
    @State var showConnectedMessage = false
    
    var onConnectionStatusChanged: ((Bool) -> Void)?
    var onTotalBlacklistHostsFetched: ((Int64) -> Void)?
    init(onConnectionStatusChanged: ((Bool) -> Void)? = nil, onTotalBlacklistHostsFetched: ((Int64) -> Void)? = nil) {
        self.onConnectionStatusChanged = onConnectionStatusChanged
        self.onTotalBlacklistHostsFetched = onTotalBlacklistHostsFetched
        
    }
    
    // view
    var body: some View {
        ZStack(alignment: .top) {
            // version
            VStack {
                ScrollView {
                    // company
                    TopBannerView(showConnectedMessage: $showConnectedMessage)

                    // logo
                    Image(.logo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300)
                        .padding(.top, 30)

                    if connecting {
                        // connecting...
                        ProgressView()
                            .tint(Color.gray)
                            .padding(.top, 30)

                    } else {
                        if error != nil && !connected {
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
                            .padding(.top, 50)
                            .tint(KahfGuardContentView.accentColor)
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
                                onConnectToggleHover(inside: inside)
                            }

                        if !connected {
                            // not connected

                            Text("Disconnected")
                                .padding(.top, 20)
                                .font(.custom("Poppins-Bold", size: 22))
                                .multilineTextAlignment(.center)
                                .foregroundColor(Color.black)

                            if error == nil {
                                Text("You're not protected from Haram websites.")
                                    .font(.custom("Poppins-Regular", size: 13))
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(Color.black)
                            }
                        } else {
                            // connected.
                            Text("Connected")
                                .padding(.top, 20)
                                .font(.custom("Poppins-Bold", size: 22))
                                .multilineTextAlignment(.center)
                                .foregroundColor(Color.black)

                            if totalBlacklistHosts != nil {
                                Group {
                                    Text("You're protected from ")
                                        .font(.custom("Poppins-Regular", size: 13))
                                    + Text(totalBlacklistHosts!)
                                        .font(.custom("Poppins-Bold", size: 13))
                                    + Text(" Haram websites.")
                                        .font(.custom("Poppins-Regular", size: 13))
                                }
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(Color.black)
                            }

                            // verify button
                            Link(destination: URL(string: verifyLink)!) {
                                Text("Verify Protection")
                                    .font(.custom("Poppins-Regular", size: 13))
                                    .underline()
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 15)
                            }
                            .onHover { inside in
                                onVerifyButtonHover(inside: inside)
                                overVerifyButton = inside
                            }
                            .foregroundStyle(overVerifyButton ? overVerifyColor : KahfGuardContentView.accentColor)
                            .animation(.easeInOut, value: overVerifyButton)
                        }
                    }

                    #if os(iOS)
                        if showBottomBanner {
                            if let bottomBanner = bottomBanner {
                                BannerView(bottomBanner: bottomBanner)
                            }
                        }
                    #else
                    #endif
                }
                .padding(.leading, 0)
                .padding(.trailing, 0)

                // bottom banner
                #if os(macOS)
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
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .background(KahfGuardContentView.background)
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
        .animation(.easeInOut, value: showConnectedMessage)

        // prefer light mode.
        .preferredColorScheme(.light)

    }

    func setTotalBlacklistHosts() {
        api.getTotalBlacklistHosts { success, errorMessage, totalFormatted, totalUnformatted in
            if success {
                totalBlacklistHosts = totalFormatted
                onTotalBlacklistHostsFetched?(totalUnformatted)
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
        vpnConnectObject.retried = false
        vpnConnectObject.connect(errorCallback: connectErrorCallback)
    }
    
    func connectErrorCallback(connectError: String, showError: Bool) {
        print("Connect error: \(connectError)")
        if showError {
            error = "Configuration error. Have you deleted VPN configuration in settings? Try connecting again."
        }
    }
    
    func disconnectButtonPressed() {
        error = nil // clear error.

        let vpnConnectObject = VpnConnect()
        vpnConnectObject.disconnect()
    }
    
    func onAppear() {
        print("Appeared")
        
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
            showConnectedMessage = false
            
            onConnectionStatusChanged?(false)
        case NEVPNStatus.disconnected:
            print("vpnStatusChanged: Disconnected")
            if connecting && vpnConnectObject.retried {
                error = "Unable to communicate with server."
            }
            connected = false
            connecting = false
            showConnectedMessage = false
            
            onConnectionStatusChanged?(false)
        case NEVPNStatus.connecting:
            print("vpnStatusChanged: Connecting")
            connecting = true
            connected = false
            showConnectedMessage = false
            
            onConnectionStatusChanged?(false)
        case NEVPNStatus.connected:
            print("vpnStatusChanged: Connected")
            connecting = false
            connected = true
            connectSwitch = true
            showConnectedMessage = true
            
            // set total blacklist hosts
            setTotalBlacklistHosts()
            
            onConnectionStatusChanged?(true)
        case NEVPNStatus.reasserting:
            print("vpnStatusChanged: Reasserting")
            connecting = true
            connected = false
            showConnectedMessage = false
            
            onConnectionStatusChanged?(false)
        case NEVPNStatus.disconnecting:
            print("vpnStatusChanged: Disconnecting")
            connecting = true
            connected = false
            showConnectedMessage = false
            
            onConnectionStatusChanged?(false)
        @unknown default:
            print("vpnStatusChanged: Unknown status")
            connecting = false
            connected = false
            showConnectedMessage = false
            
            onConnectionStatusChanged?(false)
        }
        
        if !connecting && !connected {
            connectSwitch = false
        }
    }
    
    func onConnectToggleHover(inside: Bool) {
        #if os(macOS)
            if inside {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        #else
        #endif
    }
    
    func onVerifyButtonHover(inside: Bool) {
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
        let popupView = KahfGuardContentView()
        return UIHostingController(rootView: popupView).view
    }
}

#Preview {
    KahfGuardContentView()
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
