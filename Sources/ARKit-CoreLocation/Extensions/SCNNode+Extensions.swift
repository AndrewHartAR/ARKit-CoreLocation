//
//  SCNNode+Extensions.swift
//  ARKit+CoreLocation
//
//  Created by Andrew Hart on 09/07/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import SceneKit

extension SCNNode {
    /// Overlapping nodes require unique renderingOrder values to avoid flicker
    /// This method will select random values if you don't care which node is in front of the other,
    /// or you can specify a particular z-order value
    func removeFlicker (withRenderingOrder renderingOrder: Int = Int.random(in: 1..<Int.max)) {
        self.renderingOrder = renderingOrder
        if let geom = geometry {
            geom.materials.forEach { $0.readsFromDepthBuffer = false }
        }
    }
    class func axesNode(quiverLength: CGFloat, quiverThickness: CGFloat) -> SCNNode {
        let quiverThickness = (quiverLength / 50.0) * quiverThickness
        let chamferRadius = quiverThickness / 2.0

        let xQuiverBox = SCNBox(width: quiverLength,
                                height: quiverThickness,
                                length: quiverThickness,
                                chamferRadius: chamferRadius)
        xQuiverBox.firstMaterial?.diffuse.contents = UIColor.red
        let xQuiverNode = SCNNode(geometry: xQuiverBox)
        xQuiverNode.position = SCNVector3Make(Float(quiverLength / 2.0), 0.0, 0.0)

        let yQuiverBox = SCNBox(width: quiverThickness,
                                height: quiverLength,
                                length: quiverThickness,
                                chamferRadius: chamferRadius)
        yQuiverBox.firstMaterial?.diffuse.contents = UIColor.green
        let yQuiverNode = SCNNode(geometry: yQuiverBox)
        yQuiverNode.position = SCNVector3Make(0.0, Float(quiverLength / 2.0), 0.0)

        let zQuiverBox = SCNBox(width: quiverThickness,
                                height: quiverThickness,
                                length: quiverLength,
                                chamferRadius: chamferRadius)
        zQuiverBox.firstMaterial?.diffuse.contents = UIColor.blue
        let zQuiverNode = SCNNode(geometry: zQuiverBox)
        zQuiverNode.position = SCNVector3Make(0.0, 0.0, Float(quiverLength / 2.0))

        let quiverNode = SCNNode()
        quiverNode.addChildNode(xQuiverNode)
        quiverNode.addChildNode(yQuiverNode)
        quiverNode.addChildNode(zQuiverNode)
        quiverNode.name = "Axes"
        return quiverNode
    }
}
