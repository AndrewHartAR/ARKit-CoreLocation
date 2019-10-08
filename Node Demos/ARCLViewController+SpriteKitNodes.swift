//
//  ARCLViewController+SpriteKitNodes.swift
//  Node Demos
//
//  Created by Hal Mueller on 10/7/19.
//  Copyright © 2019 Project Dent. All rights reserved.
//

import ARCL
import ARKit
import MapKit
import SceneKit
import UIKit

extension ARCLViewController {

    /// Some experiments with getting SpriteKit scenes visible in ARCL.
    func addSpriteKitNodes() {
        guard let currentLocation = sceneLocationView?.sceneLocationManager.currentLocation else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.addSpriteKitNodes()
            }
            return
        }

        // Copy the current location because it's a reference type. Necessary?
        let referenceLocation = CLLocation(coordinate:currentLocation.coordinate,
                                           altitude: currentLocation.altitude)

        // Put a label at the origin.
        let north10Meterslabel = UILabel.largeLabel(text: "North 10 meters")
        north10Meterslabel.backgroundColor = .systemTeal
        let north10MetersLocation = referenceLocation.translatedLocation(with: LocationTranslation(latitudeTranslation: 10.0, longitudeTranslation: 0.0, altitudeTranslation: 0.0))
        let north10MetersLabelNode = LocationAnnotationNode(location: north10MetersLocation, view: north10Meterslabel)
        sceneLocationView?.addLocationNodeWithConfirmedLocation(locationNode: north10MetersLabelNode)

        let south10Meterslabel = UILabel.largeLabel(text: "South 10 meters")
        south10Meterslabel.backgroundColor = .systemPurple
        let south10MetersLocation = referenceLocation.translatedLocation(with: LocationTranslation(latitudeTranslation: -10.0, longitudeTranslation: 0.0, altitudeTranslation: 0.0))
        let south10MetersLabelNode = LocationAnnotationNode(location: south10MetersLocation, view: south10Meterslabel)
        sceneLocationView?.addLocationNodeWithConfirmedLocation(locationNode: south10MetersLabelNode)

        let east10MetersLocation = referenceLocation.translatedLocation(with: LocationTranslation(latitudeTranslation: 0.0, longitudeTranslation: 10.0, altitudeTranslation: 0.0))
        let east10MetersLabelNode = LocationNode(location: east10MetersLocation)
        sceneLocationView?.addLocationNodeWithConfirmedLocation(locationNode: south10MetersLabelNode)

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
}
