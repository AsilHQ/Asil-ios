//
//  GenderDetector.swift
//
//
//  Created by Cem Sertkaya on 2.07.2024.
//

import UIKit
import Vision
import TensorFlowLiteSwift

class GenderPrediction {
    var faceCount: Int = 0
    var hasMale: Bool = false
    var hasFemale: Bool = false
    var maleConfidence: Float = 0.0
    var femaleConfidence: Float = 0.0
}

class GenderDetector: TensorflowDetector {
    private let inputImageSize = CGSize(width: 224, height: 224)
    private var interpreter: Interpreter?
    private var SAFE_GAZE_DEFAULT_BLUR_VALUE = 30
    private var SAFE_GAZE_MIN_FACE_SIZE = 15
    private var SAFE_GAZE_MIN_FEMALE_CONFIDENCE: Float = 0.7
    
    let batchSize = 1
    let inputChannels = 3
    let inputWidth = 224
    let inputHeight = 224
    
    override init() {
        do {
            interpreter = try Interpreter(modelPath: Bundle.module.path(forResource: "best_gender_float16", ofType: "tflite") ?? "")
            try interpreter?.allocateTensors()
            print("GenderDetector model has been loaded")
        } catch {
            print("GenderDetector failed to create interpreter with error: \(error.localizedDescription)")
        }
        super.init()
    }
    
    func predict(image: UIImage, data: Data, completion: @escaping (GenderPrediction) -> Void) {
        let requestHandler = VNImageRequestHandler(data: data, options: [:])
        
        let faceDetectionRequest = VNDetectFaceRectanglesRequest { [self] (request, error) in
            guard let observations = request.results as? [VNFaceObservation] else {
                DispatchQueue.main.async {
                    completion(GenderPrediction())
                }
                return
            }
            
            let prediction = GenderPrediction()
            prediction.faceCount = observations.count
            
            for faceObservation in observations {
                guard let faceImage = self.cropToBBox(image: image, boundingBox: faceObservation.boundingBox) else { continue }
                
                let genderPredictions = self.getGenderPrediction(image: faceImage)
                
                let isMale = genderPredictions.0 < genderPredictions.1
                prediction.hasMale = prediction.hasMale || isMale
                prediction.femaleConfidence = genderPredictions.0
                prediction.maleConfidence = genderPredictions.1
                
                if prediction.femaleConfidence >= self.SAFE_GAZE_MIN_FEMALE_CONFIDENCE {
                    prediction.hasFemale = true
                    break
                }
            }
            
            DispatchQueue.main.async {
                completion(prediction)
            }
        }
        
        #if targetEnvironment(simulator)
                faceDetectionRequest.usesCPUOnly = true
        #endif
        
        do {
            try requestHandler.perform([faceDetectionRequest])
        } catch {
            print("GenderDetector Error in face detection: \(error)")
            DispatchQueue.main.async {
                completion(GenderPrediction())
            }
        }
    }
    
    private func getGenderPrediction(image: UIImage) -> (Float, Float, Bool) {
        
        guard let thumbnailPixelBuffer = CVPixelBuffer.buffer(from: image)?.centerThumbnail(ofSize: inputImageSize) else {
            return (0, 0, false)
        }
        
        do {
            let inputTensor = try interpreter?.input(at: 0)

            guard let rgbData = rgbDataFromBuffer(
                thumbnailPixelBuffer,
                byteCount: batchSize * inputWidth * inputHeight * inputChannels,
                isModelQuantized: inputTensor?.dataType == .float16
            ) else {
                print("Failed to convert the image buffer to RGB data.")
                return (0, 0, false)
            }

            try interpreter?.copy(rgbData, toInputAt: 0)

            try interpreter?.invoke()
            
            let outputTensor = try interpreter?.output(at: 0)
            let predictionArray = outputTensor?.data.toArray(type: Float32.self) ?? []
            
            return (predictionArray[0], predictionArray[1], false)
        } catch {
            print("GenderDetector Failed to invoke interpreter with error: \(error.localizedDescription)")
            return (0, 0, false)
        }
    }
    
    private func cropToBBox(image: UIImage, boundingBox: CGRect) -> UIImage? {
        let size = CGSize(width: boundingBox.width * image.size.width, height: boundingBox.height * image.size.height)
        let origin = CGPoint(x: boundingBox.origin.x * image.size.width, y: (1 - boundingBox.origin.y - boundingBox.height) * image.size.height)
        let cropRect = CGRect(origin: origin, size: size).integral
        
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}
