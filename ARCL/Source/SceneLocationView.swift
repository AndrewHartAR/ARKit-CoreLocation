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
@available(iOS 11.0, *)
open class SceneLocationView: ARSCNView {
    /// The limit to the scene, in terms of what data is considered reasonably accurate.
    /// Measured in meters.
    static let sceneLimit = 100.0

    public weak var locationViewDelegate: SceneLocationViewDelegate?
    public weak var locationEstimateDelegate: SceneLocationViewEstimateDelegate?
    public weak var locationNodeTouchDelegate: LNTouchDelegate?

    public let sceneLocationManager = SceneLocationManager()

    /// The method to use for determining locations.
    /// Not advisable to change this as the scene is ongoing.
    public var locationEstimateMethod: LocationEstimateMethod {
        get {
            return sceneLocationManager.locationEstimateMethod
        }
        set {
            sceneLocationManager.locationEstimateMethod = newValue

            locationNodes.forEach { $0.locationEstimateMethod = newValue }
        }
    }

    /// When set to true, displays an axes node at the start of the scene
    public var showAxesNode = false

    public internal(set) var sceneNode: SCNNode? {
        didSet {
            guard sceneNode != nil else { return }

            locationNodes.forEach { sceneNode?.addChildNode($0) }

            locationViewDelegate?.didSetupSceneNode(sceneLocationView: self, sceneNode: sceneNode!)
        }
    }

    /// Only to be overrided if you plan on manually setting True North.
    /// When true, sets up the scene to face what the device considers to be True North.
    /// This can be inaccurate, hence the option to override it.
    /// The functions for altering True North can be used irrespective of this value,
    /// but if the scene is oriented to true north, it will update without warning,
    /// thus affecting your alterations.
    /// The initial value of this property is respected.
    public var orientToTrueNorth = true

    /// Whether debugging feature points should be displayed.
    /// Defaults to false
    public var showFeaturePoints = false

    // MARK: Scene location estimates
    public var currentScenePosition: SCNVector3? {
        guard let pointOfView = pointOfView else { return nil }
        return scene.rootNode.convertPosition(pointOfView.position, to: sceneNode)
    }

    public var currentEulerAngles: SCNVector3? { return pointOfView?.eulerAngles }

    public internal(set) var locationNodes = [LocationNode]()
    public internal(set) var polylineNodes = [PolylineNode]()

    // MARK: Internal desclarations
    internal var didFetchInitialLocation = false

    // MARK: Setup
    public convenience init() {
        self.init(frame: .zero, options: nil)
    }

    public override init(frame: CGRect, options: [String: Any]? = nil) {
        super.init(frame: frame, options: options)
        finishInitialization()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        finishInitialization()
    }

