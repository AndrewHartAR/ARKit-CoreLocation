//
//  CLLocationExtensionsTests.swift
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
class CLLocationExtensionsTests: XCTestCase {

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

    func assertCorrectBearingProjection(start: CLLocation, distanceMeters: Double, bearing: Double, lon: Double, lat: Double) {
        // 1 nautical mile ~= 2000 yards. 1 degree of latitude = 60 nautical miles.
        let longitudeAccuracy = 0.001 // 120 yards at equator, 85 yards at +/-45 degrees latitude
        let latitudeAccuracy = 0.001  // 120 yards

        let startPoint = start.coordinate
        let resultPoint = startPoint.coordinateWithBearing(bearing: bearing, distanceMeters: distanceMeters)

        XCTAssertEqual(resultPoint.latitude, lat, accuracy: latitudeAccuracy)
        XCTAssertEqual(resultPoint.longitude, lon, accuracy: longitudeAccuracy)
        
        let resultLocation = CLLocation.init(coordinate: resultPoint, altitude: 0)
        let distanceError = resultLocation.distance(from: CLLocation.init(latitude: lat, longitude: lon))
        XCTAssertLessThan(distanceError, 100.0)

        // An angular error of 5 degrees is about twice the width of your thumb at arm's length.
        let maxAngularError = 5.0 * .pi / 180
        // distanceError/distanceMeters is the sin of the max angular error.
        XCTAssertLessThan(distanceError / distanceMeters, sin(maxAngularError))
    }
    
    func testCoordinateWithBearingMidLatitude500() {
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
        let start = CLLocation.init(latitude: 47.6235858, longitude: -122.3128663)
        assertCorrectBearingProjection(start: start, distanceMeters: 500, bearing: 0, lon:-122.3128663, lat: 47.6280828887704)
        assertCorrectBearingProjection(start: start, distanceMeters: 500, bearing: 45, lon: -122.308162416608, lat: 47.6267656259013)
        assertCorrectBearingProjection(start: start, distanceMeters: 500, bearing: 90, lon:-122.306214407755, lat: 47.6235856071536)
        assertCorrectBearingProjection(start: start, distanceMeters: 500, bearing:135, lon:-122.308162987107, lat: 47.620405779481)
        assertCorrectBearingProjection(start: start, distanceMeters: 500, bearing:180, lon:-122.3128663, lat: 47.6190887076871)
        assertCorrectBearingProjection(start: start, distanceMeters: 500, bearing:225, lon:-122.317569612893, lat: 47.620405779481)
        assertCorrectBearingProjection(start: start, distanceMeters: 500, bearing:270, lon:-122.319518192245, lat: 47.6235856071536)
        assertCorrectBearingProjection(start: start, distanceMeters: 500, bearing:315, lon:-122.317570183392, lat: 47.6267656259013)
    }

    func testCoordinateWithBearingMidLatitude10000() {
/*
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
*/
        let start = CLLocation.init(latitude: 47.6235858, longitude: -122.3128663)
        assertCorrectBearingProjection(start: start, distanceMeters: 10000, bearing: 0, lon:-122.3128663, lat: 47.7135269024092)
        assertCorrectBearingProjection(start: start, distanceMeters: 10000, bearing:45, lon:-122.218680106776, lat: 47.6871452814007)
        assertCorrectBearingProjection(start: start, distanceMeters: 10000, bearing:90, lon:-122.179828585245, lat: 47.6235086614964)
        assertCorrectBearingProjection(start: start, distanceMeters: 10000, bearing:135, lon:-122.218908306631, lat: 47.5599484713877)
        assertCorrectBearingProjection(start: start, distanceMeters: 10000, bearing:180, lon:-122.3128663, lat: 47.5336432805981)
        assertCorrectBearingProjection(start: start, distanceMeters: 10000, bearing:225, lon:-122.406824293369, lat: 47.5599484713877)
        assertCorrectBearingProjection(start: start, distanceMeters: 10000, bearing:270, lon:-122.445904014755, lat: 47.6235086614964)
        assertCorrectBearingProjection(start: start, distanceMeters: 10000, bearing:315, lon:-122.407052493224, lat: 47.6871452814007)
    }

