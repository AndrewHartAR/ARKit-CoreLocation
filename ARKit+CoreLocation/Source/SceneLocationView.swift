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
    private let sceneView = ARSCNView()
    
    private let locationManager = LocationManager()
    
    private(set) var sceneAnnotations = [SceneAnnotation]()
    
    private var sceneAnchor: SceneAnchor?
    
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
    
    func run() {
        // Create a session configuration
        let configuration = ARWorldTrackingSessionConfiguration()
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    func pause() {
        sceneView.session.pause()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        sceneView.frame = self.bounds
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
    
    //MARK: ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let sceneAnchor = anchor as? SceneAnchor {
            if let heading = self.locationManager.heading {
                print("did update node for scene anchor")
                node.eulerAngles.x -= Float(heading).degreesToRadians
                node.eulerAngles.y = 0
                node.eulerAngles.z = 0 - (Float.pi/2)
                
                //An arrow that points north
//                let scene = SCNScene(named: "art.scnassets/arrow.dae")!
//                let arrowNode = scene.rootNode.childNode(withName: "SketchUp", recursively: true)!
//                arrowNode.scale = SCNVector3(x: 0.01, y: 0.01, z: 0.01)
//                arrowNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
//                node.addChildNode(arrowNode)
                
                sceneAnchor.node = node
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        if sceneAnchor == nil {
            self.setupSceneAnchor()
        }
    }
    
    //MARK: LocationManager
    
    func locationManagerDidUpdateLocation(_ locationManager: LocationManager, location: CLLocation) {
        
    }
    
    func locationManagerDidUpdateHeading(_ locationManager: LocationManager, heading: CLLocationDirection) {
        
    }
}
