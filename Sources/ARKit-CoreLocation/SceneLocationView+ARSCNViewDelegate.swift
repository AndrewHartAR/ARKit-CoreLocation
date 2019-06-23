//
//  SceneLocationView+ARSCNViewDelegate.swift
//  ARKit+CoreLocation
//
//  Created by Ilya Seliverstov on 08/08/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import Foundation
import ARKit
import CoreLocation
import MapKit

// MARK: - ARSCNViewDelegate

@available(iOS 11.0, *)
extension SceneLocationView: ARSCNViewDelegate {

    public func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        return arViewDelegate?.renderer?(renderer, nodeFor: anchor) ?? nil
    }

    public func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        arViewDelegate?.renderer?(renderer, didAdd: node, for: anchor)
    }

    public func renderer(_ renderer: SCNSceneRenderer, willUpdate node: SCNNode, for anchor: ARAnchor) {
        arViewDelegate?.renderer?(renderer, willUpdate: node, for: anchor)
    }

    public func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        arViewDelegate?.renderer?(renderer, didUpdate: node, for: anchor)
    }

    public func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        arViewDelegate?.renderer?(renderer, didRemove: node, for: anchor)
    }

}

// MARK: - ARSessionObserver

@available(iOS 11.0, *)
extension SceneLocationView {

    public func session(_ session: ARSession, didFailWithError error: Error) {
        defer {
            arViewDelegate?.session?(session, didFailWithError: error)
        }
        print("session did fail with error: \(error)")
        sceneTrackingDelegate?.session(session, didFailWithError: error)
    }

    public func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        defer {
            arViewDelegate?.session?(session, cameraDidChangeTrackingState: camera)
        }
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
        default:
            print("camera did change tracking state: unknown...")
        }
        sceneTrackingDelegate?.session(session, cameraDidChangeTrackingState: camera)
    }

    public func sessionWasInterrupted(_ session: ARSession) {
        defer {
            arViewDelegate?.sessionWasInterrupted?(session)
        }
        print("session was interrupted")
        sceneTrackingDelegate?.sessionWasInterrupted(session)
    }

    public func sessionInterruptionEnded(_ session: ARSession) {
        defer {
            arViewDelegate?.sessionInterruptionEnded?(session)
        }
        print("session interruption ended")
        sceneTrackingDelegate?.sessionInterruptionEnded(session)
    }

    @available(iOS 11.3, *)
    public func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return arViewDelegate?.sessionShouldAttemptRelocalization?(session) ?? true
    }

    public func session(_ session: ARSession, didOutputAudioSampleBuffer audioSampleBuffer: CMSampleBuffer) {
        arViewDelegate?.session?(session, didOutputAudioSampleBuffer: audioSampleBuffer)
    }

}

// MARK: - SCNSceneRendererDelegate

@available(iOS 11.0, *)
extension SceneLocationView {

    public func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        defer {
            arViewDelegate?.renderer?(renderer, didRenderScene: scene, atTime: time)
        }
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

    public func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        arViewDelegate?.renderer?(renderer, updateAtTime: time)
    }

    public func renderer(_ renderer: SCNSceneRenderer, didApplyAnimationsAtTime time: TimeInterval) {
        arViewDelegate?.renderer?(renderer, didApplyAnimationsAtTime: time)
    }

    public func renderer(_ renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: TimeInterval) {
        arViewDelegate?.renderer?(renderer, didSimulatePhysicsAtTime: time)
    }

    public func renderer(_ renderer: SCNSceneRenderer, didApplyConstraintsAtTime time: TimeInterval) {
        arViewDelegate?.renderer?(renderer, didApplyConstraintsAtTime: time)
    }

    public func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        arViewDelegate?.renderer?(renderer, willRenderScene: scene, atTime: time)
    }
}