    func testCoordinateWithBearingMidLatitude50000() {
        /*
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

*/
        let start = CLLocation.init(latitude: 47.6235858, longitude: -122.3128663)
        assertCorrectBearingProjection(start: start, distanceMeters: 50000, bearing:0, lon:-122.3128663, lat: 48.0732771512326)
        assertCorrectBearingProjection(start: start, distanceMeters: 50000, bearing:45, lon:-121.839637614568, lat: 47.9405975715807)
        assertCorrectBearingProjection(start: start, distanceMeters: 50000, bearing:90, lon:-121.647693382546, lat: 47.6216573806133)
        assertCorrectBearingProjection(start: start, distanceMeters: 50000, bearing:135, lon:-121.845342666805, lat: 47.3046277647178)
        assertCorrectBearingProjection(start: start, distanceMeters: 50000, bearing:180, lon:-122.3128663, lat: 47.1738590246445)
        assertCorrectBearingProjection(start: start, distanceMeters: 50000, bearing:225, lon:-122.780389933195, lat: 47.3046277647178)
        assertCorrectBearingProjection(start: start, distanceMeters: 50000, bearing:270, lon:-122.978039217454, lat: 47.6216573806133)
        assertCorrectBearingProjection(start: start, distanceMeters: 50000, bearing:315, lon:-122.786094985432, lat: 47.9405975715807)
    }

    func testCoordinateWithBearingFarNorth500() {
        /*
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

*/
        let start = CLLocation.init(latitude: 85, longitude: -122.3128663)
        assertCorrectBearingProjection(start: start, distanceMeters: 500, bearing:0, lon:-122.3128663, lat: 85.0044768604693)
        assertCorrectBearingProjection(start: start, distanceMeters: 500, bearing:45, lon:-122.27652381425, lat: 85.003164618309)
        assertCorrectBearingProjection(start: start, distanceMeters: 500, bearing:90, lon:-122.261502726378, lat: 84.9999980009648)
        assertCorrectBearingProjection(start: start, distanceMeters: 500, bearing:135, lon:-122.276569684625, lat: 84.9968333823477)
        assertCorrectBearingProjection(start: start, distanceMeters: 500, bearing:180, lon:-122.3128663, lat: 84.9955231389167)
        assertCorrectBearingProjection(start: start, distanceMeters: 500, bearing:225, lon:-122.349162915375, lat: 84.9968333823477)
        assertCorrectBearingProjection(start: start, distanceMeters: 500, bearing:270, lon:-122.364229873622, lat: 84.9999980009648)
        assertCorrectBearingProjection(start: start, distanceMeters: 500, bearing:315, lon:-122.34920878575, lat: 85.003164618309)
    }

    func testCoordinateWithBearingFarNorth10000() {
        /*
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

*/
        let start = CLLocation.init(latitude: 85, longitude: -122.3128663)
        assertCorrectBearingProjection(start: start, distanceMeters: 10000, bearing:0, lon:-122.3128663, lat: 85.0895370934438)
        assertCorrectBearingProjection(start: start, distanceMeters: 10000, bearing:45, lon:-121.57722387973, lat: 85.0629073941419)
        assertCorrectBearingProjection(start: start, distanceMeters: 10000, bearing:90, lon:-121.285703772561, lat: 84.9992004496645)
        assertCorrectBearingProjection(start: start, distanceMeters: 10000, bearing:135, lon:-121.595572036496, lat: 84.936292772585)
        assertCorrectBearingProjection(start: start, distanceMeters: 10000, bearing:180, lon:-122.3128663, lat: 84.9104626609434)
        assertCorrectBearingProjection(start: start, distanceMeters: 10000, bearing:225, lon:-123.030160563504, lat: 84.936292772585)
        assertCorrectBearingProjection(start: start, distanceMeters: 10000, bearing:270, lon:-123.340028827439, lat: 84.9992004496645)
        assertCorrectBearingProjection(start: start, distanceMeters: 10000, bearing:315, lon:-123.04850872027, lat: 85.0629073941419)
    }

    func testCoordinateWithBearingFarNorth50000() {
        /*
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

*/
        let start = CLLocation.init(latitude: 85, longitude: -122.3128663)
        assertCorrectBearingProjection(start: start, distanceMeters: 50000, bearing:0, lon:-122.3128663, lat: 85.447683098238)
        assertCorrectBearingProjection(start: start, distanceMeters: 50000, bearing:45, lon:-118.441917077449, lat: 85.3059018482087)
        assertCorrectBearingProjection(start: start, distanceMeters: 50000, bearing:90, lon:-117.190097318035, lat: 84.9800494382655)
        assertCorrectBearingProjection(start: start, distanceMeters: 50000, bearing:135, lon:-118.900615692524, lat: 84.6740447063519)
        assertCorrectBearingProjection(start: start, distanceMeters: 50000, bearing:180, lon:-122.3128663, lat: 84.5523107615602)
        assertCorrectBearingProjection(start: start, distanceMeters: 50000, bearing:225, lon:-125.725116907476, lat: 84.6740447063519)
        assertCorrectBearingProjection(start: start, distanceMeters: 50000, bearing:270, lon:-127.435635281965, lat: 84.9800494382655)
        assertCorrectBearingProjection(start: start, distanceMeters: 50000, bearing:315, lon:-126.183815522551, lat: 85.3059018482087)
    }

