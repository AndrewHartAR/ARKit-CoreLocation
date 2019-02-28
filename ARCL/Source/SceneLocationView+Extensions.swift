//
//  SceneLocationView+Extensions.swift
//  ARKit+CoreLocation
//
//  Created by Ilya Seliverstov on 08/08/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import Foundation
import ARKit
import CoreLocation
import MapKit

@available(iOS 11.0, *)
extension SceneLocationView: ARSCNViewDelegate {

    @objc
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
        case .limited(.relocalizing):
            print("camera did change tracking state: limited, relocalizing")
        }
    }
}
