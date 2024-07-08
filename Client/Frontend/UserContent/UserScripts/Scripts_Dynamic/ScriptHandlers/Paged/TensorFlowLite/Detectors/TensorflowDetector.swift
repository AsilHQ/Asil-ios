//
//  TensorflowDetector.swift
//
//
//  Created by Cem Sertkaya on 2.07.2024.
//

import Foundation
import UIKit

class TensorflowDetector {
    func imageToRGBData(_ image: UIImage) -> Data? {
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
    
    func normalize(buffer: Data) -> Data {
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
