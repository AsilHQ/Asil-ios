//
//  NsfwDetector.swift
//
//
//  Created by Cem Sertkaya on 24.06.2024.
//

import UIKit

class NsfwDetector: TensorflowDetector {
    
    private var interpreter: Interpreter?
    let batchSize = 1
    let inputChannels = 3
    let inputWidth = 224
    let inputHeight = 224
    private let inputImageSize = CGSize(width: 224, height: 224)
    
    override init() {
        do {
            interpreter = try Interpreter(modelPath: Bundle.module.path(forResource: "nsfw", ofType: "tflite") ?? "")
            try interpreter?.allocateTensors()
            print("NsfwDetector model has been loaded")
        } catch {
            print("NsfwDetector Failed to create interpreter with error: \(error.localizedDescription)")
        }
        super.init()
    }

    func isNsfw(image: UIImage) -> NsfwPrediction? {
        guard let thumbnailPixelBuffer = CVPixelBuffer.buffer(from: image)?.centerThumbnail(ofSize: inputImageSize) else {
            return nil
        }
        
        do {
            let inputTensor = try interpreter?.input(at: 0)

            guard let rgbData = rgbDataFromBuffer(
                thumbnailPixelBuffer,
                byteCount: batchSize * inputWidth * inputHeight * inputChannels,
                isModelQuantized: inputTensor?.dataType == .float16
            ) else {
                print("Failed to convert the image buffer to RGB data.")
                return nil
            }

            try interpreter?.copy(rgbData, toInputAt: 0)

            try interpreter?.invoke()
            
            let outputTensor = try interpreter?.output(at: 0)
            let prediction = NsfwPrediction(predictions: outputTensor?.data.toArray(type: Float32.self) ?? [])
            return prediction
        } catch {
            print("GenderDetector Failed to invoke interpreter with error: \(error.localizedDescription)")
            return nil
        }
    }
}
