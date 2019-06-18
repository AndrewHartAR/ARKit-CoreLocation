//
//  SceneLocationEstimate.swift
//  ARKit+CoreLocation
//
//  Created by Andrew Hart on 03/07/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import Foundation
import CoreLocation
import SceneKit

public class SceneLocationEstimate {
    public let location: CLLocation
    public let position: SCNVector3

    init(location: CLLocation, position: SCNVector3) {
        self.location = location
        self.position = position
    }
}
