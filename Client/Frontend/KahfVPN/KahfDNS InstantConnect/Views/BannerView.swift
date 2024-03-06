//
//  BannerView.swift
//  KahfDNS InstantConnect
//
//  Created by Cem Sertkaya on 5.03.2024.
//

import SwiftUI

struct BannerView: View {
    @State var bottomBanner: Banner
    
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
                        .padding(.leading, 2)
                        .padding(.trailing, 2)
                        .onHover { inside in
                            onHover(inside: inside)
                        }
                }
                .transition(.move(edge: .bottom))
                .transition(.slide)
            case .failure(_):
                EmptyView()
            @unknown default:
                EmptyView()
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

