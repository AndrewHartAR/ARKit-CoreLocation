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

/// Test `coordinateWithBearing(bearing:distanceMeters)` for 4 different latitudes (85, 47.6, 5, -47.6),
/// 8 different bearings (every 45 degrees starting at 0),
/// and 3 different ranges (500, 10000, and 50000 meters). Compare against values computed with PostGIS.
class ARCLTests: XCTestCase {

    let longitudeAccuracy = 0.001 // 120 yards
    let latitudeAccuracy = 0.001  // 120 yards at equator, 85 yards at 45 degrees longitude
    let meters500 = 500.0
    let meters10000 = 10000.0
    let meters50000 = 50000.0

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    // TODO: this test doesn't appear to test anything. Looks like the expected value axes are reversed, and
    // a .01 accuracy translates to 1200 yards north/south, about 850 yards east/west
    // at this latitude.
    func testBearing() {
        let pub = CLLocationCoordinate2D(latitude: 47.6235858, longitude: -122.3128663)

        let north = pub.coordinateWithBearing(bearing: 0, distanceMeters: 500)
        XCTAssertEqual(pub.latitude, north.latitude, accuracy: 0.01)

        let east = pub.coordinateWithBearing(bearing: 90, distanceMeters: 500)
        XCTAssertEqual(pub.longitude, east.longitude, accuracy: 0.01)
    }

    func testCoordinateWithBearingMidLatitude500() {
        let start = CLLocationCoordinate2D(latitude: 47.6235858, longitude: -122.3128663)
        /*
         select bearing,ST_AsText(ST_Project('POINT(-122.3128663 47.6235858)'::geography, 500, radians(bearing)))
         from (
             values (0),(45),(90),(135),(180),(225),(270),(315)
         ) s(bearing);
          bearing |                 st_astext
         ---------+-------------------------------------------
                0 | POINT(-122.3128663 47.6280828887704)
               45 | POINT(-122.308162416608 47.6267656259013)
               90 | POINT(-122.306214407755 47.6235856071536)
              135 | POINT(-122.308162987107 47.620405779481)
              180 | POINT(-122.3128663 47.6190887076871)
              225 | POINT(-122.317569612893 47.620405779481)
              270 | POINT(-122.319518192245 47.6235856071536)
              315 | POINT(-122.317570183392 47.6267656259013)
         */
        let result0 = start.coordinateWithBearing(bearing: 0, distanceMeters: meters500)
        XCTAssertEqual(result0.longitude, -122.3128663, accuracy: longitudeAccuracy)
        XCTAssertEqual(result0.latitude, 47.6280828887704, accuracy: latitudeAccuracy)
        let result45 = start.coordinateWithBearing(bearing: 45, distanceMeters: meters500)
        XCTAssertEqual(result45.longitude, -122.308162416608, accuracy: longitudeAccuracy)
        XCTAssertEqual(result45.latitude,  47.6267656259013, accuracy: latitudeAccuracy)
        let result90 = start.coordinateWithBearing(bearing: 90, distanceMeters: meters500)
        XCTAssertEqual(result90.longitude, -122.306214407755, accuracy: longitudeAccuracy)
        XCTAssertEqual(result90.latitude, 47.6235856071536, accuracy: latitudeAccuracy)
        let result135 = start.coordinateWithBearing(bearing: 135, distanceMeters: meters500)
        XCTAssertEqual(result135.longitude, -122.308162987107, accuracy: longitudeAccuracy)
        XCTAssertEqual(result135.latitude, 47.620405779481, accuracy: latitudeAccuracy)
        let result180 = start.coordinateWithBearing(bearing: 180, distanceMeters: meters500)
        XCTAssertEqual(result180.longitude, -122.3128663, accuracy: longitudeAccuracy)
        XCTAssertEqual(result180.latitude, 47.6190887076871, accuracy: latitudeAccuracy)
        let result225 = start.coordinateWithBearing(bearing: 225, distanceMeters: meters500)
        XCTAssertEqual(result225.longitude, -122.317569612893, accuracy: longitudeAccuracy)
        XCTAssertEqual(result225.latitude, 47.620405779481, accuracy: latitudeAccuracy)
        let result270 = start.coordinateWithBearing(bearing: 270, distanceMeters: meters500)
        XCTAssertEqual(result270.longitude, -122.319518192245, accuracy: longitudeAccuracy)
        XCTAssertEqual(result270.latitude, 47.6235856071536, accuracy: latitudeAccuracy)
        let result315 = start.coordinateWithBearing(bearing: 315, distanceMeters: meters500)
        XCTAssertEqual(result315.longitude, -122.317570183392, accuracy: longitudeAccuracy)
        XCTAssertEqual(result315.latitude, 47.6267656259013, accuracy: latitudeAccuracy)
    }

