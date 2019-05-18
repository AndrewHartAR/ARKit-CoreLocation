//
//  PolylineNode.swift
//  ARKit+CoreLocation
//
//  Created by Ilya Seliverstov on 11/08/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import Foundation
import SceneKit
import MapKit

public class PolylineNode {
    public private(set) var locationNodes = [LocationNode]()

    public let polyline: MKPolyline
    public let altitude: CLLocationDistance

    private let lightNode: SCNNode = {
        let node = SCNNode()
        node.light = SCNLight()
        node.light!.type = .ambient
        if #available(iOS 10.0, *) {
            node.light!.intensity = 25
        }
        node.light!.attenuationStartDistance = 100
        node.light!.attenuationEndDistance = 100
        node.position = SCNVector3(x: 0, y: 10, z: 0)
        node.castsShadow = false
        node.light!.categoryBitMask = 3
        return node
    }()

    private let lightNode3: SCNNode = {
        let node = SCNNode()
        node.light = SCNLight()
        node.light!.type = .omni
        if #available(iOS 10.0, *) {
            node.light!.intensity = 100
        }
        node.light!.attenuationStartDistance = 100
        node.light!.attenuationEndDistance = 100
        node.light!.castsShadow = true
        node.position = SCNVector3(x: -10, y: 10, z: -10)
        node.castsShadow = false
        node.light!.categoryBitMask = 3
        return node
    }()

    /// Creates a `PolylineNode` from the provided polyline, altitude (which is assumed to be uniform
    /// for all of the points) and an optional SCNBox to use as a prototype for the location boxes.
    ///
    /// - Parameters:
    ///   - polyline: The polyline that we'll be creating location nodes for.
    ///   - altitude: The uniform altitude to use to show the location nodes.
    ///   - boxPrototype: A prototype SCNBox geometry to use as a template for the direction boxes.
    public init(polyline: MKPolyline, altitude: CLLocationDistance, boxPrototype: SCNBox? = nil) {
        self.polyline = polyline
        self.altitude = altitude

        contructNodes(boxPrototype: boxPrototype)
    }

    /// This is what actually builds the SCNNodes and appends them to the
    /// locationNodes collection so they can be added to the scene and shown
    /// to the user.  If the prototype box is nil, then the default box will be used
    ///
    /// - Parameter boxPrototype: The optional prototype of the box to use
    fileprivate func contructNodes(boxPrototype: SCNBox?) {
        let points = polyline.points()

        for i in 0 ..< polyline.pointCount - 1 {
            let currentLocation = CLLocation(coordinate: points[i].coordinate, altitude: altitude)
            let nextLocation = CLLocation(coordinate: points[i + 1].coordinate, altitude: altitude)

            let distance = currentLocation.distance(from: nextLocation)

            let box = boxPrototype?.cloneBox(distance: CGFloat(distance))
                ?? SCNBox.defaultBox(distance: CGFloat(distance))

            let bearing = -currentLocation.bearing(between: nextLocation)

            let boxNode = SCNNode(geometry: box)
            boxNode.pivot = SCNMatrix4MakeTranslation(0, 0, 0.5 * Float(distance))
            boxNode.eulerAngles.y = Float(bearing).degreesToRadians
            boxNode.categoryBitMask = 3
            boxNode.addChildNode(lightNode)
            boxNode.addChildNode(lightNode3)

            let locationNode = LocationNode(location: currentLocation)
            locationNode.addChildNode(boxNode)

            locationNodes.append(locationNode)
        }
    }
}

private extension SCNBox {

    /// Creates the default box for you, a dark blueish colored box with a 0 chamfer radius.
    ///
    /// - Parameter distance: The distance of the box.
    /// - Returns: An SCN Box
    static func defaultBox(distance: CGFloat) -> SCNBox {
        let box = SCNBox(width: 1, height: 0.2, length: distance, chamferRadius: 0)
        box.firstMaterial?.diffuse.contents = UIColor(red: 47.0/255.0, green: 125.0/255.0, blue: 255.0/255.0, alpha: 1.0)
        return box
    }

    /// Clones this box (uses it as a prototype) and sets the height of the new box.
    ///
    /// - Parameter distance: The distance of the box (height)
    /// - Returns: A new box, based on this box
    func cloneBox(distance: CGFloat) -> SCNBox {
        let box = SCNBox(width: width, height: height, length: distance, chamferRadius: chamferRadius)
        box.firstMaterial = firstMaterial

        return box
    }

}
