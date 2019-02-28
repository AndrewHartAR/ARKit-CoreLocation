//
//  SceneLocationManager.swift
//  ARKit+CoreLocation
//
//  Created by Ilya Seliverstov on 10/08/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import Foundation
import ARKit
import CoreLocation
import MapKit

///Different methods which can be used when determining locations (such as the user's location).
public enum LocationEstimateMethod {
    ///Only uses core location data.
    ///Not suitable for adding nodes using current position, which requires more precision.
    case coreLocationDataOnly

    ///Combines knowledge about movement through the AR world with
    ///the most relevant Core Location estimate (based on accuracy and time).
    case mostRelevantEstimate
}

protocol SceneLocationManagerDelegate: class {
    var scenePosition: SCNVector3? { get }

    func confirmLocationOfDistantLocationNodes()
    func updatePositionAndScaleOfLocationNodes()

    func didAddSceneLocationEstimate(position: SCNVector3, location: CLLocation)
    func didRemoveSceneLocationEstimate(position: SCNVector3, location: CLLocation)
}

public final class SceneLocationManager {
    weak var sceneLocationDelegate: SceneLocationManagerDelegate?

    public var locationEstimateMethod: LocationEstimateMethod = .mostRelevantEstimate
    public let locationManager = LocationManager()

    var sceneLocationEstimates = [SceneLocationEstimate]()

    var updateEstimatesTimer: Timer?

    /// The best estimation of location that has been taken
    /// This takes into account horizontal accuracy, and the time at which the estimation was taken
    /// favouring the most accurate, and then the most recent result.
    /// This doesn't indicate where the user currently is.
    public var bestLocationEstimate: SceneLocationEstimate? {
        let sortedLocationEstimates = sceneLocationEstimates.sorted(by: {
            if $0.location.horizontalAccuracy == $1.location.horizontalAccuracy {
                return $0.location.timestamp > $1.location.timestamp
            }

            return $0.location.horizontalAccuracy < $1.location.horizontalAccuracy
        })

        return sortedLocationEstimates.first
    }

    public var currentLocation: CLLocation? {
        if locationEstimateMethod == .coreLocationDataOnly { return locationManager.currentLocation }

        guard let bestEstimate = bestLocationEstimate,
            let position = sceneLocationDelegate?.scenePosition else { return nil }

        return bestEstimate.translatedLocation(to: position)
    }

    init() {
        locationManager.delegate = self
    }

    deinit {
        pause()
    }

    @objc
    func updateLocationData() {
        removeOldLocationEstimates()

        sceneLocationDelegate?.confirmLocationOfDistantLocationNodes()
        sceneLocationDelegate?.updatePositionAndScaleOfLocationNodes()
    }

    ///Adds a scene location estimate based on current time, camera position and location from location manager
    func addSceneLocationEstimate(location: CLLocation) {
        guard let position = sceneLocationDelegate?.scenePosition else { return }

        sceneLocationEstimates.append(SceneLocationEstimate(location: location, position: position))

        sceneLocationDelegate?.didAddSceneLocationEstimate(position: position, location: location)
    }

    func removeOldLocationEstimates() {
        guard let currentScenePosition = sceneLocationDelegate?.scenePosition else { return }
        removeOldLocationEstimates(currentScenePosition: currentScenePosition)
    }

    func removeOldLocationEstimates(currentScenePosition: SCNVector3) {
        let currentPoint = CGPoint.pointWithVector(vector: currentScenePosition)

        sceneLocationEstimates = sceneLocationEstimates.filter {
            if #available(iOS 11.0, *) {
                let radiusContainsPoint = currentPoint.radiusContainsPoint(
                    radius: CGFloat(SceneLocationView.sceneLimit),
                    point: CGPoint.pointWithVector(vector: $0.position))

                if !radiusContainsPoint {
                    sceneLocationDelegate?.didRemoveSceneLocationEstimate(position: $0.position, location: $0.location)
                }

                return radiusContainsPoint
            } else {
                return false
            }
        }
    }

}

extension SceneLocationManager {
    func run() {
        pause()
        updateEstimatesTimer = Timer.scheduledTimer(
                timeInterval: 0.1,
                target: self,
                selector: #selector(SceneLocationManager.updateLocationData),
                userInfo: nil,
                repeats: true)
    }

    func pause() {
        updateEstimatesTimer?.invalidate()
        updateEstimatesTimer = nil
    }
}

extension SceneLocationManager: LocationManagerDelegate {

    func locationManagerDidUpdateLocation(_ locationManager: LocationManager,
                                          location: CLLocation) {
        addSceneLocationEstimate(location: location)
    }
}