    func testCoordinateWithBearingMidLatitude10000() {
        let start = CLLocationCoordinate2D(latitude: 47.6235858, longitude: -122.3128663)
        /*
         select bearing,ST_AsText(ST_Project('POINT(-122.3128663 47.6235858)'::geography, 10000, radians(bearing)))
                  from (
                      values (0),(45),(90),(135),(180),(225),(270),(315)
                  ) s(bearing);
          bearing |                 st_astext
         ---------+-------------------------------------------
         */
        let result0 = start.coordinateWithBearing(bearing: 0, distanceMeters: meters10000)
        XCTAssertEqual(result0.longitude, -122.3128663, accuracy: longitudeAccuracy)
        XCTAssertEqual(result0.latitude, 47.7135269024092, accuracy: latitudeAccuracy)
        let result45 = start.coordinateWithBearing(bearing: 45, distanceMeters: meters10000)
        XCTAssertEqual(result45.longitude, -122.218680106776, accuracy: longitudeAccuracy)
        XCTAssertEqual(result45.latitude, 47.6871452814007, accuracy: latitudeAccuracy)
        let result90 = start.coordinateWithBearing(bearing: 90, distanceMeters: meters10000)
        XCTAssertEqual(result90.longitude, -122.179828585245, accuracy: longitudeAccuracy)
        XCTAssertEqual(result90.latitude, 47.6235086614964, accuracy: latitudeAccuracy)
        let result135 = start.coordinateWithBearing(bearing: 135, distanceMeters: meters10000)
        XCTAssertEqual(result135.longitude, -122.218908306631, accuracy: longitudeAccuracy)
        XCTAssertEqual(result135.latitude, 47.5599484713877, accuracy: latitudeAccuracy)
        let result180 = start.coordinateWithBearing(bearing: 180, distanceMeters: meters10000)
        XCTAssertEqual(result180.longitude, -122.3128663, accuracy: longitudeAccuracy)
        XCTAssertEqual(result180.latitude, 47.5336432805981, accuracy: latitudeAccuracy)
        let result225 = start.coordinateWithBearing(bearing: 225, distanceMeters: meters10000)
        XCTAssertEqual(result225.longitude, -122.406824293369, accuracy: longitudeAccuracy)
        XCTAssertEqual(result225.latitude, 47.5599484713877, accuracy: latitudeAccuracy)
        let result270 = start.coordinateWithBearing(bearing: 270, distanceMeters: meters10000)
        XCTAssertEqual(result270.longitude, -122.445904014755, accuracy: longitudeAccuracy)
        XCTAssertEqual(result270.latitude, 47.6235086614964, accuracy: latitudeAccuracy)
        let result315 = start.coordinateWithBearing(bearing: 315, distanceMeters: meters10000)
        XCTAssertEqual(result315.longitude, -122.407052493224, accuracy: longitudeAccuracy)
        XCTAssertEqual(result315.latitude, 47.6871452814007, accuracy: latitudeAccuracy)
    }

    func testCoordinateWithBearingMidLatitude50000() {
        let start = CLLocationCoordinate2D(latitude: 47.6235858, longitude: -122.3128663)

/*
         select bearing,ST_AsText(ST_Project('POINT(-122.3128663 47.6235858)'::geography, 50000, radians(bearing)))
                  from (
                      values (0),(45),(90),(135),(180),(225),(270),(315)
                  ) s(bearing);
          bearing |                 st_astext
         ---------+-------------------------------------------
         */
        let result0 = start.coordinateWithBearing(bearing: 0, distanceMeters: meters50000)
        XCTAssertEqual(result0.longitude, -122.3128663, accuracy: longitudeAccuracy)
        XCTAssertEqual(result0.latitude, 48.0732771512326, accuracy: latitudeAccuracy)
        let result45 = start.coordinateWithBearing(bearing: 45, distanceMeters: meters50000)
        XCTAssertEqual(result45.longitude, -121.839637614568, accuracy: longitudeAccuracy)
        XCTAssertEqual(result45.latitude, 47.9405975715807, accuracy: latitudeAccuracy)
        let result90 = start.coordinateWithBearing(bearing: 90, distanceMeters: meters50000)
        XCTAssertEqual(result90.longitude, -121.647693382546, accuracy: longitudeAccuracy)
        XCTAssertEqual(result90.latitude, 47.6216573806133, accuracy: latitudeAccuracy)
        let result135 = start.coordinateWithBearing(bearing: 135, distanceMeters: meters50000)
        XCTAssertEqual(result135.longitude, -121.845342666805, accuracy: longitudeAccuracy)
        XCTAssertEqual(result135.latitude, 47.3046277647178, accuracy: latitudeAccuracy)
        let result180 = start.coordinateWithBearing(bearing: 180, distanceMeters: meters50000)
        XCTAssertEqual(result180.longitude, -122.3128663, accuracy: longitudeAccuracy)
        XCTAssertEqual(result180.latitude, 47.1738590246445, accuracy: latitudeAccuracy)
        let result225 = start.coordinateWithBearing(bearing: 225, distanceMeters: meters50000)
        XCTAssertEqual(result225.longitude, -122.780389933195, accuracy: longitudeAccuracy)
        XCTAssertEqual(result225.latitude, 47.3046277647178, accuracy: latitudeAccuracy)
        let result270 = start.coordinateWithBearing(bearing: 270, distanceMeters: meters50000)
        XCTAssertEqual(result270.longitude, -122.978039217454, accuracy: longitudeAccuracy)
        XCTAssertEqual(result270.latitude, 47.6216573806133, accuracy: latitudeAccuracy)
        let result315 = start.coordinateWithBearing(bearing: 315, distanceMeters: meters50000)
        XCTAssertEqual(result315.longitude, -122.786094985432, accuracy: longitudeAccuracy)
        XCTAssertEqual(result315.latitude, 47.9405975715807, accuracy: latitudeAccuracy)
    }

    func testCoordinateWithBearingFarNorth500() {
        let start = CLLocationCoordinate2D(latitude: 85, longitude: -122.3128663)
        /*
         select bearing,ST_AsText(ST_Project('POINT(-122.3128663 85)'::geography, 500, radians(bearing)))
                  from (
                      values (0),(45),(90),(135),(180),(225),(270),(315)
                  ) s(bearing);
          bearing |                 st_astext
         ---------+-------------------------------------------
         */
        let result0 = start.coordinateWithBearing(bearing: 0, distanceMeters: meters500)
        XCTAssertEqual(result0.longitude, -122.3128663, accuracy: longitudeAccuracy)
        XCTAssertEqual(result0.latitude, 85.0044768604693, accuracy: latitudeAccuracy)
        let result45 = start.coordinateWithBearing(bearing: 45, distanceMeters: meters500)
        XCTAssertEqual(result45.longitude, -122.27652381425, accuracy: longitudeAccuracy)
        XCTAssertEqual(result45.latitude, 85.003164618309, accuracy: latitudeAccuracy)
        let result90 = start.coordinateWithBearing(bearing: 90, distanceMeters: meters500)
        XCTAssertEqual(result90.longitude, -122.261502726378, accuracy: longitudeAccuracy)
        XCTAssertEqual(result90.latitude, 84.9999980009648, accuracy: latitudeAccuracy)
        let result135 = start.coordinateWithBearing(bearing: 135, distanceMeters: meters500)
        XCTAssertEqual(result135.longitude, -122.276569684625, accuracy: longitudeAccuracy)
        XCTAssertEqual(result135.latitude, 84.9968333823477, accuracy: latitudeAccuracy)
        let result180 = start.coordinateWithBearing(bearing: 180, distanceMeters: meters500)
        XCTAssertEqual(result180.longitude, -122.3128663, accuracy: longitudeAccuracy)
        XCTAssertEqual(result180.latitude, 84.9955231389167, accuracy: latitudeAccuracy)
        let result225 = start.coordinateWithBearing(bearing: 225, distanceMeters: meters500)
        XCTAssertEqual(result225.longitude, -122.349162915375, accuracy: longitudeAccuracy)
        XCTAssertEqual(result225.latitude, 84.9968333823477, accuracy: latitudeAccuracy)
        let result270 = start.coordinateWithBearing(bearing: 270, distanceMeters: meters500)
        XCTAssertEqual(result270.longitude, -122.364229873622, accuracy: longitudeAccuracy)
        XCTAssertEqual(result270.latitude, 84.9999980009648, accuracy: latitudeAccuracy)
    }

