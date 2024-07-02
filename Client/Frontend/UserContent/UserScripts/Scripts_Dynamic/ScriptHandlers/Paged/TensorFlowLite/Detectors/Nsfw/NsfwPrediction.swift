//
//  NsfwDetector.swift
//
//
//  Created by Cem Sertkaya on 24.06.2024.
//

import Foundation

struct NsfwPrediction: Equatable, Hashable {
    static let labels = ["drawing", "hentai", "neutral", "porn", "sexy"]
    
    let predictions: [Float]
    
    func drawing() -> Float {
        return predictions[0]
    }
    
    func hentai() -> Float {
        return predictions[1]
    }
    
    func neutral() -> Float {
        return predictions[2]
    }
    
    func porn() -> Float {
        return predictions[3]
    }
    
    func sexy() -> Float {
        return predictions[4]
    }
    
    func getLabelWithConfidence() -> (label: String, confidence: Float) {
        guard let maxIndex = predictions.indices.max(by: { predictions[$0] < predictions[$1] }) else {
            return ("Unknown", 0.0)
        }
        
        let label = (maxIndex < NsfwPrediction.labels.count) ? NsfwPrediction.labels[maxIndex] : "Unknown"
        return (label, predictions[maxIndex])
    }
    
    func safeScore() -> Float {
        return drawing() + neutral()
    }
    
    func unsafeScore() -> Float {
        return hentai() + porn() + sexy()
    }
    
    func isSafe() -> Bool {
        guard let maxIndex = predictions.indices.max(by: { predictions[$0] < predictions[$1] }) else {
            return false
        }
        return maxIndex == 0 || maxIndex == 2
    }
    
    static func == (lhs: NsfwPrediction, rhs: NsfwPrediction) -> Bool {
        return lhs.predictions == rhs.predictions
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(predictions)
    }
}
