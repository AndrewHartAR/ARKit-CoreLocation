////
////  SceneAnnotation.swift
////  ARKit+CoreLocation
////
////  Created by Andrew Hart on 02/07/2017.
////  Copyright © 2017 Project Dent. All rights reserved.
////

import Foundation
import SceneKit
import CoreLocation

/// Child node of a `LocationAnnotationNode`. You will not need to create this yourself.
/// This node type enables the client to have access to the view or image that
/// was used to initialize the `LocationAnnotationNode`.
open class AnnotationNode: SCNNode {
    public var view: UIView?
    public var image: UIImage?
    public var layer: CALayer?

    public init(view: UIView?, image: UIImage?, layer: CALayer? = nil) {
        super.init()
        self.view = view
        self.image = image
        self.layer = layer
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// A location node can be added to a scene using a coordinate.
///
/// Its scale and position should not be adjusted, as these are used for scene
/// layout purposes.  To adjust the scale and position of items within a node,
/// you can add them to a child node and adjust them there
open class LocationNode: SCNNode {
    // FIXME: figure out why this is hardcoded and why it would ever be different from the scene's sitting?
    /// This seems like it should be a bug? Why is it hardcoded? Why would it ever be different from the scene's setting?
    var locationEstimateMethod: LocationEstimateMethod = .mostRelevantEstimate

    /// Location can be changed and confirmed later by SceneLocationView.
    public var location: CLLocation!

    /// A general purpose tag that can be used to find nodes already added to a SceneLocationView
    public var tag: String?

    /// Whether the location of the node has been confirmed.
    /// This is automatically set to true when you create a node using a location.
    /// Otherwise, this is false, and becomes true once the user moves 100m away from the node,
    /// except when the locationEstimateMethod is set to use Core Location data only,
    /// as then it becomes true immediately.
    public var locationConfirmed: Bool {
        return location != nil
    }

    /// Whether a node's position should be adjusted on an ongoing basis
    /// based on its given location.
    /// This only occurs when a node's location is within 100m of the user.
    /// Adjustment doesn't apply to nodes without a confirmed location.
    /// When this is set to false, the result is a smoother appearance.
    /// When this is set to true, this means a node may appear to jump around
    /// as the user's location estimates update,
    /// but the position is generally more accurate.
    /// Defaults to true.
    public var continuallyAdjustNodePositionWhenWithinRange = true

    /// Whether a node's position and scale should be updated automatically on a continual basis.
    /// This should only be set to false if you plan to manually update position and scale
    /// at regular intervals. You can do this with `SceneLocationView`'s `updatePositionOfLocationNode`.
    public var continuallyUpdatePositionAndScale = true

    /// Whether the node should be scaled relative to its distance from the camera
    /// Default value (false) scales it to visually appear at the same size no matter the distance
    /// Setting to true causes annotation nodes to scale like a regular node
    /// Scaling relative to distance may be useful with local navigation-based uses
    /// For landmarks in the distance, the default is correct
    public var scaleRelativeToDistance = false

    /// Whether the node should appear at the same altitude of the user
    /// May be useful when you don't know the real altitude of the node
    /// When set to true, the node will stay at the same altitude of the user
    public var ignoreAltitude = false

    /// The scheme to use for scaling
    public var scalingScheme: ScalingScheme = .normal

    /// Whether the node should be stacked along the y-axis accordingly with the distance.
    /// When set to `true`, `scaleRelativeToDistance` should be `false`.
    /// TODO: figure out whether this is "should" or "must", and clarify the comment.  If "should",
    /// then add an explanation of what happens when `scaleRelativeToDistance` is true. If "must",
    /// then enforce that with a property `didSet` observer. What happens when `scalingScheme`
    /// is not `ScalingScheme.normal`?
    public var shouldStackAnnotation = false

    public init(location: CLLocation?, tag: String? = nil) {
        self.location = location
        self.tag = tag
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

    internal func adjustedDistance(setup: Bool, position: SCNVector3, locationNodeLocation: CLLocation,
                                   locationManager: SceneLocationManager) -> CLLocationDistance {
        guard let location = locationManager.currentLocation else {
            return 0.0
        }

        // Position is set to a position coordinated via the current position
        let distance = self.location(locationManager.bestLocationEstimate).distance(from: location)

        var locationTranslation = location.translation(toLocation: locationNodeLocation)
        locationTranslation.altitudeTranslation = ignoreAltitude ? 0 : locationTranslation.altitudeTranslation

        let adjustedDistance: CLLocationDistance
        // FIXME: Magic Number
        if locationConfirmed && (distance > 100
            || continuallyAdjustNodePositionWhenWithinRange
            || setup
            || shouldStackAnnotation) {
            if distance > 100 || shouldStackAnnotation {
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
            //TODO: This yields zero, perhaps we should investigate
            adjustedDistance = Double(position.distance(to: position))

            scale = SCNVector3(x: 1, y: 1, z: 1)
        }

        return adjustedDistance
    }

    /// See `LocationAnnotationNode`'s override of this function. Because it doesn't invoke `super`'s version, any changes
    /// made in this file must be repeated in `LocationAnnotationNode`.
    func updatePositionAndScale(setup: Bool = false, scenePosition: SCNVector3?, locationNodeLocation nodeLocation: CLLocation,
                                locationManager: SceneLocationManager, onCompletion: (() -> Void)) {
        guard let position = scenePosition, locationManager.currentLocation != nil else {
            return
        }

        SCNTransaction.begin()
        SCNTransaction.animationDuration = setup ? 0.0 : 0.1

        let distance = self.location(locationManager.bestLocationEstimate).distance(from:
            locationManager.currentLocation ?? nodeLocation)

        childNodes.first?.renderingOrder = renderingOrder(fromDistance: distance)

        _ = self.adjustedDistance(setup: setup, position: position,
                                  locationNodeLocation: nodeLocation,
                                  locationManager: locationManager)

        SCNTransaction.commit()

        onCompletion()
    }

    /// Converts distance from meters to SCNKit rendering order
    /// Constant multiplier eliminates flicker caused by slight distance variations
    /// Nodes with greater rendering orders are rendered last
    func renderingOrder(fromDistance distance: CLLocationDistance) -> Int {
        return Int.max - 1000 - (Int(distance * 1000))
    }

    @available(iOS 11.0, *)
    /// TODO: write a real docstring. Consider renaming.
    func stackNode(scenePosition: SCNVector3?, locationNodes: [LocationNode], stackingOffset: Float) {

        // Detecting collision
        // FIXME: force unwrap.
        let node1 = self.childNodes.first!
        var hasCollision = false
        // FIXME: better variable name
        var i = 0
        while i < locationNodes.count {
            let locationNode2 = locationNodes[i]

            if locationNode2 == self {
                // If collision, start over because movement could cause additional collisions
                if hasCollision {
                    hasCollision = false
                    i = 0
                    continue
                }
                break
            }

            // FIXME: force unwrap
            let node2 = locationNode2.childNodes.first!

            // FIXME: there's a SIMD function for this.
            // If the angle between two nodes and the user is less than a threshold and the vertical distance
            // between the node centers is less than deltaY trheshold a collision occured and move the node up
            let angle = angleBetweenTwoPointsAndUser(scenePosition: scenePosition,
                                                     pointA: node1.worldPosition,
                                                     pointB: node2.worldPosition)
            // FIXME: parameterize this 2.5 factor and figure out what 100 means.
            let angleMin = CGFloat(2.5 * atan(node1.scale.x / 100)) // You can change 2.5 to your requirements

            let deltaY = abs(node1.worldPosition.y - node2.worldPosition.y)
            let deltaYMin = 2 * node1.boundingBox.max.y * node1.scale.y

            // We have a collision, move the node 1 up
            // TODO: means "move it up by one stacking offset"?
            if deltaY < deltaYMin && angle < angleMin {
                node1.position.y += deltaYMin + stackingOffset
                hasCollision = true
            }
            i += 1
        }
    }

    // FIXME: use SIMD and provide a unit test.
    private func angleBetweenTwoPointsAndUser(scenePosition: SCNVector3?, pointA: SCNVector3, pointB: SCNVector3) -> CGFloat {
        if let userPosition = scenePosition {
            let A = CGPoint(x: CGFloat(pointA.x), y: CGFloat(pointA.z))
            let B = CGPoint(x: CGFloat(pointB.x), y: CGFloat(pointB.z))
            let U = CGPoint(x: CGFloat(userPosition.x), y: CGFloat(userPosition.z))

            let a = A.distance(to: U)
            let b = B.distance(to: U)
            let c = A.distance(to: B)
            return acos((a*a + b*b - c*c) / (2 * a*b))
        } else {
            return 0.0
        }
    }
}
