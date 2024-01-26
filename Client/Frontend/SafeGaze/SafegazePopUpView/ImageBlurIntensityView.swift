// Copyright 2024 The Asil Browser Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI

struct ImageBlurIntensityView: View {
    @Binding var value: Float
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 19) {
                
                Spacer()
                
                Text("Image Blur Intensity")
                    .font(FontHelper.quicksand(size: 13, weight: .bold))
                    .foregroundColor(.black)
                
                SliderView(value: $value)
                    .frame(height: 23)
                    .cornerRadius(3)
                
                Spacer()
                
            }.padding(.leading, 12).padding(.top, 11).padding(.bottom, 19)
            
            Spacer()
            
            ResizableImageView(image: Image(braveSystemName: "sg.blur.sample"), width: 64, height: 46)
                .scaledToFill()
                .blur(radius: Double(value) * 10)
                .cornerRadius(8)
                .padding(.trailing, 11)
        }
        .frame(height: 79)
        .background(.white)
        .cornerRadius(10)
        .shadow(color: Color(red: 0.49, green: 0.52, blue: 0.56).opacity(0.12), radius: 2.5, x: 0, y: 1)
        .padding(.horizontal, 18)
    }
}

struct SliderView: View {
    @Binding var value: Float
    @State var lastCoordinateValue: CGFloat = 0.0
    var sliderRange: ClosedRange<CGFloat> = 0...1
    var thumbColor: Color = .yellow
    var minTrackColor: Color = Color(red: 0.06, green: 0.7, blue: 0.79)
    var maxTrackColor: Color = Color(red: 0.9, green: 0.9, blue: 0.9)
    
    var body: some View {
        GeometryReader { gr in
            let thumbWidth = 10.258
            let radius = gr.size.height * 0.5
            let minValue = 0.0
            let maxValue = (gr.size.width * 0.95) - thumbWidth
            
            let scaleFactor = Double(maxValue - minValue) / Double(sliderRange.upperBound - sliderRange.lowerBound)
            let lower = sliderRange.lowerBound
            let sliderVal = (Double(self.value) - lower) * scaleFactor + minValue
            
            ZStack {
                Color.clear
                
                Rectangle()
                    .foregroundColor(maxTrackColor)
                    .frame(width: gr.size.width, height: 5)
                    .clipShape(RoundedRectangle(cornerRadius: radius))
                HStack {
                    Rectangle()
                        .foregroundColor(minTrackColor)
                        .frame(width: max(0, sliderVal), height: 5)
                    Spacer()
                }
                .clipShape(RoundedRectangle(cornerRadius: radius))
                
                HStack {
                    ZStack {
                        Rectangle()
                            .foregroundColor(.clear)
                            .frame(width: 10.258, height: 10.258)
                            .background(
                                LinearGradient(
                                    stops: [
                                        Gradient.Stop(color: Color(red: 0.11, green: 0.87, blue: 0.96), location: 0.00),
                                        Gradient.Stop(color: Color(red: 0.01, green: 0.6, blue: 0.72), location: 1.00),
                                        Gradient.Stop(color: Color(red: 0.01, green: 0.6, blue: 0.72), location: 1.00),
                                    ],
                                    startPoint: UnitPoint(x: 0.5, y: 0),
                                    endPoint: UnitPoint(x: 0.5, y: 1)
                                )
                            )
                            .shadow(color: Color(red: 0.08, green: 0.32, blue: 0.4).opacity(0.4), radius: 2, x: 0, y: 2)
                            .cornerRadius(10.258 / 2)
                    }
                    .frame(width: 23, height: 23)
                    .background(.white)
                    .cornerRadius(23 / 2)
                    .shadow(color: Color(red: 0.49, green: 0.52, blue: 0.49).opacity(0.15), radius: 2.5, x: 0, y: 1)
                    .offset(x: sliderVal)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { v in
                                if abs(v.translation.width) < 0.1 {
                                    self.lastCoordinateValue = sliderVal
                                }
                                if v.translation.width > 0 {
                                    let nextCoordinateValue = min(maxValue, self.lastCoordinateValue + v.translation.width)
                                    self.value = Float(((nextCoordinateValue - minValue) / scaleFactor)  + lower)
                                } else {
                                    let nextCoordinateValue = max(minValue, self.lastCoordinateValue + v.translation.width)
                                    self.value = Float(((nextCoordinateValue - minValue) / scaleFactor) + lower)
                                }
                            }
                    )
                    Spacer()
                }
            }
        }
    }
}
