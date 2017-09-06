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

@available(iOS 11.0, *)
public protocol SceneLocationViewDelegate: class {
    func sceneLocationViewDidAddSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation)
    func sceneLocationViewDidRemoveSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation)
    
    ///After a node's location is initially set based on current location,
    ///it is later confirmed once the user moves far enough away from it.
    ///This update uses location data collected since the node was placed to give a more accurate location.
    func sceneLocationViewDidConfirmLocationOfNode(sceneLocationView: SceneLocationView, node: LocationNode)
    
    func sceneLocationViewDidSetupSceneNode(sceneLocationView: SceneLocationView, sceneNode: SCNNode)
    
    func sceneLocationViewDidUpdateLocationAndScaleOfLocationNode(sceneLocationView: SceneLocationView, locationNode: LocationNode)
}

///Different methods which can be used when determining locations (such as the user's location).
public enum LocationEstimateMethod {
    ///Only uses core location data.
    ///Not suitable for adding nodes using current position, which requires more precision.
    case coreLocationDataOnly
    
    ///Combines knowledge about movement through the AR world with
    ///the most relevant Core Location estimate (based on accuracy and time).
    case mostRelevantEstimate
}

//Should conform to delegate here, add in future commit
@available(iOS 11.0, *)
public class SceneLocationView: ARSCNView, ARSCNViewDelegate {
    ///The limit to the scene, in terms of what data is considered reasonably accurate.
    ///Measured in meters.
    private static let sceneLimit = 100.0
    
    public weak var locationDelegate: SceneLocationViewDelegate?
    
    ///The method to use for determining locations.
    ///Not advisable to change this as the scene is ongoing.
    public var locationEstimateMethod: LocationEstimateMethod = .mostRelevantEstimate
    
    let locationManager = LocationManager()
    ///When set to true, displays an axes node at the start of the scene
    public var showAxesNode = false
    
    private(set) var locationNodes = [LocationNode]()
    
    private var sceneLocationEstimates = [SceneLocationEstimate]()
    
    public private(set) var sceneNode: SCNNode? {
        didSet {
            if sceneNode != nil {
                for locationNode in locationNodes {
                    sceneNode!.addChildNode(locationNode)
                }
                
                locationDelegate?.sceneLocationViewDidSetupSceneNode(sceneLocationView: self, sceneNode: sceneNode!)
            }
        }
    }
    
    private var updateEstimatesTimer: Timer?
    
    private var didFetchInitialLocation = false
    
    ///Whether debugging feature points should be displayed.
    ///Defaults to false
    var showFeaturePoints = false
    
    ///Only to be overrided if you plan on manually setting True North.
    ///When true, sets up the scene to face what the device considers to be True North.
    ///This can be inaccurate, hence the option to override it.
    ///The functions for altering True North can be used irrespective of this value,
    ///but if the scene is oriented to true north, it will update without warning,
    ///thus affecting your alterations.
    ///The initial value of this property is respected.
    public var orientToTrueNorth = true
    
    //MARK: Setup
    public convenience init() {
        self.init(frame: CGRect.zero, options: nil)
    }
    
    public override init(frame: CGRect, options: [String : Any]? = nil) {
        super.init(frame: frame, options: options)
        finishInitialization()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        finishInitialization()
    }

    private func finishInitialization() {
        locationManager.delegate = self

        delegate = self

        // Show statistics such as fps and timing information
        showsStatistics = false

        if showFeaturePoints {
            debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        }
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
    }
    
