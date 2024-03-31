//
//  TopBannerView.swift
//  KahfDNS InstantConnect
//
//  Created by Cem Sertkaya on 6.03.2024.
//

import SwiftUI

struct TopBannerView: View {
    let companyUrl = "https://halalz.co"
    
    @Binding var showConnectedMessage: Bool
    
    static let backgroundCompanyOriginal = Color(hex: 0xFFFFFF)
    static let backgroundCompanyOnHover = Color(hex: 0xe8fce5)
    @State var backgroundCompanyChangeable = TopBannerView.backgroundCompanyOriginal
    
    var body: some View {
        VStack(spacing: 0) {
            // show connected message to user so he calmly can close the app as vpn will still be connected.
            if showConnectedMessage {
                HStack {
                    Text("Connected. Safe to close this app.")
                        .font(.system(size: 12))
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 15)
                .padding(.top, 5)
                .padding(.bottom, 5)
                .background(KahfGuardContentView.accentColor)
                .foregroundColor(.white)
            }
            
            if !showConnectedMessage {
                Link(destination: URL(string: companyUrl)!) {
                    HStack() {
                        Image(.halalzLogoSmall)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 30)
                        
                        VStack(alignment: .leading) {
                            Text("KahfGuard")
                                .foregroundStyle(.black)
                                .font(.system(size: 14))
                                //.fontWeight(.bold)
                            Text("© by Halalz e-Tİcaret Ltd Şti.")
                                .foregroundStyle(.gray)
                                .font(.system(size: 12))
                        }
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 10)
                    .padding(.leading, 10)
                    .background(backgroundCompanyChangeable)
                }
            }
        }
        .animation(.easeInOut, value: backgroundCompanyChangeable)
        .animation(.easeInOut, value: showConnectedMessage)
    }
}
