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
public class LocationNode: SCNNode {
    public var location: CLLocation?
    
    public var locationConfirmed = false
    
    public init(location: CLLocation?) {
        self.location = location
        self.locationConfirmed = location != nil
        super.init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class LocationAnnotationNode: LocationNode {
    public let image: UIImage
    
    public init(location: CLLocation?, image: UIImage, plane: SCNPlane) {
        self.image = image
        
        super.init(location: location)
        
        plane.firstMaterial!.diffuse.contents = image
        self.geometry = plane
        
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        
        self.constraints = [billboardConstraint]
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
