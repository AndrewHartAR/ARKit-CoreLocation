//
//  SceneLocationView.swift
//  ARKit+CoreLocation
//
//  Created by Andrew Hart on 02/07/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import Foundation
import ARKit
import CoreLocation
import MapKit

//Should conform to delegate here, add in future commit
public class SceneLocationView: ARSCNView {
    ///The limit to the scene, in terms of what data is considered reasonably accurate.
    ///Measured in meters.
    static let sceneLimit = 100.0

    public weak var locationViewDelegate: SceneLocationViewDelegate?
    public weak var locationEstimateDelegate: SceneLocationViewEstimateDelegate?

    ///The method to use for determining locations.
    ///Not advisable to change this as the scene is ongoing.
    public var locationEstimateMethod: LocationEstimateMethod {
        get {
            return sceneLocationManager.locationEstimateMethod
        }
        set {
            sceneLocationManager.locationEstimateMethod = newValue

            locationNodes.forEach { $0.locationEstimateMethod = newValue }
        }
    }

    ///When set to true, displays an axes node at the start of the scene
    public var showAxesNode = false

    public internal(set) var sceneNode: SCNNode? {
        didSet {
            guard sceneNode != nil else { return }

            locationNodes.forEach { sceneNode?.addChildNode($0) }

            locationViewDelegate?.didSetupSceneNode(sceneLocationView: self, sceneNode: sceneNode!)
        }
    }

    ///Only to be overrided if you plan on manually setting True North.
    ///When true, sets up the scene to face what the device considers to be True North.
    ///This can be inaccurate, hence the option to override it.
    ///The functions for altering True North can be used irrespective of this value,
    ///but if the scene is oriented to true north, it will update without warning,
    ///thus affecting your alterations.
    ///The initial value of this property is respected.
    public var orientToTrueNorth = true

    ///Whether debugging feature points should be displayed.
    ///Defaults to false
    public var showFeaturePoints = false

    // MARK: Scene location estimates
    public var currentScenePosition: SCNVector3? {
        guard let pointOfView = pointOfView else { return nil }
        return scene.rootNode.convertPosition(pointOfView.position, to: sceneNode)
    }

    public var currentEulerAngles: SCNVector3? { return pointOfView?.eulerAngles }

    public internal(set) var locationNodes = [LocationNode]()

    // MARK: Internal desclarations
    internal var didFetchInitialLocation = false
    internal let sceneLocationManager = SceneLocationManager()

    // MARK: Setup
    public convenience init() {
        self.init(frame: .zero, options: nil)
    }

    public override init(frame: CGRect, options: [String : Any]? = nil) {
        super.init(frame: frame, options: options)

        sceneLocationManager.sceneLocationDelegate = self
        delegate = self

        // Show statistics such as fps and timing information
        showsStatistics = false

        debugOptions = showFeaturePoints ? [ARSCNDebugOptions.showFeaturePoints] : debugOptions
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    ///Resets the scene heading to 0
    internal func resetSceneHeading() {
        sceneNode?.eulerAngles.y = 0
    }

    internal func confirmLocationOfLocationNode(_ locationNode: LocationNode) {
        locationNode.location = locationOfLocationNode(locationNode)

        locationNode.locationConfirmed = true

        locationViewDelegate?.didConfirmLocationOfNode(sceneLocationView: self, node: locationNode)
    }

    ///Gives the best estimate of the location of a node
    internal func locationOfLocationNode(_ locationNode: LocationNode) -> CLLocation {
        if locationNode.locationConfirmed || locationEstimateMethod == .coreLocationDataOnly {
            return locationNode.location!
        }

        if let bestLocationEstimate = sceneLocationManager.bestLocationEstimate,
            locationNode.location == nil
                || bestLocationEstimate.location.horizontalAccuracy < locationNode.location!.horizontalAccuracy {
            return bestLocationEstimate.translatedLocation(to: locationNode.position)
        } else {
            return locationNode.location!
        }
    }
}

public extension SceneLocationView {
    public func run() {
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.worldAlignment = orientToTrueNorth ? .gravityAndHeading : .gravity

        // Run the view's session
        session.run(configuration)
        sceneLocationManager.run()
    }

    public func pause() {
        session.pause()
        sceneLocationManager.pause()
    }

    // MARK: True North
    ///iOS can be inaccurate when setting true north
    ///The scene is oriented to true north, and will update its heading when it gets a more accurate reading
    ///You can disable this through setting the
    ///These functions provide manual overriding of the scene heading,
    /// if you have a more precise idea of where True North is
    ///The goal is for the True North orientation problems to be resolved
    ///At which point these functions would no longer be useful

    ///Moves the scene heading clockwise by 1 degree
    ///Intended for correctional purposes
    public func moveSceneHeadingClockwise() {
        sceneNode?.eulerAngles.y -= Float(1).degreesToRadians
    }

