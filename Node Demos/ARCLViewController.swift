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
        sceneLocationView.showAxesNode = true
        contentView.addSubview(sceneLocationView)
        print("scene", sceneLocationView.scene)
        print("delegate", sceneLocationView.delegate)
        print("arViewDelegate", sceneLocationView.arViewDelegate)
        print("sceneTrackingDelegate", sceneLocationView.sceneTrackingDelegate)
        print("locationNodeTouchDelegate", sceneLocationView.locationNodeTouchDelegate)

        addSceneModels()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sceneLocationView.run()
    }

    override func viewWillDisappear(_ animated: Bool) {
        sceneLocationView.pause()
        super.viewWillDisappear(animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sceneLocationView.frame = contentView.bounds
    }

    /// Add a stack of nodes, 100 meters north of location, at altitudes of 0-100 meters by 20s.
    func addSceneModels() {
        // 1. Don't try to add the models to the scene until we have a current location
        guard sceneLocationView.sceneLocationManager.currentLocation != nil else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.addSceneModels()
            }
            return
        }
        print(sceneLocationView.sceneLocationManager.currentLocation)
        for altitude in [0.0, 20, 40, 60, 80, 100] {
            let node = buildViewNode(altitude: altitude, referenceLocation: sceneLocationView.sceneLocationManager.currentLocation!)
            sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: node)
        }
    }

    func buildViewNode(altitude: Double, referenceLocation: CLLocation) -> LocationAnnotationNode {
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

        let location = referenceLocation.translatedLocation(with: LocationTranslation(latitudeTranslation: 100.0, longitudeTranslation: 0.0, altitudeTranslation: altitude))
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