    public func run() {
        // Create a session configuration
		let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        if orientToTrueNorth {
            configuration.worldAlignment = .gravityAndHeading
        } else {
            configuration.worldAlignment = .gravity
        }
        
        // Run the view's session
        session.run(configuration)
        
        updateEstimatesTimer?.invalidate()
        updateEstimatesTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(SceneLocationView.updateLocationData), userInfo: nil, repeats: true)
    }
    
    public func pause() {
        session.pause()
        updateEstimatesTimer?.invalidate()
        updateEstimatesTimer = nil
    }
    
    @objc private func updateLocationData() {
        removeOldLocationEstimates()
        confirmLocationOfDistantLocationNodes()
        updatePositionAndScaleOfLocationNodes()
    }
    
    //MARK: True North
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
    
    ///Resets the scene heading to 0
    func resetSceneHeading() {
        sceneNode?.eulerAngles.y = 0
    }
    
    //MARK: Scene location estimates
    
    public func currentScenePosition() -> SCNVector3? {
        guard let pointOfView = pointOfView else {
            return nil
        }
        
        return scene.rootNode.convertPosition(pointOfView.position, to: sceneNode)
    }
    
    public func currentEulerAngles() -> SCNVector3? {
        return pointOfView?.eulerAngles
    }
    
    ///Adds a scene location estimate based on current time, camera position and location from location manager
    fileprivate func addSceneLocationEstimate(location: CLLocation) {
        if let position = currentScenePosition() {
            let sceneLocationEstimate = SceneLocationEstimate(location: location, position: position)
            self.sceneLocationEstimates.append(sceneLocationEstimate)
            
            locationDelegate?.sceneLocationViewDidAddSceneLocationEstimate(sceneLocationView: self, position: position, location: location)
        }
    }
    
    private func removeOldLocationEstimates() {
        if let currentScenePosition = currentScenePosition() {
            self.removeOldLocationEstimates(currentScenePosition: currentScenePosition)
        }
    }
    
    private func removeOldLocationEstimates(currentScenePosition: SCNVector3) {
        let currentPoint = CGPoint.pointWithVector(vector: currentScenePosition)
        
        sceneLocationEstimates = sceneLocationEstimates.filter({
            let point = CGPoint.pointWithVector(vector: $0.position)
            
            let radiusContainsPoint = currentPoint.radiusContainsPoint(radius: CGFloat(SceneLocationView.sceneLimit), point: point)
            
            if !radiusContainsPoint {
                locationDelegate?.sceneLocationViewDidRemoveSceneLocationEstimate(sceneLocationView: self, position: $0.position, location: $0.location)
            }
            
            return radiusContainsPoint
        })
    }
    
    ///The best estimation of location that has been taken
    ///This takes into account horizontal accuracy, and the time at which the estimation was taken
    ///favouring the most accurate, and then the most recent result.
    ///This doesn't indicate where the user currently is.
    func bestLocationEstimate() -> SceneLocationEstimate? {
        let sortedLocationEstimates = sceneLocationEstimates.sorted(by: {
            if $0.location.horizontalAccuracy == $1.location.horizontalAccuracy {
                return $0.location.timestamp > $1.location.timestamp
            }
            
            return $0.location.horizontalAccuracy < $1.location.horizontalAccuracy
        })
        
        return sortedLocationEstimates.first
    }
    
    public func currentLocation() -> CLLocation? {
        if locationEstimateMethod == .coreLocationDataOnly {
            return locationManager.currentLocation
        }
        
        guard let bestEstimate = self.bestLocationEstimate(),
            let position = currentScenePosition() else {
                return nil
        }
        
        return bestEstimate.translatedLocation(to: position)
    }
    
    //MARK: LocationNodes
    ///upon being added, a node's location, locationConfirmed and position may be modified and should not be changed externally.
    public func addLocationNodeForCurrentPosition(locationNode: LocationNode) {
        guard let currentPosition = currentScenePosition(),
        let currentLocation = currentLocation(),
        let sceneNode = self.sceneNode else {
            return
        }
        
        locationNode.location = currentLocation
        
        ///Location is not changed after being added when using core location data only for location estimates
        if locationEstimateMethod == .coreLocationDataOnly {
            locationNode.locationConfirmed = true
        } else {
            locationNode.locationConfirmed = false
        }
        
        locationNode.position = currentPosition
        
        locationNodes.append(locationNode)
        sceneNode.addChildNode(locationNode)
    }
    
    ///location not being nil, and locationConfirmed being true are required
    ///Upon being added, a node's position will be modified and should not be changed externally.
    ///location will not be modified, but taken as accurate.
    public func addLocationNodeWithConfirmedLocation(locationNode: LocationNode) {
        if locationNode.location == nil || locationNode.locationConfirmed == false {
            return
        }
        
        updatePositionAndScaleOfLocationNode(locationNode: locationNode, initialSetup: true, animated: false)
        
        locationNodes.append(locationNode)
        sceneNode?.addChildNode(locationNode)
    }
    
    public func removeLocationNode(locationNode: LocationNode) {
        if let index = locationNodes.index(of: locationNode) {
            locationNodes.remove(at: index)
        }
        
        locationNode.removeFromParentNode()
    }
    
    private func confirmLocationOfDistantLocationNodes() {
        guard let currentPosition = currentScenePosition() else {
            return
        }
        
        for locationNode in locationNodes {
            if !locationNode.locationConfirmed {
                let currentPoint = CGPoint.pointWithVector(vector: currentPosition)
                let locationNodePoint = CGPoint.pointWithVector(vector: locationNode.position)
                
                if !currentPoint.radiusContainsPoint(radius: CGFloat(SceneLocationView.sceneLimit), point: locationNodePoint) {
                    confirmLocationOfLocationNode(locationNode)
                }
            }
        }
    }
    
    ///Gives the best estimate of the location of a node
    func locationOfLocationNode(_ locationNode: LocationNode) -> CLLocation {
        if locationNode.locationConfirmed || locationEstimateMethod == .coreLocationDataOnly {
            return locationNode.location!
        }
        
        if let bestLocationEstimate = bestLocationEstimate(),
            locationNode.location == nil ||
                bestLocationEstimate.location.horizontalAccuracy < locationNode.location!.horizontalAccuracy {
            let translatedLocation = bestLocationEstimate.translatedLocation(to: locationNode.position)
            
            return translatedLocation
        } else {
            return locationNode.location!
        }
    }
    
    private func confirmLocationOfLocationNode(_ locationNode: LocationNode) {
        locationNode.location = locationOfLocationNode(locationNode)
        
        locationNode.locationConfirmed = true
        
        locationDelegate?.sceneLocationViewDidConfirmLocationOfNode(sceneLocationView: self, node: locationNode)
    }
    
    func updatePositionAndScaleOfLocationNodes() {
        for locationNode in locationNodes {
            if locationNode.continuallyUpdatePositionAndScale {
                updatePositionAndScaleOfLocationNode(locationNode: locationNode, animated: true)
            }
        }
    }
    
    public func updatePositionAndScaleOfLocationNode(locationNode: LocationNode, initialSetup: Bool = false, animated: Bool = false, duration: TimeInterval = 0.1) {
        guard let currentPosition = currentScenePosition(),
            let currentLocation = currentLocation() else {
            return
        }
        
        SCNTransaction.begin()
        
        if animated {
            SCNTransaction.animationDuration = duration
        } else {
            SCNTransaction.animationDuration = 0
        }
        
        let locationNodeLocation = locationOfLocationNode(locationNode)
        
        //Position is set to a position coordinated via the current position
        let locationTranslation = currentLocation.translation(toLocation: locationNodeLocation)
        
        
        let adjustedDistance: CLLocationDistance
        
        let distance = locationNodeLocation.distance(from: currentLocation)
        
        if locationNode.locationConfirmed &&
            (distance > 100 || locationNode.continuallyAdjustNodePositionWhenWithinRange || initialSetup) {
            if distance > 100 {
                //If the item is too far away, bring it closer and scale it down
                let scale = 100 / Float(distance)
                
                adjustedDistance = distance * Double(scale)
                
                let adjustedTranslation = SCNVector3(
                    x: Float(locationTranslation.longitudeTranslation) * scale,
                    y: Float(locationTranslation.altitudeTranslation) * scale,
                    z: Float(locationTranslation.latitudeTranslation) * scale)
                
                let position = SCNVector3(
                    x: currentPosition.x + adjustedTranslation.x,
                    y: currentPosition.y + adjustedTranslation.y,
                    z: currentPosition.z - adjustedTranslation.z)
                
                locationNode.position = position
                
                locationNode.scale = SCNVector3(x: scale, y: scale, z: scale)
            } else {
                adjustedDistance = distance
                let position = SCNVector3(
                    x: currentPosition.x + Float(locationTranslation.longitudeTranslation),
                    y: currentPosition.y + Float(locationTranslation.altitudeTranslation),
                    z: currentPosition.z - Float(locationTranslation.latitudeTranslation))
                
                locationNode.position = position
                locationNode.scale = SCNVector3(x: 1, y: 1, z: 1)
            }
        } else {
            //Calculates distance based on the distance within the scene, as the location isn't yet confirmed
            adjustedDistance = Double(currentPosition.distance(to: locationNode.position))
            
            locationNode.scale = SCNVector3(x: 1, y: 1, z: 1)
        }
        
        if let annotationNode = locationNode as? LocationAnnotationNode {
            //The scale of a node with a billboard constraint applied is ignored
            //The annotation subnode itself, as a subnode, has the scale applied to it
            let appliedScale = locationNode.scale
            locationNode.scale = SCNVector3(x: 1, y: 1, z: 1)
            
            var scale: Float
            
            if annotationNode.scaleRelativeToDistance {
                scale = appliedScale.y
                annotationNode.annotationNode.scale = appliedScale
            } else {
                //Scale it to be an appropriate size so that it can be seen
                scale = Float(adjustedDistance) * 0.181
                
                if distance > 3000 {
                    scale = scale * 0.75
                }
                
                annotationNode.annotationNode.scale = SCNVector3(x: scale, y: scale, z: scale)
            }
            
            annotationNode.pivot = SCNMatrix4MakeTranslation(0, -1.1 * scale, 0)
        }
        
        SCNTransaction.commit()
        
        locationDelegate?.sceneLocationViewDidUpdateLocationAndScaleOfLocationNode(sceneLocationView: self, locationNode: locationNode)
    }
    
    //MARK: ARSCNViewDelegate
    
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
                let currentLocation = self.locationManager.currentLocation {
                didFetchInitialLocation = true
                
                self.addSceneLocationEstimate(location: currentLocation)
            }
        }
    }
    
    public func sessionWasInterrupted(_ session: ARSession) {
        print("session was interrupted")
    }
    
    public func sessionInterruptionEnded(_ session: ARSession) {
        print("session interruption ended")
    }
    
    public func session(_ session: ARSession, didFailWithError error: Error) {
        print("session did fail with error: \(error)")
    }
    
    public func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .limited(.insufficientFeatures):
            print("camera did change tracking state: limited, insufficient features")
        case .limited(.excessiveMotion):
            print("camera did change tracking state: limited, excessive motion")
        case .limited(.initializing):
            print("camera did change tracking state: limited, initializing")
        case .normal:
            print("camera did change tracking state: normal")
        case .notAvailable:
            print("camera did change tracking state: not available")
        }
    }
}

//MARK: LocationManager
@available(iOS 11.0, *)
extension SceneLocationView: LocationManagerDelegate {
    func locationManagerDidUpdateLocation(_ locationManager: LocationManager, location: CLLocation) {
        addSceneLocationEstimate(location: location)
    }
    
    func locationManagerDidUpdateHeading(_ locationManager: LocationManager, heading: CLLocationDirection, accuracy: CLLocationAccuracy) {
        
    }
}
