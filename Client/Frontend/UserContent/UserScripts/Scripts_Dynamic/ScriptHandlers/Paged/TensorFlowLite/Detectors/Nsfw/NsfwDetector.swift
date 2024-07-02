//
//  NsfwDetector.swift
//
//
//  Created by Cem Sertkaya on 24.06.2024.
//

import UIKit

class NsfwDetector: TensorflowDetector {
    private let inputImageSize = 224
    private var interpreter: Interpreter?

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

    func isNsfw(bitmap: UIImage) -> NsfwPrediction? {
        guard let resizedImage = resizeImage(image: bitmap, targetSize: CGSize(width: inputImageSize, height: inputImageSize)),
              let buffer = imageToRGBData(resizedImage) else {
            return nil
        }

        do {
            let normalizedBuffer = normalize(buffer: buffer)

            try interpreter?.copy(normalizedBuffer, toInputAt: 0)

            try interpreter?.invoke()

            let outputTensor = try interpreter?.output(at: 0)
            let prediction = NsfwPrediction(predictions: outputTensor?.data.toArray(type: Float32.self) ?? [])
            return prediction
        } catch {
            print("NsfwDetector Failed to invoke interpreter with error: \(error.localizedDescription)")
            return nil
        }
    }
}
