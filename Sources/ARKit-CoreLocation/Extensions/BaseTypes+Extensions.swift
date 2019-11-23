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
}

public extension Float {
    var short: String { return String(format: "%.2f", self) }
}

public extension Int {
    var short: String { return String(format: "%02d", self) }
    var short3: String { return String(format: "%03d", self / 1_000_000) }
}