    func testCoordinateWithBearingFarNorth50000() {
        let start = CLLocationCoordinate2D(latitude: 85, longitude: -122.3128663)
        /*
         nrhp=> select bearing,ST_AsText(ST_Project('POINT(-122.3128663 85)'::geography, 50000, radians(bearing)))
                  from (
                      values (0),(45),(90),(135),(180),(225),(270),(315)
                  ) s(bearing);
         */
        let result0 = start.coordinateWithBearing(bearing: 0, distanceMeters: meters50000)
        XCTAssertEqual(result0.longitude, -122.3128663, accuracy: longitudeAccuracy)
        XCTAssertEqual(result0.latitude, 85.447683098238, accuracy: latitudeAccuracy)
        let result45 = start.coordinateWithBearing(bearing: 45, distanceMeters: meters50000)
        XCTAssertEqual(result45.longitude, -118.441917077449, accuracy: longitudeAccuracy)
        XCTAssertEqual(result45.latitude, 85.3059018482087, accuracy: latitudeAccuracy)
        let result90 = start.coordinateWithBearing(bearing: 90, distanceMeters: meters50000)
        XCTAssertEqual(result90.longitude, -117.190097318035, accuracy: longitudeAccuracy)
        XCTAssertEqual(result90.latitude, 84.9800494382655, accuracy: latitudeAccuracy)
        let result135 = start.coordinateWithBearing(bearing: 135, distanceMeters: meters50000)
        XCTAssertEqual(result135.longitude, -118.900615692524, accuracy: longitudeAccuracy)
        XCTAssertEqual(result135.latitude, 84.6740447063519, accuracy: latitudeAccuracy)
        let result180 = start.coordinateWithBearing(bearing: 180, distanceMeters: meters50000)
        XCTAssertEqual(result180.longitude, -122.3128663, accuracy: longitudeAccuracy)
        XCTAssertEqual(result180.latitude, 84.5523107615602, accuracy: latitudeAccuracy)
        let result225 = start.coordinateWithBearing(bearing: 225, distanceMeters: meters50000)
        XCTAssertEqual(result225.longitude, -125.725116907476, accuracy: longitudeAccuracy)
        XCTAssertEqual(result225.latitude, 84.6740447063519, accuracy: latitudeAccuracy)
        let result270 = start.coordinateWithBearing(bearing: 270, distanceMeters: meters50000)
        XCTAssertEqual(result270.longitude, -127.435635281965, accuracy: longitudeAccuracy)
        XCTAssertEqual(result270.latitude, 84.9800494382655, accuracy: latitudeAccuracy)
        let result315 = start.coordinateWithBearing(bearing: 315, distanceMeters: meters50000)
        XCTAssertEqual(result315.longitude, -126.183815522551, accuracy: longitudeAccuracy)
        XCTAssertEqual(result315.latitude, 85.3059018482087, accuracy: latitudeAccuracy)
    }

    func testCoordinateWithBearingFarNorth10000() {
        let start = CLLocationCoordinate2D(latitude: 85, longitude: -122.3128663)
        /*
         select bearing,ST_AsText(ST_Project('POINT(-122.3128663 85)'::geography, 10000, radians(bearing)))
         from (
         values (0),(45),(90),(135),(180),(225),(270),(315)
         ) s(bearing);
         bearing |                 st_astext
         ---------+-------------------------------------------
         */
        let result0 = start.coordinateWithBearing(bearing: 0, distanceMeters: meters10000)
        XCTAssertEqual(result0.longitude, -122.3128663, accuracy: longitudeAccuracy)
        XCTAssertEqual(result0.latitude, 85.0895370934438, accuracy: latitudeAccuracy)
        let result45 = start.coordinateWithBearing(bearing: 45, distanceMeters: meters10000)
        XCTAssertEqual(result45.longitude, -121.57722387973, accuracy: longitudeAccuracy)
        XCTAssertEqual(result45.latitude, 85.0629073941419, accuracy: latitudeAccuracy)
        let result90 = start.coordinateWithBearing(bearing: 90, distanceMeters: meters10000)
        XCTAssertEqual(result90.longitude, -121.285703772561, accuracy: longitudeAccuracy)
        XCTAssertEqual(result90.latitude, 84.9992004496645, accuracy: latitudeAccuracy)
        let result135 = start.coordinateWithBearing(bearing: 135, distanceMeters: meters10000)
        XCTAssertEqual(result135.longitude, -121.595572036496, accuracy: longitudeAccuracy)
        XCTAssertEqual(result135.latitude, 84.936292772585, accuracy: latitudeAccuracy)
        let result180 = start.coordinateWithBearing(bearing: 180, distanceMeters: meters10000)
        XCTAssertEqual(result180.longitude, -122.3128663, accuracy: longitudeAccuracy)
        XCTAssertEqual(result180.latitude, 84.9104626609434, accuracy: latitudeAccuracy)
        let result225 = start.coordinateWithBearing(bearing: 225, distanceMeters: meters10000)
        XCTAssertEqual(result225.longitude, -123.030160563504, accuracy: longitudeAccuracy)
        XCTAssertEqual(result225.latitude, 84.936292772585, accuracy: latitudeAccuracy)
        let result270 = start.coordinateWithBearing(bearing: 270, distanceMeters: meters10000)
        XCTAssertEqual(result270.longitude, -123.340028827439, accuracy: longitudeAccuracy)
        XCTAssertEqual(result270.latitude, 84.9992004496645, accuracy: latitudeAccuracy)
        let result315 = start.coordinateWithBearing(bearing: 315, distanceMeters: meters10000)
        XCTAssertEqual(result315.longitude, -123.04850872027, accuracy: longitudeAccuracy)
        XCTAssertEqual(result315.latitude, 85.0629073941419, accuracy: latitudeAccuracy)
    }

