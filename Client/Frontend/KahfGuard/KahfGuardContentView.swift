//
//  KahfGuardContentView.swift
//  KahfDNS InstantConnect
//
//  Created by Mehdi with ♥ / hi@mehssi.com
//  on 15/02/2024.
//

import SwiftUI
import NetworkExtension
import SwiftUI
import Storage
import SnapKit
import Shared
import BraveShared
import Data
import BraveUI
import UIKit
import Growth
import BraveCore


struct KahfGuardContentView: View {
    @Environment(\.scenePhase) var scenePhase

    static let background = Color(hex: 0xf2faf1)
    static let accentColor = Color(hex: 0x39b634)

    let verifyLink = "https://check.kahfguard.com/"

    let externalVpnConnectObject = ConnectExternalVpn()
    let externalVpnStatusNotification = NotificationCenter.default.publisher(for: NSNotification.Name.NEVPNStatusDidChange)

    let api = Api()

    @State var selectedVpnType: Int = UserDefaults.standard.integer(forKey: StorageKeys.VPN_TYPE);
    @State var connected = false
    @State var connecting = false
    @State var connectSwitch = false
    @State var reconnectOnChange = false
    @State var reconnectToNativeDns = false;
    @State var error: String?
    @State var totalBlacklistHosts: String?
    @State var bottomBanner: Banner?
    @State var showBottomBanner = false
    @State var showBottomButtons: Bool = false
    @State var userManuallyDisabledNativeDns = false;
    @State var userManuallyDisabledNativeDnsShowAlert = false;

    @State var overVerifyButton = false
    let overVerifyColor = Color(hex: 0x000)

    @State var showConnectedMessage = false

    @State var youtubeSafeSearchDisabled =  UserDefaults.standard.bool(forKey: StorageKeys.YOUTUBE_SAFE_SEARCH_DISABLED)

    var onConnectionStatusChanged: ((Bool) -> Void)?
    var onTotalBlacklistHostsFetched: ((Int64) -> Void)?
    init(onConnectionStatusChanged: ((Bool) -> Void)? = nil, onTotalBlacklistHostsFetched: ((Int64) -> Void)? = nil) {
        self.onConnectionStatusChanged = onConnectionStatusChanged
        self.onTotalBlacklistHostsFetched = onTotalBlacklistHostsFetched

    }

    init(){
        //beprint("KahfGuardContentView: init")/Users/cemsertkaya/KahfGuard-iOS/KahfGuard/KahfGuard
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
                        .padding(.top, -100)

                    if connecting || reconnectOnChange {
                        // connecting...
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.gray))
                            .padding(.top, 0)
                            .controlSize(.large)

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
                            .toggleStyle(SwitchToggleStyle(tint: KahfGuardContentView.accentColor))
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
                                .foregroundStyle(Color.black)
                            
                            if error == nil {
                                Text("You're not protected from Haram websites.")
                                    .font(.custom("Poppins-Regular", size: 13))
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(Color.black)
                            }
                            
