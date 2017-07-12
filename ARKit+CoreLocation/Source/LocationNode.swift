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

///Location, if available, is given with an appropriate accuracy.
///Location is not necessarily confirmed.
///When it isn't, the node's position should be used.
///Location can be changed and confirmed later.
class LocationNode: SCNNode {
    var location: CLLocation?
    
    var locationConfirmed = false
    
    init(location: CLLocation?) {
        self.location = location
        self.locationConfirmed = location != nil
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class LocationAnnotationNode: LocationNode {
    let image: UIImage
    
    init(location: CLLocation?, image: UIImage, plane: SCNPlane) {
        self.image = image
        
        super.init(location: location)
        
        plane.firstMaterial!.diffuse.contents = image
        self.geometry = plane
        self.constraints = [SCNBillboardConstraint()]
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