    func testCoordinateWithBearingLowLatitude500() {
        /*
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

*/
        let start = CLLocation.init(latitude: 5, longitude: -122.3128663)
        assertCorrectBearingProjection(start: start, distanceMeters: 500, bearing:0, lon:-122.3128663, lat: 5.00452150216546)
        assertCorrectBearingProjection(start: start, distanceMeters: 500, bearing:45, lon:-122.309678209556, lat: 5.00319717715266)
        assertCorrectBearingProjection(start: start, distanceMeters: 500, bearing:90, lon:-122.308357681126, lat: 4.99999998449507)
        assertCorrectBearingProjection(start: start, distanceMeters: 500, bearing:135, lon:-122.309678240478, lat: 4.99680280703131)
        assertCorrectBearingProjection(start: start, distanceMeters: 500, bearing:180, lon:-122.3128663, lat: 4.99547849721233)
        assertCorrectBearingProjection(start: start, distanceMeters: 500, bearing:225, lon:-122.316054359522, lat: 4.99680280703131)
        assertCorrectBearingProjection(start: start, distanceMeters: 500, bearing:270, lon:-122.317374918874, lat: 4.99999998449507)
        assertCorrectBearingProjection(start: start, distanceMeters: 500, bearing:315, lon:-122.316054390444, lat: 5.00319717715266)
    }

    func testCoordinateWithBearingLowLatitude10000() {
        /*
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

*/
        let start = CLLocation.init(latitude: 5, longitude: -122.3128663)
        assertCorrectBearingProjection(start: start, distanceMeters: 10000, bearing:0, lon:-122.3128663, lat: 5.09042992434887)
        assertCorrectBearingProjection(start: start, distanceMeters: 10000, bearing:45, lon:-122.249098589414, lat: 5.06394052429685)
        assertCorrectBearingProjection(start: start, distanceMeters: 10000, bearing:90, lon:-122.222693923089, lat: 4.99999379803119)
        assertCorrectBearingProjection(start: start, distanceMeters: 10000, bearing:135, lon:-122.249110958015, lat: 4.93605314928675)
        assertCorrectBearingProjection(start: start, distanceMeters: 10000, bearing:180, lon:-122.3128663, lat: 4.90956982676742)
        assertCorrectBearingProjection(start: start, distanceMeters: 10000, bearing:225, lon:-122.376621641985, lat: 4.93605314928675)
        assertCorrectBearingProjection(start: start, distanceMeters: 10000, bearing:270, lon:-122.403038676911, lat: 4.99999379803119)
        assertCorrectBearingProjection(start: start, distanceMeters: 10000, bearing:315, lon:-122.376634010586, lat: 5.06394052429685)
    }

    func testCoordinateWithBearingLowLatitude50000() {
        /*
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

*/
        let start = CLLocation.init(latitude: 5, longitude: -122.3128663)
        assertCorrectBearingProjection(start: start, distanceMeters: 50000, bearing:0, lon:-122.3128663, lat: 5.4521470438799)
        assertCorrectBearingProjection(start: start, distanceMeters: 50000, bearing:45, lon:-121.99390085599, lat: 5.31963770686063)
        assertCorrectBearingProjection(start: start, distanceMeters: 50000, bearing:90, lon:-121.862004483307, lat: 4.99984495156423)
        assertCorrectBearingProjection(start: start, distanceMeters: 50000, bearing:135, lon:-121.994210074066, lat: 4.68020413013662)
        assertCorrectBearingProjection(start: start, distanceMeters: 50000, bearing:180, lon:-122.3128663, lat: 4.54784673415444)
        assertCorrectBearingProjection(start: start, distanceMeters: 50000, bearing:225, lon:-122.631522525934, lat: 4.68020413013662)
        assertCorrectBearingProjection(start: start, distanceMeters: 50000, bearing:270, lon:-122.763728116693, lat: 4.99984495156423)
        assertCorrectBearingProjection(start: start, distanceMeters: 50000, bearing:315, lon:-122.63183174401, lat: 5.31963770686063)
    }

