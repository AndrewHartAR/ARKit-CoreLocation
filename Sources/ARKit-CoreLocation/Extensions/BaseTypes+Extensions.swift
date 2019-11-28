//
//  BaseTypes+Extensions.swift
//  ARKit+CoreLocation
//
//  Created by Ilya Seliverstov on 08/08/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import Foundation

public extension Double {
    var short: String { return String(format: "%.02f", self) }
	var feetToMeters: Double { return self * 0.3048 }
	var metersToFeet: Double { return self * 3.28084 }
	var nauticalMilesToMeters: Double { return self * 1852.0 }
	var metersToNauticalMiles: Double { return self / 1852.0 }
}

public extension Float {
    var short: String { return String(format: "%.2f", self) }
}

public extension Int {
    var short: String { return String(format: "%02d", self) }
    var short3: String { return String(format: "%03d", self / 1_000_000) }
}
