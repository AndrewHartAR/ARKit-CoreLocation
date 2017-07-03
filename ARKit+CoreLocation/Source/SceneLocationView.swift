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

fileprivate class SceneAnchor: ARAnchor {
    var node: SCNNode?
}

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
    
    private var sceneAnchor: SceneAnchor?
    
    private var updateEstimatesTimer: Timer?
    
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
    
    func setupSceneAnchor() {
        //Heading will be required to setup the node properly
        if let currentFrame = self.sceneView.session.currentFrame,
            self.locationManager.heading != nil {
            let translation = matrix_identity_float4x4
            let transform = simd_mul(currentFrame.camera.transform, translation)
            self.sceneAnchor = SceneAnchor(transform: transform)
            
            //Add anchor to scene view
            self.sceneView.session.add(anchor: self.sceneAnchor!)
        }
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
        print("add scene location estimate: \(currentPosition)")
        let sceneLocationEstimate = SceneLocationEstimate(location: location, position: currentPosition, date: Date())
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
            
            return radiusContainsPoint
        })
    }
    
    func currentLocation(completion: @escaping (_ location: CLLocation?) -> Void) {
        let sortedLocationEstimates = sceneLocationEstimates.sorted(by: {
            if $0.location.horizontalAccuracy == $1.location.horizontalAccuracy {
                return $0.date > $1.date
            }
            
            return $0.location.horizontalAccuracy < $1.location.horizontalAccuracy
        })
        
        if let bestEstimate = sortedLocationEstimates.first {
            fetchCurrentScenePosition(completion: {
                (position) in
                if position == nil {
                    completion(nil)
                    return
                }
                
                let translation = LocationTranslation(
                    latitudeTranslation: Double(bestEstimate.position.z - position!.z),
                    longitudeTranslation: Double(bestEstimate.position.x + position!.x))
                
                let translatedLocation = bestEstimate.location.translatedLocation(with: translation)
                
                completion(translatedLocation)
            })
        } else {
            completion(nil)
        }
    }
    
    //MARK: ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let sceneAnchor = anchor as? SceneAnchor {
            if sceneAnchor.node == nil,
                let heading = self.locationManager.heading {
                print("did update node for scene anchor")
                node.eulerAngles.x -= Float(heading).degreesToRadians
                node.eulerAngles.y = 0
                node.eulerAngles.z = 0 - (Float.pi/2)
                
                if displayDebuggingArrow {
                    //An arrow that points north
                    let scene = SCNScene(named: "art.scnassets/arrow.dae")!
                    let arrowNode = scene.rootNode.childNode(withName: "SketchUp", recursively: true)!
                    arrowNode.scale = SCNVector3(x: 0.01, y: 0.01, z: 0.01)
                    arrowNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                    node.addChildNode(arrowNode)
                }
                
                sceneAnchor.node = node
            }
        } else if let temporaryAnchor = anchor as? TemporaryAnchor {
            //Used for determining the current position on the map
            if let sceneNode = sceneAnchor?.node {
                let convertedPosition = sceneNode.convertPosition(node.position, to: sceneNode)
                
                temporaryAnchor.completion?(convertedPosition)
            } else {
                temporaryAnchor.completion?(nil)
            }
            
            node.removeFromParentNode()
            sceneView.session.remove(anchor: temporaryAnchor)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        if sceneAnchor == nil {
            self.setupSceneAnchor()
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
