//
//  BannerView.swift
//  KahfDNS InstantConnect
//
//  Created by Cem Sertkaya on 5.03.2024.
//

import SwiftUI

struct BannerView: View {
    @State var bottomBanner: Banner
    @State var opacity = 1.0
    
    var body: some View {
        AsyncImage(url: URL(string: bottomBanner.image), transaction: Transaction(animation: .bouncy)) { phase in
            switch phase {
            case .empty:
                EmptyView()
            case .success(let image):
                Link(destination: URL(string: bottomBanner.link)!) {
                    image.resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: 90)
                        .padding(.leading, 10)
                        .padding(.trailing, 10)
                }
                .transition(.move(edge: .bottom))
                .transition(.slide)
            case .failure:
                EmptyView()
            @unknown default:
                EmptyView()
            }
        }
        .opacity(opacity)
        .animation(.easeInOut, value: opacity)
    }
}
