//
//  ScalingScheme.swift
//  ARCL
//
//  Created by Eric Internicola on 5/17/19.
//

import Foundation

/// A set of schemes that can be used to scale a LocationNode.
///
/// - normal: The default way of scaling
/// - tiered: A way of scaling everything beyond a specific distance (threshold) at
/// a specific scale.
/// - doubleTiered: A way of scaling everything beyond 2 specific distances at two
/// specific scales.
/// - linear: linearly scales an object based on its distance.
/// - linearBuffer: linearly scales an object based on its distance as long as it is
/// further than the buffer distance, otherwise it just returns 100% scale.
public enum ScalingScheme {

    case normal
    case tiered(threshold: Double, scale: Float)
    case doubleTiered(firstThreshold: Double, firstScale: Float, secondThreshold: Double, secondScale: Float)
    case linear(threshold: Double)
    case linearBuffer(threshold: Double, buffer: Double)

    public func getScheme() -> ( (_ distance: Double, _ adjustedDistance: Double) -> Float) {
        switch self {
        case .tiered(let threshold, let scale):
            return { (distance, adjustedDistance) in
                if adjustedDistance > threshold {
                    return scale
                } else {
                    return 1.0
                }
            }
        case .doubleTiered(let firstThreshold, let firstScale, let secondThreshold, let secondScale):
            return { (distance, adjustedDistance) in
                if adjustedDistance > secondThreshold {
                    return secondScale
                } else if adjustedDistance > firstThreshold {
                    return firstScale
                } else {
                    return 1.0
                }
            }
        case .linear(let threshold):
            return { (distance, adjustedDistance) in

                let maxSize = 1.0
                let absThreshold = abs(threshold)
                let absAdjDist = abs(adjustedDistance)

                let scaleToReturn =  Float( max (maxSize - (absAdjDist / absThreshold), 0.0))
//                print("threshold: \(absThreshold) adjDist: \(absAdjDist) scaleToReturn: \(scaleToReturn)")
                return scaleToReturn
            }

        case .linearBuffer(let threshold, let buffer):
            return { (distance, adjustedDistance) in
                let maxSize = 1.0
                let absThreshold = abs(threshold)
                let absAdjDist = abs(adjustedDistance)

                if absAdjDist < buffer {
//                    print("threshold: \(absThreshold) adjDist: \(absAdjDist)")
                    return Float(maxSize)
                } else {
                    let scaleToReturn =  Float( max( maxSize - (absAdjDist / absThreshold), 0.0 ))
//                    print("threshold: \(absThreshold) adjDist: \(absAdjDist) scaleToReturn: \(scaleToReturn)")
                    return scaleToReturn
                }
            }
        case .normal:
            return { (distance, adjustedDistance) in

                // Scale it to be an appropriate size so that it can be seen
                var scale = Float(adjustedDistance) * 0.181
                if distance > 3000 {
                    scale *= 0.75
                }
                return scale
            }
        }

    }

}
