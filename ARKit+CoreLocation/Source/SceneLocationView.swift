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
import CocoaLumberjack

class SceneLocationView: UIView, ARSCNViewDelegate, LocationManagerDelegate {
    ///The limit to the scene, in terms of what data is considered reasonably accurate.
    ///Measured in meters.
    private static let sceneLimit = 100.0
    
    ///Displays an arrow that points north upon creation of the scene.
    ///This is based on Core Location's heading, but the setup isn't always correct
    ///so the arrow should help to clear that up.
    ///The setup of the scene to point north occurs within renderer:didUpdateNode:.
    ///Feel free to improve upon this.
    ///For one thing, I know it doesn't work too well if you start with your phone angled down.
    ///The setting for this given at the start of the scene is respected.
    var displayDebuggingArrow = false
    
    private let sceneView = ARSCNView()
    
    private let locationManager = LocationManager()
    
    private(set) var sceneAnnotations = [SceneAnnotation]()
    private var sceneLocationEstimates = [SceneLocationEstimate]()
    
    private var sceneNode: SCNNode?
    
    private var updateEstimatesTimer: Timer?
    
    private var didFetchInitialLocation = false
    
    //MARK: Setup
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        locationManager.delegate = self
        
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/scene.scn")!
        sceneView.scene = scene
        addSubview(sceneView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        sceneView.frame = self.bounds
    }
    