    func testCoordinateWithBearingLowLatitude500() {
        let start = CLLocationCoordinate2D(latitude: 5, longitude: -122.3128663)
/*
         select bearing,ST_AsText(ST_Project('POINT(-122.3128663 5)'::geography, 500, radians(bearing)))
                  from (
                      values (0),(45),(90),(135),(180),(225),(270),(315)
                  ) s(bearing);

          bearing |                 st_astext
         ---------+-------------------------------------------
 */
        let result0 = start.coordinateWithBearing(bearing: 0, distanceMeters: meters500)
        XCTAssertEqual(result0.longitude, -122.3128663, accuracy: longitudeAccuracy)
        XCTAssertEqual(result0.latitude, 5.00452150216546, accuracy: latitudeAccuracy)
        let result45 = start.coordinateWithBearing(bearing: 45, distanceMeters: meters500)
        XCTAssertEqual(result45.longitude, -122.309678209556, accuracy: longitudeAccuracy)
        XCTAssertEqual(result45.latitude, 5.00319717715266, accuracy: latitudeAccuracy)
        let result90 = start.coordinateWithBearing(bearing: 90, distanceMeters: meters500)
        XCTAssertEqual(result90.longitude, -122.308357681126, accuracy: longitudeAccuracy)
        XCTAssertEqual(result90.latitude, 4.99999998449507, accuracy: latitudeAccuracy)
        let result135 = start.coordinateWithBearing(bearing: 135, distanceMeters: meters500)
        XCTAssertEqual(result135.longitude, -122.309678240478, accuracy: longitudeAccuracy)
        XCTAssertEqual(result135.latitude, 4.99680280703131, accuracy: latitudeAccuracy)
        let result180 = start.coordinateWithBearing(bearing: 180, distanceMeters: meters500)
        XCTAssertEqual(result180.longitude, -122.3128663, accuracy: longitudeAccuracy)
        XCTAssertEqual(result180.latitude, 4.99547849721233, accuracy: latitudeAccuracy)
        let result225 = start.coordinateWithBearing(bearing: 225, distanceMeters: meters500)
        XCTAssertEqual(result225.longitude, -122.316054359522, accuracy: longitudeAccuracy)
        XCTAssertEqual(result225.latitude, 4.99680280703131, accuracy: latitudeAccuracy)
        let result270 = start.coordinateWithBearing(bearing: 270, distanceMeters: meters500)
        XCTAssertEqual(result270.longitude, -122.317374918874, accuracy: longitudeAccuracy)
        XCTAssertEqual(result270.latitude, 4.99999998449507, accuracy: latitudeAccuracy)
        let result315 = start.coordinateWithBearing(bearing: 315, distanceMeters: meters500)
        XCTAssertEqual(result315.longitude, -122.316054390444, accuracy: longitudeAccuracy)
        XCTAssertEqual(result315.latitude, 5.00319717715266, accuracy: latitudeAccuracy)
    }

    func testCoordinateWithBearingLowLatitude10000() {
        let start = CLLocationCoordinate2D(latitude: 5, longitude: -122.3128663)
            /*
             select bearing,ST_AsText(ST_Project('POINT(-122.3128663 5)'::geography, 10000, radians(bearing)))
                  from (
                      values (0),(45),(90),(135),(180),(225),(270),(315)
                  ) s(bearing);

          bearing |                 st_astext
         ---------+-------------------------------------------
             */
        let result0 = start.coordinateWithBearing(bearing: 0, distanceMeters: meters10000)
        XCTAssertEqual(result0.longitude, -122.3128663, accuracy: longitudeAccuracy)
        XCTAssertEqual(result0.latitude, 5.09042992434887, accuracy: latitudeAccuracy)
        let result45 = start.coordinateWithBearing(bearing: 45, distanceMeters: meters10000)
        XCTAssertEqual(result45.longitude, -122.249098589414, accuracy: longitudeAccuracy)
        XCTAssertEqual(result45.latitude, 5.06394052429685, accuracy: latitudeAccuracy)
        let result90 = start.coordinateWithBearing(bearing: 90, distanceMeters: meters10000)
        XCTAssertEqual(result90.longitude, -122.222693923089, accuracy: longitudeAccuracy)
        XCTAssertEqual(result90.latitude, 4.99999379803119, accuracy: latitudeAccuracy)
        let result135 = start.coordinateWithBearing(bearing: 135, distanceMeters: meters10000)
        XCTAssertEqual(result135.longitude, -122.249110958015, accuracy: longitudeAccuracy)
        XCTAssertEqual(result135.latitude, 4.93605314928675, accuracy: latitudeAccuracy)
        let result180 = start.coordinateWithBearing(bearing: 180, distanceMeters: meters10000)
        XCTAssertEqual(result180.longitude, -122.3128663, accuracy: longitudeAccuracy)
        XCTAssertEqual(result180.latitude, 4.90956982676742, accuracy: latitudeAccuracy)
        let result225 = start.coordinateWithBearing(bearing: 225, distanceMeters: meters10000)
        XCTAssertEqual(result225.longitude, -122.376621641985, accuracy: longitudeAccuracy)
        XCTAssertEqual(result225.latitude, 4.93605314928675, accuracy: latitudeAccuracy)
        let result270 = start.coordinateWithBearing(bearing: 270, distanceMeters: meters10000)
        XCTAssertEqual(result270.longitude, -122.403038676911, accuracy: longitudeAccuracy)
        XCTAssertEqual(result270.latitude, 4.99999379803119, accuracy: latitudeAccuracy)
        let result315 = start.coordinateWithBearing(bearing: 315, distanceMeters: meters10000)
        XCTAssertEqual(result315.longitude, -122.376634010586, accuracy: longitudeAccuracy)
        XCTAssertEqual(result315.latitude, 5.06394052429685, accuracy: latitudeAccuracy)
    }

