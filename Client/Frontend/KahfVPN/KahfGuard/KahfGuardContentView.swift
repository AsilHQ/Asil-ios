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
    @State var reconnectOnChange = false
    @State var error: String?
    @State var totalBlacklistHosts: String?
    @State var bottomBanner: Banner?
    @State var showBottomBanner = false
    @State var showBottomButtons: Bool = false
    
    @State var overVerifyButton = false
    let overVerifyColor = Color(hex: 0x000)
    
    @State var showConnectedMessage = false
    
    @State var youtubeSafeSearchDisabled =  UserDefaults.standard.bool(forKey: VpnConnect.storageKeys.youtubeSafeSearchDisabled)
    
    var onConnectionStatusChanged: ((Bool) -> Void)?
    var onTotalBlacklistHostsFetched: ((Int64) -> Void)?
    init(onConnectionStatusChanged: ((Bool) -> Void)? = nil, onTotalBlacklistHostsFetched: ((Int64) -> Void)? = nil) {
        self.onConnectionStatusChanged = onConnectionStatusChanged
        self.onTotalBlacklistHostsFetched = onTotalBlacklistHostsFetched
        
    }
    
    // view
    var body: some View {
        ZStack(alignment: .top) {
            // company
            TopBannerView(showConnectedMessage: $showConnectedMessage)
            
            // version
            VStack {
                VStack (alignment: .center) {
                    // logo
                    Image(.logo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300)
                        .padding(.top, -80)

                    if connecting || reconnectOnChange {
                        // connecting...
                        ProgressView()
                            .tint(Color.gray)
                            .padding(.top, 0)
                        
                    } else {
                        if error != nil && !connected {
                            // error
                            Text(error!)
                                .foregroundStyle(.red)
                                .font(.system(size: 14))
                                .padding(.top, 40)
                                .padding(.leading, 10)
                                .padding(.trailing, 10)
                                .multilineTextAlignment(.center)
                        }
                        
                        Toggle("", isOn: $connectSwitch)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .scaleEffect(CGSize(width: 2.5, height: 2.5))
                            .padding(.top, 20)
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
                            
                            // switch server type
                            Toggle(isOn: $youtubeSafeSearchDisabled) {
                                        Text("(Optional) Disable safe search in Youtube.")
                                        .opacity(youtubeSafeSearchDisabled ? 1 : 0.5)
                                        .font(.custom("Poppins-Italic", size: 12))
                                        .foregroundStyle(.black)
                                        .animation(.easeInOut, value: youtubeSafeSearchDisabled)

                            }
                            .padding(.horizontal, 20)
                            .onChange(of: self.youtubeSafeSearchDisabled, perform: { enabled in
                                print("Toggle Youtube Safe search event.")
                                youtubeSafeSearchToggled(enabled: enabled)
                            })
                            
                            // verify button
                            Link(destination: URL(string: verifyLink)!) {
                                Text("Verify Protection")
                                    .font(.custom("Poppins-Regular", size: 13))
                                    .underline()
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 10)
                            }
                            .foregroundStyle(overVerifyButton ? overVerifyColor : KahfGuardContentView.accentColor)
                            .animation(.easeInOut, value: overVerifyButton)
                        }
                    }
                }
                .padding(.leading, 0)
                .padding(.trailing, 0)
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
            
            Group{
                VStack (spacing: 0) {
                    if showBottomBanner {
                        if let bottomBanner = bottomBanner {
                            BannerView(bottomBanner: bottomBanner)
                            .onAppear {
                                print("Bottom banner appeared")
                                //show bottom buttons
                                Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                                    showBottomButtons = true
                                }
                            }
                            
                            if showBottomButtons {
                                BottomButtonsContainerView()
                            }
                            
                        }
                    }
                }
            }.frame(maxHeight: .infinity, alignment: .bottom)
        }
        .frame(
            maxWidth: .infinity,
            minHeight: 400,
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
        .animation(.easeInOut, value: showBottomButtons)
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
        connecting = true
        let vpnConnectObject = VpnConnect()
        vpnConnectObject.disconnect()
    }
    
    func youtubeSafeSearchToggled(enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: VpnConnect.storageKeys.youtubeSafeSearchDisabled)
        reconnectOnChange = true
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
            
            if (reconnectOnChange){
                reconnectOnChange = false
                connectButtonPressed()
            }
        case NEVPNStatus.connecting:
            print("vpnStatusChanged: Connecting")
            error = nil
            connecting = true
            connected = false
            showConnectedMessage = false
            
            onConnectionStatusChanged?(false)
        case NEVPNStatus.connected:
            print("vpnStatusChanged: Connected")
            error = nil
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

    @MainActor static func redirect() -> UIView {
        let popupView = KahfGuardContentView()
        return UIHostingController(rootView: popupView).view
    }
}

#Preview {
    KahfGuardContentView()
}
