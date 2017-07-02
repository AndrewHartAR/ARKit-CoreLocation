//
//  SceneAnnotation.swift
//  ARKit+CoreLocation
//
//  Created by Andrew Hart on 02/07/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import Foundation
import SceneKit
import CoreLocation

///An annotation which appears within a scene
///Either a location or a position is required
///The location or position given must be confirmed
///Location can be added later, position cannot
class SceneAnnotation: Equatable {
    var location: CLLocation?
    let position: SCNVector3?
    
    let image: UIImage
    var node: SCNNode?
    var plane: SCNPlane
    
    init(position: SCNVector3, image: UIImage, plane: SCNPlane) {
        self.position = position
        self.image = image
        self.plane = plane
    }
    
    init(location: CLLocation, image: UIImage, plane: SCNPlane) {
        self.location = location
        self.position = nil
        self.image = image
        self.plane = plane
    }
    
    static func ==(lhs: SceneAnnotation, rhs: SceneAnnotation) -> Bool {
        return lhs === rhs
    }
}