    func testCoordinateWithBearingLowLatitude50000() {
        let start = CLLocationCoordinate2D(latitude: 5, longitude: -122.3128663)

        /*
         select bearing,ST_AsText(ST_Project('POINT(-122.3128663 5)'::geography, 50000, radians(bearing)))
                  from (
                      values (0),(45),(90),(135),(180),(225),(270),(315)
                  ) s(bearing);
          bearing |                 st_astext
         ---------+-------------------------------------------
         */
        let result0 = start.coordinateWithBearing(bearing: 0, distanceMeters: meters50000)
        XCTAssertEqual(result0.longitude, -122.3128663, accuracy: longitudeAccuracy)
        XCTAssertEqual(result0.latitude, 5.4521470438799, accuracy: latitudeAccuracy)
        let result45 = start.coordinateWithBearing(bearing: 45, distanceMeters: meters50000)
        XCTAssertEqual(result45.longitude, -121.99390085599, accuracy: longitudeAccuracy)
        XCTAssertEqual(result45.latitude, 5.31963770686063, accuracy: latitudeAccuracy)
        let result90 = start.coordinateWithBearing(bearing: 90, distanceMeters: meters50000)
        XCTAssertEqual(result90.longitude, -121.862004483307, accuracy: longitudeAccuracy)
        XCTAssertEqual(result90.latitude, 4.99984495156423, accuracy: latitudeAccuracy)
        let result135 = start.coordinateWithBearing(bearing: 135, distanceMeters: meters50000)
        XCTAssertEqual(result135.longitude, -121.994210074066, accuracy: longitudeAccuracy)
        XCTAssertEqual(result135.latitude, 4.68020413013662, accuracy: latitudeAccuracy)
        let result180 = start.coordinateWithBearing(bearing: 180, distanceMeters: meters50000)
        XCTAssertEqual(result180.longitude, -122.3128663, accuracy: longitudeAccuracy)
        XCTAssertEqual(result180.latitude, 4.54784673415444, accuracy: latitudeAccuracy)
        let result225 = start.coordinateWithBearing(bearing: 225, distanceMeters: meters50000)
        XCTAssertEqual(result225.longitude, -122.631522525934, accuracy: longitudeAccuracy)
        XCTAssertEqual(result225.latitude, 4.68020413013662, accuracy: latitudeAccuracy)
        let result270 = start.coordinateWithBearing(bearing: 270, distanceMeters: meters50000)
        XCTAssertEqual(result270.longitude, -122.763728116693, accuracy: longitudeAccuracy)
        XCTAssertEqual(result270.latitude, 4.99984495156423, accuracy: latitudeAccuracy)
        let result315 = start.coordinateWithBearing(bearing: 315, distanceMeters: meters50000)
        XCTAssertEqual(result315.longitude, -122.63183174401, accuracy: longitudeAccuracy)
        XCTAssertEqual(result315.latitude, 5.31963770686063, accuracy: latitudeAccuracy)
    }

    func testCoordinateWithBearingSouthernHemisphere500() {
        let start = CLLocationCoordinate2D(latitude: -40, longitude: -122.3128663)
        /*
         select bearing,ST_AsText(ST_Project('POINT(-122.3128663 -40)'::geography, 500, radians(bearing)))
                  from (
                      values (0),(45),(90),(135),(180),(225),(270),(315)
                  ) s(bearing);

          bearing |                 st_astext
         ---------+--------------------------------------------
         */
        let result0 = start.coordinateWithBearing(bearing: 0, distanceMeters: meters500)
        XCTAssertEqual(result0.longitude, -122.3128663, accuracy: longitudeAccuracy)
        XCTAssertEqual(result0.latitude, -39.9954968987312, accuracy: latitudeAccuracy)
        let result45 = start.coordinateWithBearing(bearing: 45, distanceMeters: meters500)
        XCTAssertEqual(result45.longitude, -122.308726225035, accuracy: longitudeAccuracy)
        XCTAssertEqual(result45.latitude, -39.9968157529746, accuracy: latitudeAccuracy)
        let result90 = start.coordinateWithBearing(bearing: 90, distanceMeters: meters500)
        XCTAssertEqual(result90.longitude, -122.30701107789, accuracy: longitudeAccuracy)
        XCTAssertEqual(result90.latitude, -39.9999998520994, accuracy: latitudeAccuracy)
        let result135 = start.coordinateWithBearing(bearing: 135, distanceMeters: meters500)
        XCTAssertEqual(result135.longitude, -122.308725840415, accuracy: longitudeAccuracy)
        XCTAssertEqual(result135.latitude, -40.00318409737, accuracy: latitudeAccuracy)
        let result180 = start.coordinateWithBearing(bearing: 180, distanceMeters: meters500)
        XCTAssertEqual(result180.longitude, -122.3128663, accuracy: longitudeAccuracy)
        XCTAssertEqual(result180.latitude, -40.0045030977592, accuracy: latitudeAccuracy)
        let result225 = start.coordinateWithBearing(bearing: 225, distanceMeters: meters500)
        XCTAssertEqual(result225.longitude, -122.317006759585, accuracy: longitudeAccuracy)
        XCTAssertEqual(result225.latitude, -40.00318409737, accuracy: latitudeAccuracy)
        let result270 = start.coordinateWithBearing(bearing: 270, distanceMeters: meters500)
        XCTAssertEqual(result270.longitude, -122.318721522109, accuracy: longitudeAccuracy)
        XCTAssertEqual(result270.latitude, -39.9999998520994, accuracy: latitudeAccuracy)
        let result315 = start.coordinateWithBearing(bearing: 315, distanceMeters: meters500)
        XCTAssertEqual(result315.longitude, -122.317006374965, accuracy: longitudeAccuracy)
        XCTAssertEqual(result315.latitude, -39.9968157529746, accuracy: latitudeAccuracy)
    }

