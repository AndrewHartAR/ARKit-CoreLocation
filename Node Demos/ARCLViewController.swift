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

enum Demonstration {
    case stackOfNodes
    case fieldOfNodes
    case fieldOfLabels
}

class ARCLViewController: UIViewController {

    let sceneLocationView = SceneLocationView()
    var demonstration = Demonstration.fieldOfNodes

    @IBOutlet weak var contentView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sceneLocationView.translatesAutoresizingMaskIntoConstraints = false
        sceneLocationView.frame = contentView.frame
        sceneLocationView.arViewDelegate = self

        sceneLocationView.debugOptions = [.showWorldOrigin]
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
        switch demonstration {
        case .stackOfNodes:
            addStackOfNodes()
        case .fieldOfNodes:
            addFieldOfNodes()
        case .fieldOfLabels:
                addFieldOfLabels()
        }
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
    
    /// Add a stack of annotation nodes, 100 meters north of location, at altitudes between 0 and 100 meters.
    /// Also add a location node at the same place as each annotation node.
    func addStackOfNodes() {
        // 1. Don't try to add the models to the scene until we have a current location
        guard sceneLocationView.sceneLocationManager.currentLocation != nil else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.addStackOfNodes()
            }
            return
        }

        let referenceLocation = CLLocation(coordinate:sceneLocationView.sceneLocationManager.currentLocation!.coordinate,
                                           altitude: sceneLocationView.sceneLocationManager.currentLocation!.altitude)
        for altitude in [0.0, 20, 60, 100] {
            // Create one annotation node 100 meters north, at specified altitude.
            let location = referenceLocation.translatedLocation(with: LocationTranslation(latitudeTranslation: 100.0, longitudeTranslation: 0.0, altitudeTranslation: altitude))
            let node = buildDisplacedAnnotationViewNode(altitude: altitude, location: location)
            sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: node)

            // Now create a plain old geometry node at the same location.
            let cubeNode = LocationNode(location: location)
            let cubeSide = CGFloat(5)
            let cube = SCNBox(width: cubeSide, height: cubeSide, length: cubeSide, chamferRadius: 0)
            cube.firstMaterial?.diffuse.contents = UIColor.systemOrange
            cubeNode.addChildNode(SCNNode(geometry: cube))
            sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: cubeNode)
        }
        // Put a label at the origin.
        let label = UILabel.largeLabel(text: "Starting point")
        label.backgroundColor = .systemTeal
        let startingPoint = CLLocation(coordinate: referenceLocation.coordinate, altitude: referenceLocation.altitude)
        let originLabelNode = LocationAnnotationNode(location: startingPoint, view: label)
        sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: originLabelNode)
    }

    /// Create a `LocationAnnotationNode` at `altitude` meters above the given location, labeled with the altitude.
    func buildDisplacedAnnotationViewNode(altitude: Double, location: CLLocation) -> LocationAnnotationNode {
        let label = UILabel.largeLabel(text: "\(altitude)")
        let result = LocationAnnotationNode(location: location, view: label)
        return result
    }

    /// Add an array of SNCSphere nodes centered on your current location.
    func addFieldOfNodes() {
        // Don't try to add the nodes to the scene until we have a current location
        guard sceneLocationView.sceneLocationManager.currentLocation != nil else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.addFieldOfNodes()
            }
            return
        }

        let referenceLocation = CLLocation(coordinate:sceneLocationView.sceneLocationManager.currentLocation!.coordinate,
                                           altitude: sceneLocationView.sceneLocationManager.currentLocation!.altitude)
        let colors = [UIColor.systemGreen, UIColor.systemBlue, UIColor.systemOrange, UIColor.systemRed, UIColor.systemYellow, UIColor.systemPurple]
        var colorIndex = 0
        for northStep in -5...5 {
            let color = colors[colorIndex % colors.count]
            colorIndex += 1
            for eastStep in -5...5 {
                let location = referenceLocation.translatedLocation(with: LocationTranslation(latitudeTranslation: Double(northStep) * 200.0, longitudeTranslation: Double(eastStep) * 200.0, altitudeTranslation: referenceLocation.altitude))
                let sphereNode = LocationNode(location: location)
                let sphere = SCNSphere(radius: 10.0)
                sphere.firstMaterial?.diffuse.contents = color
                sphereNode.addChildNode(SCNNode(geometry: sphere))
                sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: sphereNode)
            }
        }
    }

    /// Add an array of annotation nodes centered on your current location.
    func addFieldOfLabels() {
        // Don't try to add the nodes to the scene until we have a current location
        guard sceneLocationView.sceneLocationManager.currentLocation != nil else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.addFieldOfLabels()
            }
            return
        }

        let referenceLocation = CLLocation(coordinate:sceneLocationView.sceneLocationManager.currentLocation!.coordinate,
                                           altitude: sceneLocationView.sceneLocationManager.currentLocation!.altitude)
        let colors = [UIColor.systemGreen, UIColor.systemBlue, UIColor.systemOrange, UIColor.systemRed, UIColor.systemYellow, UIColor.systemPurple]
        var colorIndex = 0
        for northStep in -5...5 {
            let color = colors[colorIndex % colors.count]
            colorIndex += 1
            for eastStep in -5...5 {
                let northOffset = Double(northStep) * 200.0
                let eastOffset = Double(eastStep) * 200.0
                let location = referenceLocation.translatedLocation(with: LocationTranslation(latitudeTranslation: northOffset, longitudeTranslation: eastOffset, altitudeTranslation: referenceLocation.altitude))
                let radius = Int(sqrt (northOffset * northOffset + eastOffset * eastOffset))
                let label = UILabel.largeLabel(text: "\(northStep), \(eastStep) (\(radius))")
                label.backgroundColor = color
                let annoNode = LocationAnnotationNode(location: location, view: label)
                sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annoNode)
            }
        }
    }
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

extension UILabel {
    class func largeLabel(text: String) -> UILabel {
        let font = UIFont.preferredFont(forTextStyle: .title2)
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = (text as NSString).size(withAttributes: fontAttributes)
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))

        let attributedQuote = NSAttributedString(string: text, attributes:  [NSAttributedString.Key.font: font])
        label.attributedText = attributedQuote
        label.textAlignment = .center
        label.backgroundColor = UIColor.systemGray
        label.adjustsFontForContentSizeCategory = true
        return label
    }


}

