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
    case justOneNode
    case stackOfNodes
    case fieldOfNodes
    case fieldOfLabels
    case fieldOfRadii
    case spriteKitNodes
}

class ARCLViewController: UIViewController {

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var sceneXYZLabel: UILabel!
    @IBOutlet weak var estLatLonLabel: UILabel!
    @IBOutlet weak var estXYZLabel: UILabel!
    @IBOutlet weak var estHeadingLabel: UILabel!

    var sceneLocationView: SceneLocationView?
    public var demonstration = Demonstration.fieldOfNodes

    /// This is for the `SceneLocationView`. There's no way to set a node's `locationEstimateMethod`, which is hardcoded to `mostRelevantEstimate`.
    public var locationEstimateMethod = LocationEstimateMethod.mostRelevantEstimate

    public var arTrackingType = SceneLocationView.ARTrackingType.orientationTracking
    public var scalingScheme = ScalingScheme.normal

    // These three properties are properties of individual nodes. We'll set them the same way for each node added.
    public var continuallyAdjustNodePositionWhenWithinRange = true
    public var continuallyUpdatePositionAndScale = true
    public var annotationHeightAdjustmentFactor = 1.1

    let colors = [UIColor.systemGreen, UIColor.systemBlue, UIColor.systemOrange, UIColor.systemPurple, UIColor.systemYellow, UIColor.systemRed]
    let northingIncrementMeters = 100.0
    let eastingIncrementMeters = 75.0

    // MARK: - Lifecycle and actions