    func testCoordinateWithBearingSouthernHemisphere10000() {
        let start = CLLocationCoordinate2D(latitude: -40, longitude: -122.3128663)
        /*
         select bearing,ST_AsText(ST_Project('POINT(-122.3128663 -40)'::geography, 10000, radians(bearing)))
                  from (
                      values (0),(45),(90),(135),(180),(225),(270),(315)
                  ) s(bearing);

          bearing |                 st_astext
         ---------+--------------------------------------------
         */
        let result0 = start.coordinateWithBearing(bearing: 0, distanceMeters: meters10000)
        XCTAssertEqual(result0.longitude, -122.3128663, accuracy: longitudeAccuracy)
        XCTAssertEqual(result0.latitude, -39.9099373079262, accuracy: latitudeAccuracy)
        let result45 = start.coordinateWithBearing(bearing: 45, distanceMeters: meters10000)
        XCTAssertEqual(result45.longitude, -122.230137797083, accuracy: longitudeAccuracy)
        XCTAssertEqual(result45.latitude, -39.9362866650944, accuracy: latitudeAccuracy)
        let result90 = start.coordinateWithBearing(bearing: 90, distanceMeters: meters10000)
        XCTAssertEqual(result90.longitude, -122.195761925015, accuracy: longitudeAccuracy)
        XCTAssertEqual(result90.latitude, -39.9999408398175, accuracy: latitudeAccuracy)
        let result135 = start.coordinateWithBearing(bearing: 135, distanceMeters: meters10000)
        XCTAssertEqual(result135.longitude, -122.229983949109, accuracy: longitudeAccuracy)
        XCTAssertEqual(result135.latitude, -40.0636534726882, accuracy: latitudeAccuracy)
        let result180 = start.coordinateWithBearing(bearing: 180, distanceMeters: meters10000)
        XCTAssertEqual(result180.longitude, -122.3128663, accuracy: longitudeAccuracy)
        XCTAssertEqual(result180.latitude, -40.0900612882388, accuracy: latitudeAccuracy)
        let result225 = start.coordinateWithBearing(bearing: 225, distanceMeters: meters10000)
        XCTAssertEqual(result225.longitude, -122.395748650891, accuracy: longitudeAccuracy)
        XCTAssertEqual(result225.latitude, -40.0636534726882, accuracy: latitudeAccuracy)
        let result270 = start.coordinateWithBearing(bearing: 270, distanceMeters: meters10000)
        XCTAssertEqual(result270.longitude, -122.429970674985, accuracy: longitudeAccuracy)
        XCTAssertEqual(result270.latitude, -39.9999408398175, accuracy: latitudeAccuracy)
        let result315 = start.coordinateWithBearing(bearing: 315, distanceMeters: meters10000)
        XCTAssertEqual(result315.longitude, -122.395594802917, accuracy: longitudeAccuracy)
        XCTAssertEqual(result315.latitude, -39.9362866650943, accuracy: latitudeAccuracy)
    }

    func testCoordinateWithBearingSouthernHemisphere50000() {
        let start = CLLocationCoordinate2D(latitude: -40, longitude: -122.3128663)

        /*
         select bearing,ST_AsText(ST_Project('POINT(-122.3128663 -40)'::geography, 50000, radians(bearing)))
                  from (
                      values (0),(45),(90),(135),(180),(225),(270),(315)
                  ) s(bearing);

          bearing |                 st_astext
         ---------+--------------------------------------------
         */
        let result0 = start.coordinateWithBearing(bearing: 0, distanceMeters: meters50000)
        XCTAssertEqual(result0.longitude, -122.3128663, accuracy: longitudeAccuracy)
        XCTAssertEqual(result0.latitude, -39.5496725166091, accuracy: latitudeAccuracy)
        let result45 = start.coordinateWithBearing(bearing: 45, distanceMeters: meters50000)
        XCTAssertEqual(result45.longitude, -121.900752491598, accuracy: longitudeAccuracy)
        XCTAssertEqual(result45.latitude, -39.6808395104955, accuracy: latitudeAccuracy)
        let result90 = start.coordinateWithBearing(bearing: 90, distanceMeters: meters50000)
        XCTAssertEqual(result90.longitude, -121.727352509562, accuracy: longitudeAccuracy)
        XCTAssertEqual(result90.latitude, -39.9985210178516, accuracy: latitudeAccuracy)
        let result135 = start.coordinateWithBearing(bearing: 135, distanceMeters: meters50000)
        XCTAssertEqual(result135.longitude, -121.896906254532, accuracy: longitudeAccuracy)
        XCTAssertEqual(result135.latitude, -40.3176638863652, accuracy: latitudeAccuracy)
        let result180 = start.coordinateWithBearing(bearing: 180, distanceMeters: meters50000)
        XCTAssertEqual(result180.longitude, -122.3128663, accuracy: longitudeAccuracy)
        XCTAssertEqual(result180.latitude, -40.4502923882122, accuracy: latitudeAccuracy)
        let result225 = start.coordinateWithBearing(bearing: 225, distanceMeters: meters50000)
        XCTAssertEqual(result225.longitude, -122.728826345467, accuracy: longitudeAccuracy)
        XCTAssertEqual(result225.latitude, -40.3176638863652, accuracy: latitudeAccuracy)
        let result270 = start.coordinateWithBearing(bearing: 270, distanceMeters: meters50000)
        XCTAssertEqual(result270.longitude, -122.898380090438, accuracy: longitudeAccuracy)
        XCTAssertEqual(result270.latitude, -39.9985210178516, accuracy: latitudeAccuracy)
        let result315 = start.coordinateWithBearing(bearing: 315, distanceMeters: meters50000)
        XCTAssertEqual(result315.longitude, -122.724980108402, accuracy: longitudeAccuracy)
        XCTAssertEqual(result315.latitude, -39.6808395104955, accuracy: latitudeAccuracy)
    }

