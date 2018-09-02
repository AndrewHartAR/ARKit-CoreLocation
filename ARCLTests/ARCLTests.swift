//
//  ARCLTests.swift
//  ARCLTests
//
//  Created by Aaron Brethorst on 5/29/18.
//  Copyright © 2018 Project Dent. All rights reserved.
//

import XCTest
import CoreLocation

@testable import ARCL

class ARCLTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testBearing() {
        let pub = CLLocationCoordinate2D(latitude: 47.6235858, longitude: -122.3128663)

        let north = pub.coordinateWithBearing(bearing: 0, distanceMeters: 500)
        XCTAssertEqual(pub.latitude, north.latitude, accuracy: 0.01)

        let east = pub.coordinateWithBearing(bearing: 90, distanceMeters: 500)
        XCTAssertEqual(pub.longitude, east.longitude, accuracy: 0.01)
    }
}
