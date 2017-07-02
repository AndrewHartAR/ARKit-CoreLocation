//
//  SceneLocationView.swift
//  ARKit+CoreLocation
//
//  Created by Andrew Hart on 02/07/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import Foundation
import ARKit

class SceneLocationView: UIView, ARSCNViewDelegate {
    private let sceneView = ARSCNView()
    
    //MARK: Setup
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.red
        
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
    
    //MARK: ARSCNViewDelegate
}