    ///Moves the scene heading anti-clockwise by 1 degree
    ///Intended for correctional purposes
    public func moveSceneHeadingAntiClockwise() {
        sceneNode?.eulerAngles.y += Float(1).degreesToRadians
    }

    // MARK: LocationNodes
    ///upon being added, a node's location, locationConfirmed and position may be modified and should not be changed externally.
    public func addLocationNodeForCurrentPosition(locationNode: LocationNode) {
        guard let currentPosition = currentScenePosition,
            let currentLocation = sceneLocationManager.currentLocation,
            let sceneNode = sceneNode else { return }

        locationNode.location = currentLocation

        ///Location is not changed after being added when using core location data only for location estimates
        locationNode.locationConfirmed = locationEstimateMethod == .coreLocationDataOnly

        locationNode.position = currentPosition

        locationNodes.append(locationNode)
        sceneNode.addChildNode(locationNode)
    }
    public func addLocationNodesForCurrentPosition(locationNodes: [LocationNode]) {
        locationNodes.forEach { addLocationNodeForCurrentPosition(locationNode: $0) }
    }

    ///location not being nil, and locationConfirmed being true are required
    ///Upon being added, a node's position will be modified and should not be changed externally.
    ///location will not be modified, but taken as accurate.
    public func addLocationNodeWithConfirmedLocation(locationNode: LocationNode) {
        if locationNode.location == nil || locationNode.locationConfirmed == false { return }

        locationNode.updatePositionAndScale(setup: true, scenePosition: currentScenePosition,
                                            locationManager: sceneLocationManager) {
                                                self.locationViewDelegate?
                                                    .didUpdateLocationAndScaleOfLocationNode(sceneLocationView: self,
                                                                                             locationNode: locationNode)
        }

        locationNodes.append(locationNode)
        sceneNode?.addChildNode(locationNode)
    }

    public func addLocationNodesWithConfirmedLocation(locationNodes: [LocationNode]) {
        locationNodes.forEach { addLocationNodeWithConfirmedLocation(locationNode: $0) }
    }

    public func removeLocationNode(locationNode: LocationNode) {
        if let index = locationNodes.index(of: locationNode) {
            locationNodes.remove(at: index)
        }

        locationNode.removeFromParentNode()
    }

    public func removeLocationNodes(locationNodes: [LocationNode]) {
        locationNodes.forEach { removeLocationNode(locationNode: $0) }
    }
}

extension SceneLocationView: SceneLocationManagerDelegate {
    var scenePosition: SCNVector3? { return currentScenePosition }

    func confirmLocationOfDistantLocationNodes() {
        guard let currentPosition = currentScenePosition else { return }

        locationNodes.filter { !$0.locationConfirmed }.forEach {
            let currentPoint = CGPoint.pointWithVector(vector: currentPosition)
            let locationNodePoint = CGPoint.pointWithVector(vector: $0.position)

            if !currentPoint.radiusContainsPoint(radius: CGFloat(SceneLocationView.sceneLimit), point: locationNodePoint) {
                confirmLocationOfLocationNode($0)
            }
        }
    }

    func updatePositionAndScaleOfLocationNodes() {
        locationNodes.filter { $0.continuallyUpdatePositionAndScale }.forEach { node in
            node.updatePositionAndScale(scenePosition: currentScenePosition, locationManager: sceneLocationManager) {
                self.locationViewDelegate?.didUpdateLocationAndScaleOfLocationNode(sceneLocationView: self, locationNode: node)
            }
        }
    }

    func didAddSceneLocationEstimate(position: SCNVector3, location: CLLocation) {
        locationEstimateDelegate?.didAddSceneLocationEstimate(sceneLocationView: self, position: position, location: location)
    }

    func didRemoveSceneLocationEstimate(position: SCNVector3, location: CLLocation) {
        locationEstimateDelegate?.didRemoveSceneLocationEstimate(sceneLocationView: self, position: position, location: location)
    }
}

extension SceneLocationView: ARSCNViewDelegate {
    public func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        if sceneNode == nil {
            sceneNode = SCNNode()
            scene.rootNode.addChildNode(sceneNode!)

            if showAxesNode {
                let axesNode = SCNNode.axesNode(quiverLength: 0.1, quiverThickness: 0.5)
                sceneNode?.addChildNode(axesNode)
            }
        }

        if !didFetchInitialLocation {
            //Current frame and current location are required for this to be successful
            if session.currentFrame != nil,
                let currentLocation = sceneLocationManager.currentLocation {
                didFetchInitialLocation = true
                sceneLocationManager.addSceneLocationEstimate(location: currentLocation)
            }
        }
    }
}