    func testCoordinateWithBearingSouthernHemisphere500() {
        /*
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

*/
        let start = CLLocation.init(latitude: -40, longitude: -122.3128663)
        assertCorrectBearingProjection(start: start, distanceMeters: 500, bearing:0, lon:-122.3128663, lat: -39.9954968987312)
        assertCorrectBearingProjection(start: start, distanceMeters: 500, bearing:45, lon:-122.308726225035, lat: -39.9968157529746)
        assertCorrectBearingProjection(start: start, distanceMeters: 500, bearing:90, lon:-122.30701107789, lat: -39.9999998520994)
        assertCorrectBearingProjection(start: start, distanceMeters: 500, bearing:135, lon:-122.308725840415, lat: -40.00318409737)
        assertCorrectBearingProjection(start: start, distanceMeters: 500, bearing:180, lon:-122.3128663, lat: -40.0045030977592)
        assertCorrectBearingProjection(start: start, distanceMeters: 500, bearing:225, lon:-122.317006759585, lat: -40.00318409737)
        assertCorrectBearingProjection(start: start, distanceMeters: 500, bearing:270, lon:-122.318721522109, lat: -39.9999998520994)
        assertCorrectBearingProjection(start: start, distanceMeters: 500, bearing:315, lon:-122.317006374965, lat: -39.9968157529746)
    }

    func testCoordinateWithBearingSouthernHemisphere10000() {
        /*
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

*/
        let start = CLLocation.init(latitude: -40, longitude: -122.3128663)
        assertCorrectBearingProjection(start: start, distanceMeters: 10000, bearing:0, lon:-122.3128663, lat: -39.9099373079262)
        assertCorrectBearingProjection(start: start, distanceMeters: 10000, bearing:45, lon:-122.230137797083, lat: -39.9362866650944)
        assertCorrectBearingProjection(start: start, distanceMeters: 10000, bearing:90, lon:-122.195761925015, lat: -39.9999408398175)
        assertCorrectBearingProjection(start: start, distanceMeters: 10000, bearing:135, lon:-122.229983949109, lat: -40.0636534726882)
        assertCorrectBearingProjection(start: start, distanceMeters: 10000, bearing:180, lon:-122.3128663, lat: -40.0900612882388)
        assertCorrectBearingProjection(start: start, distanceMeters: 10000, bearing:225, lon:-122.395748650891, lat: -40.0636534726882)
        assertCorrectBearingProjection(start: start, distanceMeters: 10000, bearing:270, lon:-122.429970674985, lat: -39.9999408398175)
        assertCorrectBearingProjection(start: start, distanceMeters: 10000, bearing:315, lon:-122.395594802917, lat: -39.9362866650943)
    }

    func testCoordinateWithBearingSouthernHemisphere50000() {
        /*
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

*/
        let start = CLLocation.init(latitude: -40, longitude: -122.3128663)
        assertCorrectBearingProjection(start: start, distanceMeters: 50000, bearing:0, lon:-122.3128663, lat: -39.5496725166091)
        assertCorrectBearingProjection(start: start, distanceMeters: 50000, bearing:45, lon:-121.900752491598, lat: -39.6808395104955)
        assertCorrectBearingProjection(start: start, distanceMeters: 50000, bearing:90, lon:-121.727352509562, lat: -39.9985210178516)
        assertCorrectBearingProjection(start: start, distanceMeters: 50000, bearing:135, lon:-121.896906254532, lat: -40.3176638863652)
        assertCorrectBearingProjection(start: start, distanceMeters: 50000, bearing:180, lon:-122.3128663, lat: -40.4502923882122)
        assertCorrectBearingProjection(start: start, distanceMeters: 50000, bearing:225, lon:-122.728826345467, lat: -40.3176638863652)
        assertCorrectBearingProjection(start: start, distanceMeters: 50000, bearing:270, lon:-122.898380090438, lat: -39.9985210178516)
        assertCorrectBearingProjection(start: start, distanceMeters: 50000, bearing:315, lon:-122.724980108402, lat: -39.6808395104955)
    }

    /*
     Here is the original transcript of the PostGIS session for coordinateWithBearing/assertCorrectBearingProjection.
     
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
