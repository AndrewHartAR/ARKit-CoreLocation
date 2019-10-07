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
    case fieldOfRadii
    case spriteKitNodes
}

class ARCLViewController: UIViewController {

    @IBOutlet weak var sceneLocationView: SceneLocationView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var sceneXYZLabel: UILabel!
    @IBOutlet weak var estLatLonLabel: UILabel!
    
    @IBOutlet weak var estXYZLabel: UILabel!
    @IBOutlet weak var estHeadingLabel: UILabel!
    var demonstration = Demonstration.fieldOfNodes
    let colors = [UIColor.systemGreen, UIColor.systemBlue, UIColor.systemOrange, UIColor.systemRed, UIColor.systemYellow, UIColor.systemPurple]
    let northingIncrementMeters = 75.0
    let eastingIncrementMeters = 75.0

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
        print("scene", sceneLocationView.scene.debugDescription)
        print("delegate", sceneLocationView.delegate.debugDescription)
        print("arViewDelegate", sceneLocationView.arViewDelegate.debugDescription)
        print("sceneTrackingDelegate", sceneLocationView.sceneTrackingDelegate.debugDescription)
        print("locationNodeTouchDelegate", sceneLocationView.locationNodeTouchDelegate.debugDescription)

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
        case .fieldOfRadii:
            addFieldOfRadii()
        case .spriteKitNodes:
            addSpriteKitNodes()
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
            node.annotationHeightAdjustmentFactor = 0.0
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
        let rotateForeverAction = SCNAction.repeatForever(SCNAction.rotate(by: .pi, around: SCNVector3(1, 0, 0), duration: 3))
        var colorIndex = 0
        for northStep in -5...5 {
            let color = colors[colorIndex % colors.count]
            colorIndex += 1
            for eastStep in -5...5 {
                let location = referenceLocation.translatedLocation(with: LocationTranslation(latitudeTranslation: Double(northStep) * northingIncrementMeters, longitudeTranslation: Double(eastStep) * eastingIncrementMeters, altitudeTranslation: 0.0))
                let locationeNode = LocationNode(location: location)
                let torus = SCNTorus(ringRadius: 10, pipeRadius: 2)
                torus.firstMaterial?.diffuse.contents = color
                let torusNode = SCNNode(geometry: torus)
                torusNode.runAction(rotateForeverAction)
                locationeNode.addChildNode(torusNode)
                sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: locationeNode)
            }
        }
    }

    /// Add an array of annotation nodes centered on your current location. Labels are static.
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
        var colorIndex = 0
        for northStep in -5...5 {
            let color = colors[colorIndex % colors.count]
            colorIndex += 1
            for eastStep in -5...5 {
                let northOffset = Double(northStep) * northingIncrementMeters
                let eastOffset = Double(eastStep) * eastingIncrementMeters
                let location = referenceLocation.translatedLocation(with: LocationTranslation(latitudeTranslation: northOffset, longitudeTranslation: eastOffset, altitudeTranslation: 0.0))
                let radius = Int(sqrt (northOffset * northOffset + eastOffset * eastOffset))
                let label = UILabel.largeLabel(text: "\(northStep), \(eastStep) (\(radius))")
                label.backgroundColor = color
                let annoNode = LocationAnnotationNode(location: location, view: label)
                sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annoNode)
            }
        }
    }


    func addSpriteKitNodes() {
        // Don't try to add the nodes to the scene until we have a current location
        guard sceneLocationView.sceneLocationManager.currentLocation != nil else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.addSpriteKitNodes()
            }
            return
        }

        let referenceLocation = CLLocation(coordinate:sceneLocationView.sceneLocationManager.currentLocation!.coordinate,
                                           altitude: sceneLocationView.sceneLocationManager.currentLocation!.altitude)

        // Put a label at the origin.
        let north10Meterslabel = UILabel.largeLabel(text: "North 10 meters")
        north10Meterslabel.backgroundColor = .systemTeal
        let north10MetersLocation = referenceLocation.translatedLocation(with: LocationTranslation(latitudeTranslation: 10.0, longitudeTranslation: 0.0, altitudeTranslation: 0.0))
        let north10MetersLabelNode = LocationAnnotationNode(location: north10MetersLocation, view: north10Meterslabel)
        sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: north10MetersLabelNode)

        let south10Meterslabel = UILabel.largeLabel(text: "South 10 meters")
        south10Meterslabel.backgroundColor = .systemPurple
        let south10MetersLocation = referenceLocation.translatedLocation(with: LocationTranslation(latitudeTranslation: -10.0, longitudeTranslation: 0.0, altitudeTranslation: 0.0))
        let south10MetersLabelNode = LocationAnnotationNode(location: south10MetersLocation, view: south10Meterslabel)
        sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: south10MetersLabelNode)

        let east10MetersLocation = referenceLocation.translatedLocation(with: LocationTranslation(latitudeTranslation: 0.0, longitudeTranslation: 10.0, altitudeTranslation: 0.0))
        let east10MetersLabelNode = LocationNode(location: east10MetersLocation)
        sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: south10MetersLabelNode)

        //SKScene to hold 2D elements that get put onto a plane, then added to the SCNScene
        let skScene = SKScene(size:CGSize(width: 500, height: 52  ))
        skScene.backgroundColor = SKColor(white:0,alpha:0)

        //create red box around the SKScene
        let shape = SKShapeNode(rect: CGRect(x: 0, y: 0, width: skScene.frame.size.width, height: skScene.frame.size.height))
        shape.strokeColor = SKColor.red
        shape.lineWidth = 1
        skScene.addChild(shape)

        //the label we can update anytime we want
        let label = SKLabelNode(fontNamed:"Menlo-Bold")
        label.fontSize = 48
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x:0,y:skScene.frame.size.height/2)
        label.text = "HELLO WORLD!"
        skScene.addChild(label)

        //create a plane to put the skScene on
        let plane = SCNPlane(width:5,height:0.5)
        let material = SCNMaterial()
        material.lightingModel = SCNMaterial.LightingModel.constant
        material.isDoubleSided = true
        material.diffuse.contents = skScene
        plane.materials = [material]

        //Add plane to a node, and node to the SCNScene
        let hudNode = SCNNode(geometry: plane)
        hudNode.name = "HUD"
        hudNode.rotation = SCNVector4(x: 1, y: 0, z: 0, w: 3.14159265)
        hudNode.position = SCNVector3(x:0, y: 1.5, z: 1)
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        hudNode.constraints = [billboardConstraint]
        east10MetersLabelNode.addChildNode(hudNode)

  /*      SKSpriteNode *someSKSpriteNode;

        // initialize your SKSpriteNode and set it up..

        SKScene *tvSKScene = [SKScene sceneWithSize:CGSizeMake(100, 100)];
        tvSKScene.anchorPoint = CGPointMake(0.5, 0.5);
        [tvSKScene addChild:someSKSpriteNode];

        // use spritekit scene as plane's material

        SCNMaterial *materialProperty = [SCNMaterial material];
        materialProperty.diffuse.contents = tvSKScene;

        // this will likely change to whereever you want to show this scene.
        SCNVector3 tvLocationCoordinates = SCNVector3Make(0, 0, 0);

        SCNPlane *scnPlane = [SCNPlane planeWithWidth:100.0 height:100.0];
        SCNNode *scnNode = [SCNNode nodeWithGeometry:scnPlane];
        scnNode.geometry.firstMaterial = materialProperty;
        scnNode.position = tvLocationCoordinates;

        // Assume we have a SCNCamera and SCNNode set up already.

        SCNLookAtConstraint *constraint = [SCNLookAtConstraint lookAtConstraintWithTarget:cameraNode];
        constraint.gimbalLockEnabled = NO;
        scnNode.constraints = @[constraint];

        // Assume we have a SCNView *sceneView set up already.
        [sceneView.scene.rootNode addChildNode:scnNode];
*/
    }

    /// Add an array of annotation nodes centered on your current location. Radius values are updated live.
    func addFieldOfRadii() {
        // Don't try to add the nodes to the scene until we have a current location
        guard sceneLocationView.sceneLocationManager.currentLocation != nil else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.addFieldOfRadii()
            }
            return
        }

        let referenceLocation = CLLocation(coordinate:sceneLocationView.sceneLocationManager.currentLocation!.coordinate,
                                           altitude: sceneLocationView.sceneLocationManager.currentLocation!.altitude)
        for northStep in -5...5 {
            for eastStep in -5...5 {
                let northOffset = Double(northStep) * 2.0
                let eastOffset = Double(eastStep) * 2.0
                let location = referenceLocation.translatedLocation(with: LocationTranslation(latitudeTranslation: northOffset, longitudeTranslation: eastOffset, altitudeTranslation: 0))
                let radius = Int(sqrt (northOffset * northOffset + eastOffset * eastOffset))
                let label = UILabel.largeLabel(text: "(\(radius))")
                label.backgroundColor = .systemTeal
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
    // These functions defined in SCNSceneRendererDelegate are invoked on the arViewDelegate within ARCL's
    // internal SCNSceneRendererDelegate (akak ARSCNViewDelegate). They're forwarded versions of the
    // SCNSceneRendererDelegate calls.
    
    public func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        DispatchQueue.main.async {
            if let position = self.sceneLocationView.currentScenePosition {
            self.sceneXYZLabel.text = "SLV x: \(position.x.short), y: \(position.y.short), z: \(position.z.short)"
        }
        else {
            self.sceneXYZLabel.text = ""
        }
            if let locationEstimate = self.sceneLocationView.sceneLocationManager.bestLocationEstimate {
                self.estXYZLabel.text = "LM x: \(locationEstimate.position.x.short) y: \(locationEstimate.position.y.short) z: \(locationEstimate.position.z.short)"
                let coordinate = locationEstimate.location.coordinate
                let latString = String(format: "%+7.5f", coordinate.latitude)
                let lonString = String(format: "%+7.5f", coordinate.longitude)
                self.estLatLonLabel.text = "LM \(latString) \(lonString)"
                if let heading = self.sceneLocationView.sceneLocationManager.locationManager.heading,
                    let headingAccuracy = self.sceneLocationView.sceneLocationManager.locationManager.headingAccuracy {
                    let headingString = String(format: "%4.1f", heading)
                    let headingAccuracyString = String(format: "%3.1f", headingAccuracy)
                    self.estHeadingLabel.text = "LM heading \(headingString)° +/- \(headingAccuracyString)°"
                }
            }
//            if let eulerAngles = sceneLocationView.currentEulerAngles,
//                let heading = sceneLocationView.sceneLocationManager.locationManager.heading,
//                let headingAccuracy = sceneLocationView.sceneLocationManager.locationManager.headingAccuracy {
//                let yDegrees = (((0 - eulerAngles.y.radiansToDegrees) + 360).truncatingRemainder(dividingBy: 360) ).short
//                infoLabel.text!.append(" Heading: \(yDegrees)° • \(Float(heading).short)° • \(headingAccuracy)°\n")
//            }
//
//            let comp = Calendar.current.dateComponents([.hour, .minute, .second, .nanosecond], from: Date())
//            if let hour = comp.hour, let minute = comp.minute, let second = comp.second, let nanosecond = comp.nanosecond {
//                let nodeCount = "\(sceneLocationView.sceneNode?.childNodes.count.description ?? "n/a") ARKit Nodes"
//                infoLabel.text!.append(" \(hour.short):\(minute.short):\(second.short):\(nanosecond.short3) • \(nodeCount)")
//            }
//        }
        }
    }

    public func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if self.demonstration == .fieldOfRadii {
            if let renderer = renderer as? SceneLocationView {
                let location = sceneLocationView.sceneLocationManager.currentLocation
                if let locationNodes = renderer.locationNodes as? [LocationAnnotationNode] {
                    for node in locationNodes {
                        DispatchQueue.main.async {
                            // FIXME: This approach won't work because the underlying SCNPlane has its material set only once, at init time. Leaving it for future inspiration.
                            let radius = Int(location?.distance(from: node.location) ?? 0)
                            let label = UILabel.largeLabel(text: "(\(radius))")
                            label.backgroundColor = UIColor.systemTeal
                            node.annotationNode.image = label.image
                        }                    }
                }
            }
        }
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