    /*
     nrhp=>          select bearing,ST_AsText(ST_Project('POINT(-122.3128663 47.6235858)'::geography, 500, radians(bearing)))
     nrhp->          from (
     nrhp(>              values (0),(45),(90),(135),(180),(225),(270),(315)
     nrhp(>          ) s(bearing);
      bearing |                 st_astext
     ---------+-------------------------------------------
            0 | POINT(-122.3128663 47.6280828887704)
           45 | POINT(-122.308162416608 47.6267656259013)
           90 | POINT(-122.306214407755 47.6235856071536)
          135 | POINT(-122.308162987107 47.620405779481)
          180 | POINT(-122.3128663 47.6190887076871)
          225 | POINT(-122.317569612893 47.620405779481)
          270 | POINT(-122.319518192245 47.6235856071536)
          315 | POINT(-122.317570183392 47.6267656259013)
     (8 rows)

     nrhp=>
     nrhp=> select bearing,ST_AsText(ST_Project('POINT(-122.3128663 47.6235858)'::geography, 10000, radians(bearing)))
              from (
                  values (0),(45),(90),(135),(180),(225),(270),(315)
              ) s(bearing);
      bearing |                 st_astext
     ---------+-------------------------------------------
            0 | POINT(-122.3128663 47.7135269024092)
           45 | POINT(-122.218680106776 47.6871452814007)
           90 | POINT(-122.179828585245 47.6235086614964)
          135 | POINT(-122.218908306631 47.5599484713877)
          180 | POINT(-122.3128663 47.5336432805981)
          225 | POINT(-122.406824293369 47.5599484713877)
          270 | POINT(-122.445904014755 47.6235086614964)
          315 | POINT(-122.407052493224 47.6871452814007)
     (8 rows)

     nrhp=> select bearing,ST_AsText(ST_Project('POINT(-122.3128663 47.6235858)'::geography, 50000, radians(bearing)))
              from (
                  values (0),(45),(90),(135),(180),(225),(270),(315)
              ) s(bearing);
      bearing |                 st_astext
     ---------+-------------------------------------------
            0 | POINT(-122.3128663 48.0732771512326)
           45 | POINT(-121.839637614568 47.9405975715807)
           90 | POINT(-121.647693382546 47.6216573806133)
          135 | POINT(-121.845342666805 47.3046277647178)
          180 | POINT(-122.3128663 47.1738590246445)
          225 | POINT(-122.780389933195 47.3046277647178)
          270 | POINT(-122.978039217454 47.6216573806133)
          315 | POINT(-122.786094985432 47.9405975715807)
     (8 rows)

     nrhp=> select bearing,ST_AsText(ST_Project('POINT(-122.3128663 85)'::geography, 50000, radians(bearing)))
              from (
                  values (0),(45),(90),(135),(180),(225),(270),(315)
              ) s(bearing);
      bearing |                 st_astext
     ---------+-------------------------------------------
            0 | POINT(-122.3128663 85.447683098238)
           45 | POINT(-118.441917077449 85.3059018482087)
           90 | POINT(-117.190097318035 84.9800494382655)
          135 | POINT(-118.900615692524 84.6740447063519)
          180 | POINT(-122.3128663 84.5523107615602)
          225 | POINT(-125.725116907476 84.6740447063519)
          270 | POINT(-127.435635281965 84.9800494382655)
          315 | POINT(-126.183815522551 85.3059018482087)
     (8 rows)

     nrhp=> select bearing,ST_AsText(ST_Project('POINT(-122.3128663 85)'::geography, 10000, radians(bearing)))
              from (
                  values (0),(45),(90),(135),(180),(225),(270),(315)
              ) s(bearing);
      bearing |                 st_astext
     ---------+-------------------------------------------
            0 | POINT(-122.3128663 85.0895370934438)
           45 | POINT(-121.57722387973 85.0629073941419)
           90 | POINT(-121.285703772561 84.9992004496645)
          135 | POINT(-121.595572036496 84.936292772585)
          180 | POINT(-122.3128663 84.9104626609434)
          225 | POINT(-123.030160563504 84.936292772585)
          270 | POINT(-123.340028827439 84.9992004496645)
          315 | POINT(-123.04850872027 85.0629073941419)
     (8 rows)

     nrhp=> select bearing,ST_AsText(ST_Project('POINT(-122.3128663 85)'::geography, 500, radians(bearing)))
              from (
                  values (0),(45),(90),(135),(180),(225),(270),(315)
              ) s(bearing);
      bearing |                 st_astext
     ---------+-------------------------------------------
            0 | POINT(-122.3128663 85.0044768604693)
           45 | POINT(-122.27652381425 85.003164618309)
           90 | POINT(-122.261502726378 84.9999980009648)
          135 | POINT(-122.276569684625 84.9968333823477)
          180 | POINT(-122.3128663 84.9955231389167)
          225 | POINT(-122.349162915375 84.9968333823477)
          270 | POINT(-122.364229873622 84.9999980009648)
          315 | POINT(-122.34920878575 85.003164618309)
     (8 rows)

     nrhp=>          select bearing,ST_AsText(ST_Project('POINT(-122.3128663 5)'::geography, 500, radians(bearing)))
     nrhp->                   from (
     nrhp(>                       values (0),(45),(90),(135),(180),(225),(270),(315)
     nrhp(>                   ) s(bearing);
      bearing |                 st_astext
     ---------+-------------------------------------------
            0 | POINT(-122.3128663 5.00452150216546)
           45 | POINT(-122.309678209556 5.00319717715266)
           90 | POINT(-122.308357681126 4.99999998449507)
          135 | POINT(-122.309678240478 4.99680280703131)
          180 | POINT(-122.3128663 4.99547849721233)
          225 | POINT(-122.316054359522 4.99680280703131)
          270 | POINT(-122.317374918874 4.99999998449507)
          315 | POINT(-122.316054390444 5.00319717715266)
     (8 rows)

     nrhp=>
     nrhp=>          select bearing,ST_AsText(ST_Project('POINT(-122.3128663 5)'::geography, 500, radians(bearing)))
     nrhp->                   from (
     nrhp(>                       values (0),(45),(90),(135),(180),(225),(270),(315)
     nrhp(>                   ) s(bearing);
      bearing |                 st_astext
     ---------+-------------------------------------------
            0 | POINT(-122.3128663 5.00452150216546)
           45 | POINT(-122.309678209556 5.00319717715266)
           90 | POINT(-122.308357681126 4.99999998449507)
          135 | POINT(-122.309678240478 4.99680280703131)
          180 | POINT(-122.3128663 4.99547849721233)
          225 | POINT(-122.316054359522 4.99680280703131)
          270 | POINT(-122.317374918874 4.99999998449507)
          315 | POINT(-122.316054390444 5.00319717715266)
     (8 rows)

     nrhp=>
     nrhp=>          select bearing,ST_AsText(ST_Project('POINT(-122.3128663 5)'::geography, 500, radians(bearing)))
     nrhp->                   from (
     nrhp(>                       values (0),(45),(90),(135),(180),(225),(270),(315)
     nrhp(>                   ) s(bearing);
      bearing |                 st_astext
     ---------+-------------------------------------------
            0 | POINT(-122.3128663 5.00452150216546)
           45 | POINT(-122.309678209556 5.00319717715266)
           90 | POINT(-122.308357681126 4.99999998449507)
          135 | POINT(-122.309678240478 4.99680280703131)
          180 | POINT(-122.3128663 4.99547849721233)
          225 | POINT(-122.316054359522 4.99680280703131)
          270 | POINT(-122.317374918874 4.99999998449507)
          315 | POINT(-122.316054390444 5.00319717715266)
     (8 rows)

     nrhp=>
     nrhp=>          select bearing,ST_AsText(ST_Project('POINT(-122.3128663 5)'::geography, 10000, radians(bearing)))
     nrhp->                   from (
     nrhp(>                       values (0),(45),(90),(135),(180),(225),(270),(315)
     nrhp(>                   ) s(bearing);
      bearing |                 st_astext
     ---------+-------------------------------------------
            0 | POINT(-122.3128663 5.09042992434887)
           45 | POINT(-122.249098589414 5.06394052429685)
           90 | POINT(-122.222693923089 4.99999379803119)
          135 | POINT(-122.249110958015 4.93605314928675)
          180 | POINT(-122.3128663 4.90956982676742)
          225 | POINT(-122.376621641985 4.93605314928675)
          270 | POINT(-122.403038676911 4.99999379803119)
          315 | POINT(-122.376634010586 5.06394052429685)
     (8 rows)

     nrhp=>
     nrhp=>          select bearing,ST_AsText(ST_Project('POINT(-122.3128663 5)'::geography, 50000, radians(bearing)))
     nrhp->                   from (
     nrhp(>                       values (0),(45),(90),(135),(180),(225),(270),(315)
     nrhp(>                   ) s(bearing);
      bearing |                 st_astext
     ---------+-------------------------------------------
            0 | POINT(-122.3128663 5.4521470438799)
           45 | POINT(-121.99390085599 5.31963770686063)
           90 | POINT(-121.862004483307 4.99984495156423)
          135 | POINT(-121.994210074066 4.68020413013662)
          180 | POINT(-122.3128663 4.54784673415444)
          225 | POINT(-122.631522525934 4.68020413013662)
          270 | POINT(-122.763728116693 4.99984495156423)
          315 | POINT(-122.63183174401 5.31963770686063)
     (8 rows)

     nrhp=>          select bearing,ST_AsText(ST_Project('POINT(-122.3128663 -40)'::geography, 500, radians(bearing)))
     nrhp->                   from (
     nrhp(>                       values (0),(45),(90),(135),(180),(225),(270),(315)
     nrhp(>                   ) s(bearing);
      bearing |                 st_astext
     ---------+--------------------------------------------
            0 | POINT(-122.3128663 -39.9954968987312)
           45 | POINT(-122.308726225035 -39.9968157529746)
           90 | POINT(-122.30701107789 -39.9999998520994)
          135 | POINT(-122.308725840415 -40.00318409737)
          180 | POINT(-122.3128663 -40.0045030977592)
          225 | POINT(-122.317006759585 -40.00318409737)
          270 | POINT(-122.318721522109 -39.9999998520994)
          315 | POINT(-122.317006374965 -39.9968157529746)
     (8 rows)

     nrhp=>
     nrhp=>          select bearing,ST_AsText(ST_Project('POINT(-122.3128663 -40)'::geography, 10000, radians(bearing)))
     nrhp->                   from (
     nrhp(>                       values (0),(45),(90),(135),(180),(225),(270),(315)
     nrhp(>                   ) s(bearing);
      bearing |                 st_astext
     ---------+--------------------------------------------
            0 | POINT(-122.3128663 -39.9099373079262)
           45 | POINT(-122.230137797083 -39.9362866650944)
           90 | POINT(-122.195761925015 -39.9999408398175)
          135 | POINT(-122.229983949109 -40.0636534726882)
          180 | POINT(-122.3128663 -40.0900612882388)
          225 | POINT(-122.395748650891 -40.0636534726882)
          270 | POINT(-122.429970674985 -39.9999408398175)
          315 | POINT(-122.395594802917 -39.9362866650943)
     (8 rows)

     nrhp=>
     nrhp=>          select bearing,ST_AsText(ST_Project('POINT(-122.3128663 -40)'::geography, 50000, radians(bearing)))
     nrhp->                   from (
     nrhp(>                       values (0),(45),(90),(135),(180),(225),(270),(315)
     nrhp(>                   ) s(bearing);
      bearing |                 st_astext
     ---------+--------------------------------------------
            0 | POINT(-122.3128663 -39.5496725166091)
           45 | POINT(-121.900752491598 -39.6808395104955)
           90 | POINT(-121.727352509562 -39.9985210178516)
          135 | POINT(-121.896906254532 -40.3176638863652)
          180 | POINT(-122.3128663 -40.4502923882122)
          225 | POINT(-122.728826345467 -40.3176638863652)
          270 | POINT(-122.898380090438 -39.9985210178516)
          315 | POINT(-122.724980108402 -39.6808395104955)
     (8 rows)


     */
}
