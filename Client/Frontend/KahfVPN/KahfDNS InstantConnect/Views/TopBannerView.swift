//
//  TopBannerView.swift
//  KahfDNS InstantConnect
//
//  Created by Cem Sertkaya on 6.03.2024.
//

import SwiftUI
import BraveShared

struct TopBannerView: View {
    let companyUrl = "https://halalz.co"
    let backgroundCompany = Color(hex: 0xF8EFFF)
    
    var body: some View {
        Group {
            Link(destination: URL(string: companyUrl)!) {
                HStack() {
                    Image(uiImage: UIImage(named: "halalz-logo-small", in: .module, compatibleWith: nil)!)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 30)
                    
                    VStack(alignment: .leading) {
                        Text(Strings.kahfDnsBroughtToYouTitle)
                            .foregroundStyle(.gray)
                            .font(.system(size: 11))
                        Text("© Halalz Ltd, Turkey.")
                            .foregroundStyle(.gray)
                            .font(.system(size: 12))
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 5)
                .padding(.bottom, 5)
                .padding(.leading, 10)
                .background(backgroundCompany)
            }.onHover { inside in
                onHover(inside: inside)
            }
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
}

#Preview {
    TopBannerView()
}
