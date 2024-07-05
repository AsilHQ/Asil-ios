//
//  TensorflowDetector.swift
//
//
//  Created by Cem Sertkaya on 2.07.2024.
//

import Foundation
import UIKit

class TensorflowDetector {
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: targetSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
    
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
    
    func pixelValuesFromImage(imageRef: CGImage?) -> [UInt8]? {
        var width = 0
        var height = 0
        var pixelValues: [UInt8]?
        if let imageRef = imageRef {
            width = imageRef.width
            height = imageRef.height
            let bitsPerComponent = imageRef.bitsPerComponent
            let bytesPerRow = imageRef.bytesPerRow
            let totalBytes = height * bytesPerRow
            
            let colorSpace = CGColorSpaceCreateDeviceGray()
            pixelValues = [UInt8](repeating: 0, count: totalBytes)
            
            let contextRef = CGContext(data: &pixelValues!, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: 0)
            contextRef?.draw(imageRef, in: CGRect(origin: CGPoint.zero, size: CGSize(width: width, height: height)))
        }
        
        return pixelValues
    }
    
    func normalizedFloatArray(from array: [UInt8]) -> [Float] {
        var resultArray = [Float]()
        
        array.forEach {resultArray.append(Float($0)/255.0) }
        resultArray = resultArray.map { Float(1 - $0) }
        
        return resultArray
        
    }
}

extension Data {
    func toArray<T>(type: T.Type) -> [T] {
        return withUnsafeBytes {
            Array(UnsafeBufferPointer<T>(start: $0.bindMemory(to: T.self).baseAddress!, count: count / MemoryLayout<T>.stride))
        }
    }
}

extension UIImage {
    // Convert UIImage to Data normalized to [0, 1] range
    func normalizedData() -> Data? {
        guard let cgImage = cgImage else { return nil }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let totalBytes = bytesPerRow * height
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Little.rawValue
        bitmapInfo |= CGImageAlphaInfo.premultipliedFirst.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
        
        guard let context = CGContext(data: nil,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo) else {
            return nil
        }
        
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        context.draw(cgImage, in: rect)
        
        guard let pixelBuffer = context.data else {
            return nil
        }
        
        return Data(bytes: pixelBuffer, count: totalBytes)
    }
}
