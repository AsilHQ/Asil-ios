//
//  ResizableImageView.swift
//  SwiftUI_DEsigner
//
//  Created by Cem Sertkaya on 19.01.2024.
//

import SwiftUI

struct ResizableImageView: View {
    var imageName: String?
    var image: Image?
    var width: CGFloat
    var height: CGFloat
    
    var body: some View {
        if let imageName = imageName {
            Image(systemName: imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: width, height: height)
        } else if let image = image {
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: width, height: height)
        } else {
            Text("")
        }
       
    }
}