    override func viewDidLoad() {
        super.viewDidLoad()

        sceneXYZLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: UIFont.Weight.medium)
        estLatLonLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: UIFont.Weight.medium)
        estXYZLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: UIFont.Weight.medium)
        estHeadingLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: UIFont.Weight.medium)
    }

    func rebuildSceneLocationView() {
        sceneLocationView?.removeFromSuperview()
        let newSceneLocationView = SceneLocationView.init(trackingType: arTrackingType, frame: contentView.frame, options: nil)
        newSceneLocationView.translatesAutoresizingMaskIntoConstraints = false
        newSceneLocationView.arViewDelegate = self
        newSceneLocationView.locationEstimateMethod = locationEstimateMethod

        newSceneLocationView.debugOptions = [.showWorldOrigin]
        newSceneLocationView.showsStatistics = true
        newSceneLocationView.showAxesNode = false // don't need ARCL's axesNode because we're showing SceneKit's
        newSceneLocationView.autoenablesDefaultLighting = true
        contentView.addSubview(newSceneLocationView)
        sceneLocationView = newSceneLocationView
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        rebuildSceneLocationView()
        switch demonstration {
        case .justOneNode:
            addJustOneNode()
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
        sceneLocationView?.run()
    }

    override func viewWillDisappear(_ animated: Bool) {
        sceneLocationView?.removeAllNodes()
        sceneLocationView?.pause()
        super.viewWillDisappear(animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sceneLocationView?.frame = contentView.bounds
    }

    @IBAction func doneTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Some canned demos

    /// Perform these actions on every node after it's added.
    func addScenewideNodeSettings(_ node: LocationNode) {
        if let annoNode = node as? LocationAnnotationNode {
            annoNode.annotationHeightAdjustmentFactor = annotationHeightAdjustmentFactor
        }
        node.scalingScheme = scalingScheme
        // FIXME: We should be able to do this, or do it internally in addLocationNode...() calls, to match SceneLocationView's setting.
        // node.locationEstimateMethod = locationEstimateMethod
        node.continuallyAdjustNodePositionWhenWithinRange = continuallyAdjustNodePositionWhenWithinRange
        node.continuallyUpdatePositionAndScale = continuallyUpdatePositionAndScale
    }

    /// Add one node, at our current location.
    func addJustOneNode() {
        guard let currentLocation = sceneLocationView?.sceneLocationManager.currentLocation else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.addJustOneNode()
            }
            return
        }

        // Copy the current location because it's a reference type. Necessary?
        let referenceLocation = CLLocation(coordinate:currentLocation.coordinate,
                                           altitude: currentLocation.altitude)
        let startingPoint = CLLocation(coordinate: referenceLocation.coordinate, altitude: referenceLocation.altitude)
        let originNode = LocationNode(location: startingPoint)
        let pyramid: SCNPyramid = SCNPyramid(width: 2.0, height: 2.0, length: 2.0)
        pyramid.firstMaterial?.diffuse.contents = UIColor.systemPink
        let pyramidNode = SCNNode(geometry: pyramid)
        originNode.addChildNode(pyramidNode)
        addScenewideNodeSettings(originNode)
        sceneLocationView?.addLocationNodeWithConfirmedLocation(locationNode: originNode)
    }

    /// Add a stack of annotation nodes, 100 meters north of location, at altitudes between 0 and 100 meters.
    /// Also add a location node at the same place as each annotation node.
    func addStackOfNodes() {
        guard let currentLocation = sceneLocationView?.sceneLocationManager.currentLocation else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.addStackOfNodes()
            }
            return
        }

        // Copy the current location because it's a reference type. Necessary?
        let referenceLocation = CLLocation(coordinate:currentLocation.coordinate,
                                           altitude: currentLocation.altitude)
        var colorIndex = 0
        for altitude in [0.0, 20, 60, 100] {
            let color = colors[colorIndex % colors.count]
            colorIndex += 1
            // Create one annotation node 100 meters north, at specified altitude.
            let location = referenceLocation.translatedLocation(with: LocationTranslation(latitudeTranslation: 100.0, longitudeTranslation: 0.0, altitudeTranslation: altitude))
            let node = buildDisplacedAnnotationViewNode(altitude: altitude, color: color, location: location)
            addScenewideNodeSettings(node)
            sceneLocationView?.addLocationNodeWithConfirmedLocation(locationNode: node)

            // Now create a plain old geometry node at the same location.
            let cubeNode = LocationNode(location: location)
            let cubeSide = CGFloat(5)
            let cube = SCNBox(width: cubeSide, height: cubeSide, length: cubeSide, chamferRadius: 0)
            cube.firstMaterial?.diffuse.contents = color
            cubeNode.addChildNode(SCNNode(geometry: cube))
            addScenewideNodeSettings(cubeNode)
            sceneLocationView?.addLocationNodeWithConfirmedLocation(locationNode: cubeNode)
        }
        // Put a label at the origin.
        let label = UILabel.largeLabel(text: "Starting point")
        label.backgroundColor = .systemTeal
        let startingPoint = CLLocation(coordinate: referenceLocation.coordinate, altitude: referenceLocation.altitude)
        let originLabelNode = LocationAnnotationNode(location: startingPoint, view: label)
        sceneLocationView?.addLocationNodeWithConfirmedLocation(locationNode: originLabelNode)
    }

    /// Create a `LocationAnnotationNode` at `altitude` meters above the given location, labeled with the altitude.
    func buildDisplacedAnnotationViewNode(altitude: Double, color: UIColor, location: CLLocation) -> LocationAnnotationNode {
        let label = UILabel.largeLabel(text: "\(altitude)", backgroundColor: color)
        let result = LocationAnnotationNode(location: location, view: label)
        return result
    }

    /// Add an array of SNCSphere nodes centered on your current location.
    func addFieldOfNodes() {
        guard let currentLocation = sceneLocationView?.sceneLocationManager.currentLocation else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.addFieldOfNodes()
            }
            return
        }

        // Copy the current location because it's a reference type. Necessary?
        let referenceLocation = CLLocation(coordinate:currentLocation.coordinate,
                                           altitude: currentLocation.altitude)
        let rotateForeverAction = SCNAction.repeatForever(SCNAction.rotate(by: .pi, around: SCNVector3(1, 0, 0), duration: 3))
        var colorIndex = 0
        for northStep in -5...5 {
            let color = colors[colorIndex % colors.count]
            colorIndex += 1
            for eastStep in -5...5 {
                let location = referenceLocation.translatedLocation(with: LocationTranslation(latitudeTranslation: Double(northStep) * northingIncrementMeters, longitudeTranslation: Double(eastStep) * eastingIncrementMeters, altitudeTranslation: 0.0))
                let locationNode = LocationNode(location: location)
                let torus = SCNTorus(ringRadius: 10, pipeRadius: 2)
                torus.firstMaterial?.diffuse.contents = color
                let torusNode = SCNNode(geometry: torus)
                torusNode.runAction(rotateForeverAction)
                locationNode.addChildNode(torusNode)
                addScenewideNodeSettings(locationNode)
                sceneLocationView?.addLocationNodeWithConfirmedLocation(locationNode: locationNode)
            }
        }
    }

    /// Add an array of annotation nodes centered on your current location. Labels are static.
    func addFieldOfLabels() {
        guard let currentLocation = sceneLocationView?.sceneLocationManager.currentLocation else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.addFieldOfLabels()
            }
            return
        }

        // Copy the current location because it's a reference type. Necessary?
        let referenceLocation = CLLocation(coordinate:currentLocation.coordinate,
                                           altitude: currentLocation.altitude)
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
                addScenewideNodeSettings(annoNode)
                sceneLocationView?.addLocationNodeWithConfirmedLocation(locationNode: annoNode)
            }
        }
    }

    /// Add an array of annotation nodes showing radius, centered on your current location. Radius values are static.
    func addFieldOfRadii() {
        guard let currentLocation = sceneLocationView?.sceneLocationManager.currentLocation else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.addFieldOfRadii()
            }
            return
        }

        // Copy the current location because it's a reference type. Necessary?
        let referenceLocation = CLLocation(coordinate:currentLocation.coordinate,
                                           altitude: currentLocation.altitude)
        var colorIndex = 0
        for northStep in -5...5 {
            for eastStep in -5...5 {
                let color = colors[colorIndex % colors.count]
                colorIndex += 1
                let northOffset = Double(northStep) * 2.0
                let eastOffset = Double(eastStep) * 2.0
                let location = referenceLocation.translatedLocation(with: LocationTranslation(latitudeTranslation: northOffset, longitudeTranslation: eastOffset, altitudeTranslation: 0))
                let radius = Int(sqrt (northOffset * northOffset + eastOffset * eastOffset))
                let label = UILabel.largeLabel(text: "(\(radius))", backgroundColor: color)
                let annoNode = LocationAnnotationNode(location: location, view: label)
                addScenewideNodeSettings(annoNode)
                sceneLocationView?.addLocationNodeWithConfirmedLocation(locationNode: annoNode)
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
            if let position = self.sceneLocationView?.currentScenePosition {
                let xString = String(format: "%+03.2f", position.x)
                let yString = String(format: "%+03.2f", position.y)
                let zString = String(format: "%+03.2f", position.z)
                self.sceneXYZLabel.text = "SLV x: \(xString), y: \(yString), z: \(zString)"
            }
            else {
                self.sceneXYZLabel.text = ""
            }
            if let locationEstimate = self.sceneLocationView?.sceneLocationManager.bestLocationEstimate {
                let position = locationEstimate.position
                let xString = String(format: "%+03.2f", position.x)
                let yString = String(format: "%+03.2f", position.y)
                let zString = String(format: "%+03.2f", position.z)
                self.estXYZLabel.text = "LM x: \(xString), y: \(yString), z: \(zString)"

                let coordinate = locationEstimate.location.coordinate
                let latString = String(format: "%+6.5f", coordinate.latitude)
                let lonString = String(format: "%+6.5f", coordinate.longitude)
                self.estLatLonLabel.text = "LM \(latString) \(lonString)"
            }
            else {
                self.estXYZLabel.text = ""
                self.estHeadingLabel.text = ""
            }
            if let heading = self.sceneLocationView?.sceneLocationManager.locationManager.heading,
                let headingAccuracy = self.sceneLocationView?.sceneLocationManager.locationManager.headingAccuracy {
                let headingString = String(format: "%4.1f", heading)
                let headingAccuracyString = String(format: "%3.1f", headingAccuracy)
                self.estHeadingLabel.text = "LM heading \(headingString)° +/- \(headingAccuracyString)°"
            }
            else {
                self.estHeadingLabel.text = ""
            }
        }
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
    class func largeLabel(text: String, backgroundColor: UIColor = .systemGray) -> UILabel {
        let font = UIFont.preferredFont(forTextStyle: .title2)
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = (text as NSString).size(withAttributes: fontAttributes)
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))

        let attributedQuote = NSAttributedString(string: text, attributes:  [NSAttributedString.Key.font: font])
        label.attributedText = attributedQuote
        label.textAlignment = .center
        label.backgroundColor = backgroundColor
        label.adjustsFontForContentSizeCategory = true
        return label
    }


}

