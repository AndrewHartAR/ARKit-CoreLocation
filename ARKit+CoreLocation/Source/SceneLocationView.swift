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

public protocol SceneLocationViewDelegate: class {
    func sceneLocationViewDidAddSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation)
    func sceneLocationViewDidRemoveSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation)
    
    ///After a node's location is initially set based on current location,
    ///it is later confirmed once the user moves far enough away from it.
    ///This update uses location data collected since the node was placed to give a more accurate location.
    func sceneLocationViewDidConfirmLocationOfNode(sceneLocationView: SceneLocationView, node: LocationNode)
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

public class SceneLocationView: UIView {
    ///The limit to the scene, in terms of what data is considered reasonably accurate.
    ///Measured in meters.
    private static let sceneLimit = 100.0
    
    private let sceneView = ARSCNView()
    
    public weak var delegate: SceneLocationViewDelegate?
    
    ///The method to use for determining locations.
    ///Not advisable to change this as the scene is ongoing.
    public var locationEstimateMethod: LocationEstimateMethod = .mostRelevantEstimate
    
    let locationManager = LocationManager()
    
    private(set) var locationNodes = [LocationNode]()
    
    private var sceneLocationEstimates = [SceneLocationEstimate]()
    
    private var sceneNode: SCNNode? {
        didSet {
            if sceneNode != nil {
                for locationNode in locationNodes {
                    sceneNode!.addChildNode(locationNode)
                }
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
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        locationManager.delegate = self
        
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false
        
        if showFeaturePoints {
            sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        }
        
        // Create a new scene
        let scene = SCNScene()
        sceneView.scene = scene
        addSubview(sceneView)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        sceneView.frame = self.bounds
    }
    
    public func run() {
        // Create a session configuration
        let configuration = ARWorldTrackingSessionConfiguration()
        configuration.planeDetection = .horizontal
        
        if orientToTrueNorth {
            configuration.worldAlignment = .gravityAndHeading
        } else {
            configuration.worldAlignment = .gravity
        }
        
        // Run the view's session
        sceneView.session.run(configuration)
        
        updateEstimatesTimer?.invalidate()
        updateEstimatesTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(SceneLocationView.updateLocationData), userInfo: nil, repeats: true)
    }
    
    public func pause() {
        sceneView.session.pause()
        updateEstimatesTimer?.invalidate()
        updateEstimatesTimer = nil
    }
    
    @objc private func updateLocationData() {
        removeOldLocationEstimates()
        confirmLocationOfDistantLocationNodes()
        updatePositionOfLocationNodesWithConfirmedLocation()
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
    
    func currentScenePosition() -> SCNVector3? {
        guard let pointOfView = sceneView.pointOfView else {
            return nil
        }
        
        return sceneView.scene.rootNode.convertPosition(pointOfView.position, to: sceneNode)
    }
    
    ///Adds a scene location estimate based on current time, camera position and location from location manager
    private func addSceneLocationEstimate(location: CLLocation) {
        if let position = currentScenePosition() {
            let sceneLocationEstimate = SceneLocationEstimate(location: location, position: position)
            self.sceneLocationEstimates.append(sceneLocationEstimate)
            
            delegate?.sceneLocationViewDidAddSceneLocationEstimate(sceneLocationView: self, position: position, location: location)
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
                delegate?.sceneLocationViewDidRemoveSceneLocationEstimate(sceneLocationView: self, position: $0.position, location: $0.location)
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
        
        updatePositionOfLocationNode(locationNode: locationNode)
        
        locationNodes.append(locationNode)
        sceneNode?.addChildNode(locationNode)
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
                    confirmLocationOfLocationNode(locationNode: locationNode)
                }
            }
        }
    }
    
    private func confirmLocationOfLocationNode(locationNode: LocationNode) {
        if let bestLocationEstimate = bestLocationEstimate(),
            locationNode.location == nil ||
            bestLocationEstimate.location.horizontalAccuracy < locationNode.location!.horizontalAccuracy {
            let translatedLocation = bestLocationEstimate.translatedLocation(to: locationNode.position)
            
            locationNode.location = translatedLocation
        }
        
        locationNode.locationConfirmed = true
        
        delegate?.sceneLocationViewDidConfirmLocationOfNode(sceneLocationView: self, node: locationNode)
    }
    
    func updatePositionOfLocationNodesWithConfirmedLocation() {
        for locationNode in locationNodes {
            if locationNode.locationConfirmed {
                updatePositionOfLocationNode(locationNode: locationNode)
            }
        }
    }
    
    func updatePositionOfLocationNode(locationNode: LocationNode) {
        guard let currentPosition = currentScenePosition(),
            let currentLocation = currentLocation() else {
            return
        }
        
        //Position is set to a position coordinated via the current position
        let locationTranslation = currentLocation.translation(toLocation: locationNode.location!)
        
        let position = SCNVector3(
            x: currentPosition.x + Float(locationTranslation.longitudeTranslation),
            y: currentPosition.y,
            z: currentPosition.z - Float(locationTranslation.longitudeTranslation))
        
        locationNode.position = position
    }
}

//MARK: LocationManager
extension SceneLocationView: LocationManagerDelegate {
    func locationManagerDidUpdateLocation(_ locationManager: LocationManager, location: CLLocation) {
        self.addSceneLocationEstimate(location: location)
    }
    
    func locationManagerDidUpdateHeading(_ locationManager: LocationManager, heading: CLLocationDirection, accuracy: CLLocationAccuracy) {
        
    }
}

//MARK: ARSceneViewDelegate
extension SceneLocationView: ARSCNViewDelegate {
    public func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        if sceneNode == nil {
            sceneNode = SCNNode()
            sceneView.scene.rootNode.addChildNode(sceneNode!)
            
            let axesNode = SCNNode.axesNode(quiverLength: 0.1, quiverThickness: 0.5)
            sceneNode?.addChildNode(axesNode)
        }
        
        if !didFetchInitialLocation {
            //Current frame and current location are required for this to be successful
            if sceneView.session.currentFrame != nil,
                let currentLocation = self.locationManager.currentLocation {
                didFetchInitialLocation = true
                
                self.addSceneLocationEstimate(location: currentLocation)
            }
        }
    }
}