    private func finishInitialization() {
        sceneLocationManager.sceneLocationDelegate = self

        delegate = self

        // Show statistics such as fps and timing information
        showsStatistics = false

        debugOptions = showFeaturePoints ? [ARSCNDebugOptions.showFeaturePoints] : debugOptions

        let touchGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(sceneLocationViewTouched(sender:)))
        self.addGestureRecognizer(touchGestureRecognizer)
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
    }

    /// Resets the scene heading to 0
    func resetSceneHeading() {
        sceneNode?.eulerAngles.y = 0
    }

    func confirmLocationOfLocationNode(_ locationNode: LocationNode) {
        locationNode.location = locationOfLocationNode(locationNode)
        locationViewDelegate?.didConfirmLocationOfNode(sceneLocationView: self, node: locationNode)
    }

    /// Gives the best estimate of the location of a node
    func locationOfLocationNode(_ locationNode: LocationNode) -> CLLocation {
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

@available(iOS 11.0, *)
public extension SceneLocationView {

    func run() {
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.worldAlignment = orientToTrueNorth ? .gravityAndHeading : .gravity

        // Run the view's session
        session.run(configuration)
        sceneLocationManager.run()
    }

    func pause() {
        session.pause()
        sceneLocationManager.pause()
    }

    // MARK: True North

    /// iOS can be inaccurate when setting true north
    /// The scene is oriented to true north, and will update its heading when it gets a more accurate reading
    /// You can disable this through setting the
    /// These functions provide manual overriding of the scene heading,
    /// if you have a more precise idea of where True North is
    /// The goal is for the True North orientation problems to be resolved
    /// At which point these functions would no longer be useful
    /// Moves the scene heading clockwise by 1 degree
    /// Intended for correctional purposes
    func moveSceneHeadingClockwise() {
        sceneNode?.eulerAngles.y -= Float(1).degreesToRadians
    }

    /// Moves the scene heading anti-clockwise by 1 degree
    /// Intended for correctional purposes
    func moveSceneHeadingAntiClockwise() {
        sceneNode?.eulerAngles.y += Float(1).degreesToRadians
    }

    // MARK: LocationNodes

    /// upon being added, a node's location, locationConfirmed and position may be modified and should not be changed externally.
    func addLocationNodeForCurrentPosition(locationNode: LocationNode) {
        guard let currentPosition = currentScenePosition,
            let currentLocation = sceneLocationManager.currentLocation,
            let sceneNode = sceneNode else { return }

        locationNode.location = currentLocation
        locationNode.position = currentPosition

        locationNodes.append(locationNode)
        sceneNode.addChildNode(locationNode)
    }

    func addLocationNodesForCurrentPosition(locationNodes: [LocationNode]) {
        locationNodes.forEach { addLocationNodeForCurrentPosition(locationNode: $0) }
    }

    /// location not being nil, and locationConfirmed being true are required
    /// Upon being added, a node's position will be modified and should not be changed externally.
    /// location will not be modified, but taken as accurate.
    func addLocationNodeWithConfirmedLocation(locationNode: LocationNode) {
        if locationNode.location == nil || locationNode.locationConfirmed == false {
            return
        }

        let locationNodeLocation = locationOfLocationNode(locationNode)

        locationNode.updatePositionAndScale(setup: true,
                                            scenePosition: currentScenePosition, locationNodeLocation: locationNodeLocation,
                                            locationManager: sceneLocationManager) {
                                                self.locationViewDelegate?
                                                    .didUpdateLocationAndScaleOfLocationNode(sceneLocationView: self,
                                                                                             locationNode: locationNode)
        }

        locationNodes.append(locationNode)
        sceneNode?.addChildNode(locationNode)
    }

    @objc func sceneLocationViewTouched(sender: UITapGestureRecognizer) {
        guard let touchedView = sender.view as? SCNView else {
            return
        }

        let coordinates = sender.location(in: touchedView)
        let hitTest = touchedView.hitTest(coordinates)

        if !hitTest.isEmpty,
            let firstHitTest = hitTest.first,
            let touchedNode = firstHitTest.node as? AnnotationNode {
            self.locationNodeTouchDelegate?.locationNodeTouched(node: touchedNode)
        }
    }

    func addLocationNodesWithConfirmedLocation(locationNodes: [LocationNode]) {
        locationNodes.forEach { addLocationNodeWithConfirmedLocation(locationNode: $0) }
    }

    func removeAllNodes() {
        locationNodes.removeAll()
        guard let childNodes = sceneNode?.childNodes else { return }
        for node in childNodes {
            node.removeFromParentNode()
        }
    }

    /// Determine if scene contains a node with the specified tag
    ///
    /// - Parameter tag: tag text
    /// - Returns: true if a LocationNode with the tag exists; false otherwise
    func sceneContainsNodeWithTag(_ tag: String) -> Bool {
        return findNodes(tagged: tag).count > 0
    }

    /// Find all location nodes in the scene tagged with `tag`
    ///
    /// - Parameter tag: The tag text for which to search nodes.
    /// - Returns: A list of all matching tags
    func findNodes(tagged tag: String) -> [LocationNode] {
        guard tag.count > 0 else {
            return []
        }

        return locationNodes.filter { $0.tag == tag }
    }

    func removeLocationNode(locationNode: LocationNode) {
        if let index = locationNodes.index(of: locationNode) {
            locationNodes.remove(at: index)
        }

        locationNode.removeFromParentNode()
    }

    func removeLocationNodes(locationNodes: [LocationNode]) {
        locationNodes.forEach { removeLocationNode(locationNode: $0) }
    }
}

@available(iOS 11.0, *)
public extension SceneLocationView {

    /// Adds routes to the scene and lets you specify the geometry prototype for the box.
    /// Note: You can provide your own SCNBox prototype to base the direction nodes from.
    ///
    /// - Parameters:
    ///   - routes: The MKRoute of directions.
    ///   - boxBuilder: A block that will customize how a box is built.
    func addRoutes(routes: [MKRoute], boxBuilder: BoxBuilder? = nil) {
        guard let altitude = sceneLocationManager.currentLocation?.altitude else {
            return assertionFailure("we don't have an elevation")
        }
        let polyNodes = routes.map {
            PolylineNode(polyline: $0.polyline, altitude: altitude - 2.0, boxBuilder: boxBuilder)
        }

        polylineNodes.append(contentsOf: polyNodes)
        polyNodes.forEach {
            $0.locationNodes.forEach {
                let locationNodeLocation = self.locationOfLocationNode($0)
                $0.updatePositionAndScale(setup: true,
                                          scenePosition: currentScenePosition,
                                          locationNodeLocation: locationNodeLocation,
                                          locationManager: sceneLocationManager,
                                          onCompletion: {})
                sceneNode?.addChildNode($0)
            }
        }
    }

    func removeRoutes(routes: [MKRoute]) {
        routes.forEach { route in
            if let index = polylineNodes.index(where: { $0.polyline == route.polyline }) {
                polylineNodes.remove(at: index)
            }
        }
    }
}

@available(iOS 11.0, *)
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
            let locationNodeLocation = locationOfLocationNode(node)
            node.updatePositionAndScale(scenePosition: currentScenePosition,
                                        locationNodeLocation: locationNodeLocation,
                                        locationManager: sceneLocationManager) {
                                            self.locationViewDelegate?
                                                .didUpdateLocationAndScaleOfLocationNode(sceneLocationView: self,
                                                                                         locationNode: node)
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
