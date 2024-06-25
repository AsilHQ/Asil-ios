//
//  NsfwDetector.swift
//
//
//  Created by Cem Sertkaya on 24.06.2024.
//

import UIKit
import TensorFlowLite

class NsfwDetector {
    private let inputImageSize = 224
    private var interpreter: Interpreter

    init?(modelPath: String) {
        do {
            interpreter = try Interpreter(modelPath: modelPath)
            try interpreter.allocateTensors()
        } catch {
            print("Failed to create interpreter with error: \(error.localizedDescription)")
            return nil
        }
    }

    func isNsfw(bitmap: UIImage) -> NsfwPrediction? {
        guard let resizedImage = resizeImage(image: bitmap, targetSize: CGSize(width: inputImageSize, height: inputImageSize)),
              let buffer = imageToRGBData(resizedImage) else {
            return nil
        }

        do {
            try interpreter.copy(buffer, toInputAt: 0)
            try interpreter.invoke()
            let outputTensor = try interpreter.output(at: 0)
            let prediction = NsfwPrediction(probabilities: outputTensor.data.toArray(type: Float32.self))
            return prediction
        } catch {
            print("Failed to invoke interpreter with error: \(error.localizedDescription)")
            return nil
        }
    }

    func dispose() {
        // TensorFlow Lite interpreter does not need explicit disposal in Swift.
    }

    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: targetSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }

    private func imageToRGBData(_ image: UIImage) -> Data? {
        guard let cgImage = image.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        let byteCount = width * height * 3
        var rgbData = Data(count: byteCount)

        rgbData.withUnsafeMutableBytes { (bytes: UnsafeMutableRawBufferPointer) in
            guard let context = CGContext(data: bytes.baseAddress,
                                          width: width,
                                          height: height,
                                          bitsPerComponent: 8,
                                          bytesPerRow: width * 3,
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { return }
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }

        return rgbData
    }
}

struct NsfwPrediction {
    let probabilities: [Float]
}

extension Data {
    func toArray<T>(type: T.Type) -> [T] {
        return withUnsafeBytes {
            Array(UnsafeBufferPointer<T>(start: $0.bindMemory(to: T.self).baseAddress!, count: count / MemoryLayout<T>.stride))
        }
    }
}
