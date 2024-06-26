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

    init?() {
        do {
            interpreter = try Interpreter(modelPath: Bundle.module.path(forResource: "nsfw", ofType: "tflite") ?? "")
            try interpreter.allocateTensors()
            print("NsfwDetector model has been loaded")
        } catch {
            print("NsfwDetector Failed to create interpreter with error: \(error.localizedDescription)")
            return nil
        }
    }

    func isNsfw(bitmap: UIImage) -> NsfwPrediction? {
        guard let resizedImage = resizeImage(image: bitmap, targetSize: CGSize(width: inputImageSize, height: inputImageSize)),
              let buffer = imageToRGBData(resizedImage) else {
            return nil
        }

        do {
            let normalizedBuffer = normalize(buffer: buffer)

            try interpreter.copy(normalizedBuffer, toInputAt: 0)

            try interpreter.invoke()

            let outputTensor = try interpreter.output(at: 0)
            let prediction = NsfwPrediction(predictions: outputTensor.data.toArray(type: Float32.self))
            return prediction
        } catch {
            print("NsfwDetector Failed to invoke interpreter with error: \(error.localizedDescription)")
            return nil
        }
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
        let bytesPerRow = width * 3
        let byteCount = bytesPerRow * height
        
        var rgbData = Data(count: byteCount)
        rgbData.withUnsafeMutableBytes { (bytes: UnsafeMutableRawBufferPointer) in
            let context = CGContext(
                data: bytes.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
            )
            context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        return rgbData
    }
    
    private func normalize(buffer: Data) -> Data {
        let normalizedBuffer = buffer.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) -> [Float] in
            let buffer = ptr.bindMemory(to: UInt8.self)
            return buffer.map { Float($0) / 255.0 }
        }
        return Data(bytes: normalizedBuffer, count: normalizedBuffer.count * MemoryLayout<Float>.stride)
    }
}


extension Data {
    func toArray<T>(type: T.Type) -> [T] {
        return withUnsafeBytes {
            Array(UnsafeBufferPointer<T>(start: $0.bindMemory(to: T.self).baseAddress!, count: count / MemoryLayout<T>.stride))
        }
    }
}
