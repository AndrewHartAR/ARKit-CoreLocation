//
//  ARCLViewController.swift
//  Node Demos
//
//  Created by Hal Mueller on 9/29/19.
//  Copyright © 2019 Project Dent. All rights reserved.
//

import ARCL
import ARKit
import MapKit
import SceneKit
import UIKit

class ARCLViewController: UIViewController {

    let sceneLocationView = SceneLocationView()

    @IBOutlet weak var contentView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sceneLocationView.translatesAutoresizingMaskIntoConstraints = false
        sceneLocationView.frame = contentView.frame
        sceneLocationView.arViewDelegate = self

        sceneLocationView.debugOptions = .showWorldOrigin
        sceneLocationView.showsStatistics = true
        sceneLocationView.showAxesNode = false // don't need ARCL's axesNode because we're showing SceneKit's
        sceneLocationView.autoenablesDefaultLighting = true
        
        contentView.addSubview(sceneLocationView)
        print("scene", sceneLocationView.scene)
        print("delegate", sceneLocationView.delegate)
        print("arViewDelegate", sceneLocationView.arViewDelegate)
        print("sceneTrackingDelegate", sceneLocationView.sceneTrackingDelegate)
        print("locationNodeTouchDelegate", sceneLocationView.locationNodeTouchDelegate)

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        addDemoNodes()
        sceneLocationView.run()
    }

    override func viewWillDisappear(_ animated: Bool) {
        sceneLocationView.removeAllNodes()
        sceneLocationView.pause()
        super.viewWillDisappear(animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sceneLocationView.frame = contentView.bounds
    }

    @IBAction func doneTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    /// Add a stack of nodes, 100 meters north of location, at altitudes of 0-100 meters by 20s.
    func addDemoNodes() {
        // 1. Don't try to add the models to the scene until we have a current location
        guard sceneLocationView.sceneLocationManager.currentLocation != nil else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.addDemoNodes()
            }
            return
        }
        print(sceneLocationView.sceneLocationManager.currentLocation)
        let referenceLocation = sceneLocationView.sceneLocationManager.currentLocation!
        let cubeSide = CGFloat(5)
        for altitude in [0.0, 20, 60, 100] {
            let location = referenceLocation.translatedLocation(with: LocationTranslation(latitudeTranslation: 100.0, longitudeTranslation: 0.0, altitudeTranslation: altitude))
            let node = buildDisplacedAnnotationViewNode(altitude: altitude, location: location)
            sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: node)

            let cubeNode = LocationNode(location: location)
            let cube = SCNBox(width: cubeSide, height: cubeSide, length: cubeSide, chamferRadius: 0)
            cube.firstMaterial?.diffuse.contents = UIColor.systemOrange
            cubeNode.addChildNode(SCNNode(geometry: cube))
            sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: cubeNode)
        }
        // origin node
        let text = "Starting point"
        let font = UIFont.preferredFont(forTextStyle: .title2)
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = (text as NSString).size(withAttributes: fontAttributes)
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let attributedQuote = NSAttributedString(string: text, attributes:  [NSAttributedString.Key.font: font])
        label.attributedText = attributedQuote
        label.textAlignment = .center
        label.backgroundColor = UIColor.systemTeal
        label.adjustsFontForContentSizeCategory = true
        let originLabelNode = LocationAnnotationNode(location: referenceLocation, view: label)
        originLabelNode.ignoreAltitude = false
        sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: originLabelNode)

    }

    func buildDisplacedAnnotationViewNode(altitude: Double, location: CLLocation) -> LocationAnnotationNode {
        let text = "\(altitude)"
        let font = UIFont.preferredFont(forTextStyle: .title2)
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = (text as NSString).size(withAttributes: fontAttributes)
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))

        let attributedQuote = NSAttributedString(string: text, attributes:  [NSAttributedString.Key.font: font])
        label.attributedText = attributedQuote
        label.textAlignment = .center
        label.backgroundColor = UIColor.systemGray
        label.adjustsFontForContentSizeCategory = true

        let result = LocationAnnotationNode(location: location, view: label)
        result.ignoreAltitude = false

        return result
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

// MARK: - ARSCNViewDelegate
extension ARCLViewController: ARSCNViewDelegate {

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // print(#file, #function)
    }

    func renderer(_ renderer: SCNSceneRenderer, willUpdate node: SCNNode, for anchor: ARAnchor) {
        // print(#file, #function)
    }

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        // print(#file, #function)
    }

    // MARK: - SCNSceneRendererDelegate
    // These functions defined in SCNSceneRendererDelegate are invoked on the arViewDelegate within ARCL's internal SCNSceneRendererDelegate (akak ARSCNViewDelegate).
    
    public func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        // print(#file, #function)
    }

    public func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // print(#file, #function)
    }

    public func renderer(_ renderer: SCNSceneRenderer, didApplyAnimationsAtTime time: TimeInterval) {
        // print(#file, #function)
    }

    public func renderer(_ renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: TimeInterval) {
        // print(#file, #function)
    }

    public func renderer(_ renderer: SCNSceneRenderer, didApplyConstraintsAtTime time: TimeInterval) {
        // print(#file, #function)
    }

    public func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        // print(#file, #function)
    }

}
