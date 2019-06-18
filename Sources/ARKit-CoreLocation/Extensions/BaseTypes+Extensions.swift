//
//  BaseTypes+Extensions.swift
//  ARKit+CoreLocation
//
//  Created by Ilya Seliverstov on 08/08/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import Foundation

public extension Double {

    var metersToLatitude: Double {
        return self / (6_378_137.0)
    }

    var metersToLongitude: Double {
        return self / (6_356_752.3)
    }
}

public extension Float {
    var short: String { return String(format: "%.2f", self) }
}

public extension Int {
    var short: String { return String(format: "%02d", self) }
    var short3: String { return String(format: "%03d", self / 1_000_000) }
}