    func run() {
        // Create a session configuration
        let configuration = ARWorldTrackingSessionConfiguration()
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
        
        self.updateEstimatesTimer?.invalidate()
        self.updateEstimatesTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(SceneLocationView.updateEstimates), userInfo: nil, repeats: true)
    }
    
    func pause() {
        sceneView.session.pause()
        self.updateEstimatesTimer?.invalidate()
        self.updateEstimatesTimer = nil
    }
    
    //MARK: Scene position
    
    class TemporaryAnchor: ARAnchor {
        var completion: ((_ position: SCNVector3?) -> Void)?
        
        init(transform: matrix_float4x4, completion: ((_ position: SCNVector3?) -> Void)?) {
            self.completion = completion
            
            super.init(transform: transform)
        }
    }
    
    func fetchCurrentScenePosition(completion: @escaping (_ position: SCNVector3?) -> Void) {
        if let currentFrame = sceneView.session.currentFrame {
            let translation = matrix_identity_float4x4
            let transform = simd_mul(currentFrame.camera.transform, translation)
            let anchor = TemporaryAnchor(transform: transform, completion: completion)
            
            sceneView.session.add(anchor: anchor)
            
            //This is continued in renderer:didUpdateNode:forAnchor:,
            //where it recognises the anchor, figures out the location and calls completion
        } else {
            completion(nil)
        }
    }
    
    //MARK: Scene location estimates
    
    @objc func updateEstimates() {
        self.removeOldLocationEstimates {
            
        }
    }
    
    ///Adds a scene location estimate based on current time, camera position and location from location manager
    func addSceneLocationEstimate(location: CLLocation, completion: @escaping () -> Void) {
        self.fetchCurrentScenePosition() {
            position in
            if position != nil {
                self.addSceneLocationEstimate(location: location, currentPosition: position!)
            }
            
            completion()
        }
    }
    
    func addSceneLocationEstimate(location: CLLocation, currentPosition: SCNVector3) {
        DDLogDebug("add scene location estimate, position: \(currentPosition), location: \(location.coordinate), accuracy: \(location.horizontalAccuracy), date: \(location.timestamp)")
        
        let sceneLocationEstimate = SceneLocationEstimate(location: location, position: currentPosition)
        self.sceneLocationEstimates.append(sceneLocationEstimate)
    }
    
    func removeOldLocationEstimates(completion: @escaping () -> Void) {
        self.fetchCurrentScenePosition {
            position in
            if position != nil {
                self.removeOldLocationEstimates(currentPosition: position!)
            }
            
            completion()
        }
    }
    
    func removeOldLocationEstimates(currentPosition: SCNVector3) {
        let currentPoint = CGPoint.pointWithVector(vector: currentPosition)
        
        sceneLocationEstimates = sceneLocationEstimates.filter({
            let point = CGPoint.pointWithVector(vector: $0.position)
            
            let radiusContainsPoint = currentPoint.radiusContainsPoint(radius: CGFloat(SceneLocationView.sceneLimit), point: point)
            
            if !radiusContainsPoint {
                DDLogDebug("remove scene location estimate, position: \($0.position), location: \($0.location.coordinate), accuracy: \($0.location.horizontalAccuracy), date: \($0.location.timestamp)")
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
    
    func fetchCurrentLocation(completion: @escaping (_ location: CLLocation?) -> Void) {
        if let bestEstimate = self.bestLocationEstimate() {
            fetchCurrentScenePosition(completion: {
                (position) in
                if position == nil {
                    completion(nil)
                    return
                }
                
                let translation = LocationTranslation(
                    latitudeTranslation: Double(bestEstimate.position.z - position!.z),
                    longitudeTranslation: Double(position!.x - bestEstimate.position.x))
                
                let translatedLocation = bestEstimate.location.translatedLocation(with: translation)
                
                DDLogDebug("")
                DDLogDebug("Fetch current location")
                DDLogDebug("best location estimate, position: \(bestEstimate.position), location: \(bestEstimate.location.coordinate), accuracy: \(bestEstimate.location.horizontalAccuracy), date: \(bestEstimate.location.timestamp)")
                DDLogDebug("current position: \(position!)")
                DDLogDebug("translation: \(translation)")
                DDLogDebug("translated location: \(translatedLocation)")
                DDLogDebug("")
                
                completion(translatedLocation)
            })
        } else {
            completion(nil)
        }
    }
    
    //MARK: ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let temporaryAnchor = anchor as? TemporaryAnchor {
            //Used for determining the current position on the map
            if sceneNode != nil {
                let convertedPosition = sceneView.scene.rootNode.convertPosition(node.position, to: sceneNode)
                
                temporaryAnchor.completion?(convertedPosition)
            } else {
                temporaryAnchor.completion?(nil)
            }
            
            node.removeFromParentNode()
            sceneView.session.remove(anchor: temporaryAnchor)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        if sceneNode == nil,
            let heading = locationManager.heading {
            sceneNode = SCNNode()
            sceneNode!.eulerAngles.y += Float(heading).degreesToRadians
            sceneView.scene.rootNode.addChildNode(sceneNode!)
            
            if displayDebuggingArrow {
                //An axes that points north
                let axesNode = SCNNode.axesNode(quiverLength: 0.1, quiverThickness: 0.5)
                sceneNode!.addChildNode(axesNode)
            }
        }
        
        if !didFetchInitialLocation {
            //Current frame and current location are required for this to be successful
            if sceneView.session.currentFrame != nil,
                let currentLocation = self.locationManager.currentLocation {
                didFetchInitialLocation = true
                
                self.addSceneLocationEstimate(location: currentLocation) {
                    
                }
            }
        }
    }
    
    //MARK: LocationManager
    
    func locationManagerDidUpdateLocation(_ locationManager: LocationManager, location: CLLocation) {
        self.addSceneLocationEstimate(location: location, completion: {

        })
    }
    
    func locationManagerDidUpdateHeading(_ locationManager: LocationManager, heading: CLLocationDirection) {
        
    }
}

extension SCNNode {
    class func axesNode(quiverLength: CGFloat, quiverThickness: CGFloat) -> SCNNode {
        let quiverThickness = (quiverLength / 50.0) * quiverThickness
        let chamferRadius = quiverThickness / 2.0
        
        let xQuiverBox = SCNBox(width: quiverLength, height: quiverThickness, length: quiverThickness, chamferRadius: chamferRadius)
        xQuiverBox.firstMaterial?.diffuse.contents = UIColor.red
        let xQuiverNode = SCNNode(geometry: xQuiverBox)
        xQuiverNode.position = SCNVector3Make(Float(quiverLength / 2.0), 0.0, 0.0)
        
        let yQuiverBox = SCNBox(width: quiverThickness, height: quiverLength, length: quiverThickness, chamferRadius: chamferRadius)
        yQuiverBox.firstMaterial?.diffuse.contents = UIColor.green
        let yQuiverNode = SCNNode(geometry: yQuiverBox)
        yQuiverNode.position = SCNVector3Make(0.0, Float(quiverLength / 2.0), 0.0)
        
        let zQuiverBox = SCNBox(width: quiverThickness, height: quiverThickness, length: quiverLength, chamferRadius: chamferRadius)
        zQuiverBox.firstMaterial?.diffuse.contents = UIColor.blue
        let zQuiverNode = SCNNode(geometry: zQuiverBox)
        zQuiverNode.position = SCNVector3Make(0.0, 0.0, Float(quiverLength / 2.0))
        
        let quiverNode = SCNNode()
        quiverNode.addChildNode(xQuiverNode)
        quiverNode.addChildNode(yQuiverNode)
        quiverNode.addChildNode(zQuiverNode)
        quiverNode.name = "Axes"
        return quiverNode
    }
}
