//
//  SwiftUIView.swift
//  
//
//  Created by Cem Sertkaya on 24.01.2024.
//

import SwiftUI

struct SliderView: View {
    @Binding var value: Double
    @State var lastCoordinateValue: CGFloat = 0.0
    var sliderRange: ClosedRange<Double> = 1...100
    var thumbColor: Color = .yellow
    var minTrackColor: Color = Color(red: 0.06, green: 0.7, blue: 0.79)
    var maxTrackColor: Color = Color(red: 0.9, green: 0.9, blue: 0.9)
    
    var body: some View {
        GeometryReader { gr in
            let thumbWidth = gr.size.width * 0.03
            let radius = gr.size.height * 0.5
            let minValue = gr.size.width * 0.015
            let maxValue = (gr.size.width * 0.98) - thumbWidth
            
            let scaleFactor = (maxValue - minValue) / (sliderRange.upperBound - sliderRange.lowerBound)
            let lower = sliderRange.lowerBound
            let sliderVal = (self.value - lower) * scaleFactor + minValue
            
            ZStack {
                Color.clear
                
                Rectangle()
                    .foregroundColor(maxTrackColor)
                    .frame(width: gr.size.width, height: 5)
                    .clipShape(RoundedRectangle(cornerRadius: radius))
                HStack {
                    Rectangle()
                        .foregroundColor(minTrackColor)
                        .frame(width: sliderVal, height: 5)
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
                                if (abs(v.translation.width) < 0.1) {
                                    self.lastCoordinateValue = sliderVal
                                }
                                if v.translation.width > 0 {
                                    let nextCoordinateValue = min(maxValue, self.lastCoordinateValue + v.translation.width)
                                    self.value = ((nextCoordinateValue - minValue) / scaleFactor)  + lower
                                } else {
                                    let nextCoordinateValue = max(minValue, self.lastCoordinateValue + v.translation.width)
                                    self.value = ((nextCoordinateValue - minValue) / scaleFactor) + lower
                                }
                            }
                    )
                    Spacer()
                }
            }
        }
    }
}