                            //give option to select vpn type
                            if (VpnType.SHOW_CONNECT_OPTIONS){
                                if (!reconnectOnChange && !connecting){
                                    Picker("", selection: $selectedVpnType) {
                                        Text("Native DNS (Faster)").tag(VpnType.INTERNAL)
                                        Text("VPN (Secure)").tag(VpnType.EXTERNAL)
                                    }.accentColor(KahfGuardContentView.accentColor)
                                }
                            }
                        } else {
                            // connected.
                            Text("Connected")
                                .padding(.top, 20)
                                .font(.custom("Poppins-Bold", size: 22))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Color.black)

                            if (!userManuallyDisabledNativeDns){
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
                                    .foregroundStyle(.black)
                                }

                                // switch server type
                                Toggle(isOn: $youtubeSafeSearchDisabled) {
                                    Text("(Optional) Disable safe search in Youtube.")
                                        .opacity(youtubeSafeSearchDisabled ? 1 : 0.5)
                                        .font(.custom("Poppins-Regular", size:10))
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
                                        .padding(.top, 20)
                                }
                                .foregroundStyle(overVerifyButton ? overVerifyColor : KahfGuardContentView.accentColor)
                                .animation(.easeInOut, value: overVerifyButton)
                            } else {
                                VStack {
                                }.alert("Enable Kahf Guard in your \(isIpad() ? "iPad" : "iPhone")", isPresented: $userManuallyDisabledNativeDnsShowAlert, actions: { // 3
                                    Button("Cancel", role: .cancel) {
                                        print("Native DNS alert - cancel button pressed")
                                        disconnectButtonPressed()
                                    }
                                }, message: {
                                    Text("Please Open \(isIpad() ? "iPad" : "iPhone") Settings ⇒ General ⇒ VPN & Device Management ⇒ DNS ⇒ Select Kahf Guard.")

                                })

                            }
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
            maxWidth: .infinity, minHeight: 550,
            maxHeight: .infinity
        )
        .background(KahfGuardContentView.background)
        .onAppear(perform: onAppear)
        .onDisappear(perform: onDisappear)
        .onReceive(externalVpnStatusNotification) { (data) in
            self.onExternalVpnStatusChanged(data: data)
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .inactive:
                //app inactive
                break;
            case .active:
                //app in foreground
                appInForeground();
                break;
            case .background:
                //app in background
                break;
            @unknown default:
                break;
            }
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

    func isIpad() -> Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }

    func appInForeground(){
        print("appInForeground")
        if (selectedVpnType == VpnType.INTERNAL){
            (ConnectNativeDns()).check(completion: { connected in
                print("appInForeground: native dns: \(connected)")
                if (connected){
                    setConnected()
                    userManuallyDisabledNativeDns = false;
                } else {
                    let lastStatus = UserDefaults.standard.bool(forKey: StorageKeys.USER_CONNECT_TOGGLE_STATUS);
                    if (lastStatus){
                        print("appInForeground: native dns: not connected, but user last selected our option so he might disabled it manually")
                        userManuallyDisabledNativeDns = true
                        userManuallyDisabledNativeDnsShowAlert = true;
                        setConnected()
                    } else {
                        userManuallyDisabledNativeDns = false;
                        userManuallyDisabledNativeDnsShowAlert = false;
                        setDisconnected()
                    }
                }
            })
        }
    }

    func onAppear() {
        print("Appeared")

        // set bottom banner
        setBottomBanner()
    }

    func onDisappear() {
        print("Disappeared")
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
        userManuallyDisabledNativeDns = false;

        //store user's selected vpn type
        UserDefaults.standard.set(selectedVpnType, forKey: StorageKeys.VPN_TYPE)

        //store user's connect status so we can check if he disabled dns profile directly.
        UserDefaults.standard.set(true, forKey: StorageKeys.USER_CONNECT_TOGGLE_STATUS)

        //connect vpn
        if (selectedVpnType == VpnType.EXTERNAL){
            print("Connect: External")
            externalVpnConnectObject.retried = false
            externalVpnConnectObject.connect(errorCallback: connectErrorCallback)
        } else {
            print("Connect: Internal")
            let nativeDnsConnectObject = ConnectNativeDns()
            nativeDnsConnectObject.connect(completion: { success, errorMessage in
                connecting = false

                if success {
                    //check if dns profile activated
                    (ConnectNativeDns()).check(completion: { connected in
                        if (connected){
                            setConnected()
                        } else {
                            setConnected()
                            userManuallyDisabledNativeDns = true;
                            userManuallyDisabledNativeDnsShowAlert = true;
                        }
                    })
                } else {
                    error = errorMessage
                    connectSwitch = false
                }
            })
        }
    }

    func connectErrorCallback(connectError: String, showError: Bool) {
        print("Connect error: \(connectError)")
        connected = false
        connectSwitch = false
        connecting = false
        if showError {
            error = "Kahf Guard can not be connected without VPN configuration."
        }
    }

    func disconnectButtonPressed() {
        error = nil // clear error.
        connecting = true
        userManuallyDisabledNativeDns = false;

        //store user's connect status so we can check if he disabled dns profile directly.
        UserDefaults.standard.set(false, forKey: StorageKeys.USER_CONNECT_TOGGLE_STATUS)

        if (selectedVpnType == VpnType.EXTERNAL){
            print("Disconnect: External")
            let externalVpnConnectObject = ConnectExternalVpn()
            externalVpnConnectObject.disconnect()
        } else {
            if (reconnectOnChange){
                reconnectOnChange = false
                connectButtonPressed()
            } else {
                print("Disconnect: Internal")

                let nativeDnsConnectObject = ConnectNativeDns()
                nativeDnsConnectObject.disconnect(completion: { success, errorMessage in
                    setDisconnected()
                    if (!success){
                        print("Disconnect: Internal. Error: \(errorMessage)")
                    }

                })
            }
        }
    }

    func youtubeSafeSearchToggled(enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: StorageKeys.YOUTUBE_SAFE_SEARCH_DISABLED)
        reconnectOnChange = true

        if (selectedVpnType == VpnType.EXTERNAL){
            externalVpnConnectObject.disconnect()
        } else {
            disconnectButtonPressed()
        }
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

    func onExternalVpnStatusChanged(data: Notification) {
        print("onVpnStatusChanged")
        if (selectedVpnType == VpnType.EXTERNAL){
            if let neVpnConnection = data.object as? NEVPNConnection {
                externalVpnStatusChanged(status: neVpnConnection.status)
            }
        }
    }

    func externalVpnStatusChanged(status: NEVPNStatus) {
        switch status {
        case NEVPNStatus.invalid:
            print("vpnStatusChanged: Invalid")
            error = "The associated VPN configuration doesn’t exist in the Network Extension preferences or isn’t enabled."
            connected = false
            connecting = false
            showConnectedMessage = false

            onConnectionStatusChanged?(false)
        case NEVPNStatus.connecting:
            print("vpnStatusChanged: Connecting")
            error = nil
            connecting = true
            connected = false
            showConnectedMessage = false

            onConnectionStatusChanged?(false)
        case NEVPNStatus.connected:
            print("vpnStatusChanged: Connected")
            setConnected();
        case NEVPNStatus.disconnected:
            print("vpnStatusChanged: Disconnecting")
            setDisconnected();
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

        if (connected){
            if (!VpnType.SHOW_CONNECT_OPTIONS){
                print("Disconnecting from external vpn as we no longer provide it.")
                reconnectToNativeDns = true
                disconnectButtonPressed()
            }
        }
    }

    func setConnected(){
        error = nil
        connecting = false
        connected = true
        connectSwitch = true
        showConnectedMessage = true

        // set total blacklist hosts
        setTotalBlacklistHosts()

        onConnectionStatusChanged?(true)
    }

    func setDisconnected(){
        if connecting && externalVpnConnectObject.retried {
            error = "Unable to communicate with server."
        } else {
            error = nil
        }
        connected = false
        connecting = false
        connectSwitch = false
        showConnectedMessage = false

        onConnectionStatusChanged?(false)

        if (reconnectOnChange){
            print("Disconnected, but reconnecting...")
            reconnectOnChange = false
            connectButtonPressed()
        } else if (reconnectToNativeDns){
            print("Disconnected, but reconnecting to native dns...")
            reconnectToNativeDns = false
            selectedVpnType = VpnType.INTERNAL
            connectButtonPressed()

            //remove vpn profile
            externalVpnConnectObject.removeProfile()
        }
    }

    @MainActor static func redirect() -> UIView {
        return UIHostingController(rootView: KahfGuardContentView()).view
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
