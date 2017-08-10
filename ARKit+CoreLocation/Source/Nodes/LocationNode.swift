//
//  SceneAnnotation.swift
//  ARKit+CoreLocation
//
//  Created by Andrew Hart on 02/07/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import Foundation
import SceneKit
import CoreLocation

///A location node can be added to a scene using a coordinate.
///Its scale and position should not be adjusted, as these are used for scene layout purposes
///To adjust the scale and position of items within a node, you can add them to a child node and adjust them there
open class LocationNode: SCNNode {
    var locationEstimateMethod: LocationEstimateMethod = .mostRelevantEstimate

    ///Location can be changed and confirmed later by SceneLocationView.
    public var location: CLLocation?

    ///Whether the location of the node has been confirmed.
    ///This is automatically set to true when you create a node using a location.
    ///Otherwise, this is false, and becomes true once the user moves 100m away from the node,
    ///except when the locationEstimateMethod is set to use Core Location data only,
    ///as then it becomes true immediately.
    public var locationConfirmed = false

    ///Whether a node's position should be adjusted on an ongoing basis
    ///based on its' given location.
    ///This only occurs when a node's location is within 100m of the user.
    ///Adjustment doesn't apply to nodes without a confirmed location.
    ///When this is set to false, the result is a smoother appearance.
    ///When this is set to true, this means a node may appear to jump around
    ///as the user's location estimates update,
    ///but the position is generally more accurate.
    ///Defaults to true.
    public var continuallyAdjustNodePositionWhenWithinRange = true

    ///Whether a node's position and scale should be updated automatically on a continual basis.
    ///This should only be set to false if you plan to manually update position and scale
    ///at regular intervals. You can do this with `SceneLocationView`'s `updatePositionOfLocationNode`.
    public var continuallyUpdatePositionAndScale = true

    public init(location: CLLocation?) {
        self.location = location
        self.locationConfirmed = location != nil
        super.init()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    internal func location(_ bestLocationEstimate: SceneLocationEstimate?) -> CLLocation {
        if locationConfirmed || locationEstimateMethod == .coreLocationDataOnly {
            return location!
        }

        if let bestLocationEstimate = bestLocationEstimate,
            location == nil || bestLocationEstimate.location.horizontalAccuracy < location!.horizontalAccuracy {
            return bestLocationEstimate.translatedLocation(to: position)
        } else {
            return location!
        }
    }

    internal func adjustedDistance(setup: Bool, position: SCNVector3,
                                   locationManager: SceneLocationManager) -> CLLocationDistance {
        guard let location = locationManager.currentLocation else { return 0.0 }

        //Position is set to a position coordinated via the current position
        let distance = self.location(locationManager.bestLocationEstimate).distance(from: location)

        let adjustedDistance: CLLocationDistance
        if locationConfirmed && (distance > 100 || continuallyAdjustNodePositionWhenWithinRange || setup) {
            let locationTranslation = location.translation(toLocation: self.location(locationManager.bestLocationEstimate))

            if distance > 100 {
                //If the item is too far away, bring it closer and scale it down
                let scale = 100 / Float(distance)

                adjustedDistance = distance * Double(scale)

                let adjustedTranslation = SCNVector3( x: Float(locationTranslation.longitudeTranslation) * scale,
                                                      y: Float(locationTranslation.altitudeTranslation) * scale,
                                                      z: Float(locationTranslation.latitudeTranslation) * scale)
                self.position = SCNVector3( x: position.x + adjustedTranslation.x,
                                            y: position.y + adjustedTranslation.y,
                                            z: position.z - adjustedTranslation.z)
                self.scale = SCNVector3(x: scale, y: scale, z: scale)
            } else {
                adjustedDistance = distance
                self.position = SCNVector3( x: position.x + Float(locationTranslation.longitudeTranslation),
                                            y: position.y + Float(locationTranslation.altitudeTranslation),
                                            z: position.z - Float(locationTranslation.latitudeTranslation))
                self.scale = SCNVector3(x: 1, y: 1, z: 1)
            }
        } else {
            //Calculates distance based on the distance within the scene, as the location isn't yet confirmed
            adjustedDistance = Double(position.distance(to: position))

            scale = SCNVector3(x: 1, y: 1, z: 1)
        }

        return adjustedDistance
    }

    func updatePositionAndScale(setup: Bool = false, scenePosition: SCNVector3?,
                                locationManager: SceneLocationManager, onCompletion: (() -> Void)) {
        guard let position = scenePosition, locationManager.currentLocation != nil else { return }

        SCNTransaction.begin()
        SCNTransaction.animationDuration = setup ? 0.0 : 0.1

        _ = self.adjustedDistance(setup: setup, position: position, locationManager: locationManager)

        SCNTransaction.commit()

        onCompletion()
    }
}
