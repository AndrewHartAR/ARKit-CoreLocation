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

// MARK: test runners

    /// Verify that the CLLocation extension function `coordinateWithBearing(bearing:distanceMeters:)` works correctly.
    ///
    /// Tested:
    /// - longitude accuracy and latitude accuracy within absolute limits of 0.001 degrees.
    /// - distance from computed point to correct point less than 100 meters.
    /// - max angular error (assuming error distance is perpendicular to bearing) less than 5 degrees.
    ///
    /// Parameter order is `lon`, `lat` because the GIS software I'm using to produce the comparison values assumes `(x, y)` (as does most
    /// GIS software). This makes it easier to generate calls with an editing macro, and to compare the call to the comparison values.
    /// - Parameters:
    ///     - start: passed as the `start:` parameter to the function.
    ///     - distanceMeters: passed as the `distanceMeters` parameter to the function.
    ///     - bearing: passed as the `bearing` parameter to the function.
    ///     - lon: longitude of the correct result.
    ///     - lat: latitude of the correct result.
    ///     - file: reference to #file to make the failure message appear at the point of call.
    ///     - line: reference to #line to make the failure message appear at the point of call.
    func assertCorrectBearingProjection(start: CLLocation, distanceMeters: Double, bearing: Double, lon: Double, lat: Double, file: StaticString = #file,
    line: UInt = #line) {
        // Thanks to https://medium.com/bleeding-edge/writing-better-unit-tests-in-swift-part-two-d19b69f3d794 for the #file/#line trick!
        // 1 nautical mile ~= 2000 yards. 1 degree of latitude = 60 nautical miles.
        let longitudeAccuracy = 0.001 // 120 yards at equator, 85 yards at +/-45 degrees latitude
        let latitudeAccuracy = 0.001  // 120 yards

        let startPoint = start.coordinate
        let resultPoint = startPoint.coordinateWithBearing(bearing: bearing, distanceMeters: distanceMeters)

        // Calculated lat/lon must be within limits.
        XCTAssertEqual(resultPoint.latitude, lat, accuracy: latitudeAccuracy, "latitude difference exceeds limit", file: file, line: line)
        XCTAssertEqual(resultPoint.longitude, lon, accuracy: longitudeAccuracy, "longitude difference exceeds limit", file: file, line: line)
        
        // Calculated location must be no farther than 100 meters from correct location.
        let resultLocation = CLLocation.init(coordinate: resultPoint, altitude: 0)
        let distanceError = resultLocation.distance(from: CLLocation.init(latitude: lat, longitude: lon))
        XCTAssertLessThan(distanceError, 100.0, "distance between correct and computed locations exceeds limit", file: file, line: line)

        // Angular error less than 5 degrees, if the error distance is perpendicular to the line of sight.
        // An angular error of 5 degrees is about twice the width of your thumb at arm's length.
        let maxAngularError = 5.0 * .pi / 180
        // distanceError/distanceMeters is the sin of the max angular error.
        XCTAssertLessThan(distanceError / distanceMeters, sin(maxAngularError), "max angular error exceeds limit", file: file, line: line)
    }
    
    /// Verify that the CLLocation extension function `bearing(between:)` works correctly.
    ///
    /// Tested:
    /// - error between computed and correct bearing less than 0.1 degrees.
    ///
    /// Parameter order is `lon`, `lat` because the GIS software I'm using to produce the comparison values assumes `(x, y)` (as does most
    /// GIS software). This makes it easier to generate calls with an editing macro, and to compare the call to the comparison values.
    /// - Parameters:
    ///     - start: passed as the `start:` parameter to the function.
    ///     - lon: longitude of the test destination result.
    ///     - lat: latitude of the test destination result.
    ///     - correctBearing: the correct result.
    ///     - file: reference to #file to make the failure message appear at the point of call.
    ///     - line: reference to #line to make the failure message appear at the point of call.
    func assertCorrectBearingComputation(start: CLLocation, lon: Double, lat: Double, correctBearing: Double, file: StaticString = #file,
    line: UInt = #line) {
        let maxBearingErrorDegrees = 0.5
        let destination = CLLocation.init(latitude: lat, longitude: lon)
        let computedBearing = start.bearing(between: destination)
        // Now force result into range 0-360:
        let adjustedComputedBearing = (computedBearing + 360.0).truncatingRemainder(dividingBy: 360.0)
        XCTAssertEqual(adjustedComputedBearing, correctBearing, accuracy: maxBearingErrorDegrees, "difference in bearing to second point exceeds limit", file: file, line: line)
    }

    func assertCorrectTranslationDistance(start: CLLocation, distanceMeters: Double, bearing: Double, lon: Double, lat: Double, file: StaticString = #file,
                                              line: UInt = #line) {
        let requiredAccuracy = distanceMeters * 0.01 // 1% of actual distance
        let maxBearingErrorDegrees = 0.5
        let endLocation = CLLocation(latitude: lat, longitude: lon)
        
        let translation = start.translation(toLocation: endLocation)
        let translationDistance = sqrt(translation.latitudeTranslation * translation.latitudeTranslation + translation.longitudeTranslation * translation.longitudeTranslation)
        XCTAssertEqual(distanceMeters, translationDistance, accuracy: requiredAccuracy, file: file, line: line)
        
        let translationAngle = (450.0 - atan2(translation.latitudeTranslation, translation.longitudeTranslation).radiansToDegrees).truncatingRemainder(dividingBy: 360.0)
        print(bearing, translationAngle)
        XCTAssertEqual(translationAngle, bearing, accuracy: maxBearingErrorDegrees, file: file, line: line)
    }

    /// Test the `CLLocation` extention function `translation(toLocation:)`. Translation from point defined by `lat0, lon0` (Point 0)
    ///  to  `lat1, lon1` (Point 1) must be correct to within 10 meters. Right triangle hypotenuse of the translations must equal the original translation radius.
    ///
    ///  This function is way too complicated.
    ///
    /// - Parameters:
    ///     - bearing: original bearing used in ground-truth computation of Point 1.
    ///     - radius: distance in meters from Point 1 to Point 2.
    ///     - lon0: degrees.
    ///     - lat0: degrees.
    ///     - east0: easting, in meters, of rectangular projection of Point 0.
    ///     - north0: northing, in meters, of rectangular projection of Point 0.
    ///     - lon1: degrees.
    ///     - lat1: degrees.
    ///     - east1: easting, in meters, of rectangular projection of Point 1.
    ///     - north1: northing, in meters, of rectangular projection of Point 1.
    func assertCorrectTranslationComputations(bearing: Double, radius: Double,
                                              lon0: Double, lat0: Double, east0: Double, north0:  Double,
                                              lon1: Double, lat1: Double, east1: Double, north1: Double,
                                              file: StaticString = #file, line: UInt = #line) {
        let metersAccuracy = 10.0
        
        let startPoint = CLLocation(latitude: lat0, longitude: lon0)
        let endPoint = CLLocation(latitude: lat1, longitude: lon1)
        let eastingDelta = east1 - east0
        let northingDelta = north1 - north0
        let computedTranslation = startPoint.translation(toLocation: endPoint)
        print(computedTranslation)
        XCTAssertEqual(eastingDelta, computedTranslation.longitudeTranslation, accuracy: metersAccuracy, "longitude translation error exceeds limit", file: file, line: line)
        XCTAssertEqual(northingDelta, computedTranslation.latitudeTranslation, accuracy: metersAccuracy, "longitude translation error exceeds limit", file: file, line: line)
        XCTAssertEqual(sqrt(eastingDelta*eastingDelta + northingDelta*northingDelta), radius, accuracy: metersAccuracy, "radius wrong", file: file, line: line)
    }

    // MARK: - tests

    // TODO: this test doesn't appear to test anything. Looks like the expected value axes are reversed, and
    // a .01 accuracy translates to 1200 yards north/south, about 850 yards east/west
    // at this latitude.
    // Leaving it in for now because it's the only green test :-(
    func testBearing() {
        let pub = CLLocationCoordinate2D(latitude: 47.6235858, longitude: -122.3128663)

        let north = pub.coordinateWithBearing(bearing: 0, distanceMeters: 500)
        // Assert: if I move north 500 meters, my northing has changed by less than 1200 yards.
        XCTAssertEqual(pub.latitude, north.latitude, accuracy: 0.01)

        let east = pub.coordinateWithBearing(bearing: 90, distanceMeters: 500)
        // Assert: if I move east 500 meters, my easting has changed by less than 800 yards.
        XCTAssertEqual(pub.longitude, east.longitude, accuracy: 0.01)
    }


    // MARK: - CLLocation.coordinateWithBearing(bearing:distanceMeters:)
    
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

    // MARK: - CLLocation.bearing(between)
    
    func testAzimuthMidLatitude500() {
        // Points are 500 meters apart. Same data as in testCoordinateWithBearingMidLatitude500() above.
/*      bearing |                 st_astext
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
*/
        let start = CLLocation.init(latitude: 47.6235858, longitude: -122.3128663)
        assertCorrectBearingComputation(start: start, lon: -122.3128663, lat:  47.6280828887704, correctBearing: 0.0)
        assertCorrectBearingComputation(start: start, lon: -122.308162416608, lat: 47.6267656259013, correctBearing: 45.0)
        assertCorrectBearingComputation(start: start, lon: -122.306214407755, lat: 47.6235856071536, correctBearing: 90.0)
        assertCorrectBearingComputation(start: start, lon: -122.308162987107, lat: 47.620405779481, correctBearing: 135.0)
        assertCorrectBearingComputation(start: start, lon: -122.3128663, lat: 47.6190887076871, correctBearing: 180.0)
        assertCorrectBearingComputation(start: start, lon: -122.317569612893, lat: 47.620405779481, correctBearing: 225.0)
        assertCorrectBearingComputation(start: start, lon: -122.319518192245, lat: 47.6235856071536, correctBearing: 270.0)
        assertCorrectBearingComputation(start: start, lon: -122.317570183392, lat: 47.6267656259013, correctBearing: 315.0)
    }
    
    func testAzimuthMidLatitude10000() {
        // Points are 10000 meters apart. Same data as in testCoordinateWithBearingMidLatitude10000() above.
        /*      select bearing,ST_AsText(ST_Project('POINT(-122.3128663 47.6235858)'::geography, 10000, radians(bearing)))
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
*/
        let start = CLLocation.init(latitude: 47.6235858, longitude: -122.3128663)
        assertCorrectBearingComputation(start: start, lon: -122.3128663, lat: 47.7135269024092, correctBearing: 0.0)
        assertCorrectBearingComputation(start: start, lon: -122.218680106776, lat: 47.6871452814007, correctBearing: 45.0)
        assertCorrectBearingComputation(start: start, lon: -122.179828585245, lat: 47.6235086614964, correctBearing: 90.0)
        assertCorrectBearingComputation(start: start, lon: -122.218908306631, lat: 47.5599484713877, correctBearing: 135.0)
        assertCorrectBearingComputation(start: start, lon: -122.3128663, lat: 47.5336432805981, correctBearing: 180.0)
        assertCorrectBearingComputation(start: start, lon: -122.406824293369, lat: 47.5599484713877, correctBearing: 225.0)
        assertCorrectBearingComputation(start: start, lon: -122.445904014755, lat: 47.6235086614964, correctBearing: 270.0)
        assertCorrectBearingComputation(start: start, lon: -122.407052493224, lat: 47.6871452814007, correctBearing: 315.0)
    }
    
    func testAzimuthMidLatitude50000() {
        // Points are 500000 meters apart. Same data as in testCoordinateWithBearingMidLatitude50000() above.
        /*
         select bearing,ST_AsText(ST_Project('POINT(-122.3128663 47.6235858)'::geography, 50000, radians(bearing)))
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
*/
        let start = CLLocation.init(latitude: 47.6235858, longitude: -122.3128663)
        assertCorrectBearingComputation(start: start, lon: -122.3128663, lat: 48.0732771512326, correctBearing: 0.0)
        assertCorrectBearingComputation(start: start, lon: -121.839637614568, lat: 47.9405975715807, correctBearing: 45.0)
        assertCorrectBearingComputation(start: start, lon: -121.647693382546, lat: 47.6216573806133, correctBearing: 90.0)
        assertCorrectBearingComputation(start: start, lon: -121.845342666805, lat: 47.3046277647178, correctBearing: 135.0)
        assertCorrectBearingComputation(start: start, lon: -122.3128663, lat: 47.1738590246445, correctBearing: 180.0)
        assertCorrectBearingComputation(start: start, lon: -122.780389933195, lat: 47.3046277647178, correctBearing: 225.0)
        assertCorrectBearingComputation(start: start, lon: -122.978039217454, lat: 47.6216573806133, correctBearing: 270.0)
        assertCorrectBearingComputation(start: start, lon: -122.786094985432, lat: 47.9405975715807, correctBearing: 315.0)
    }

    // MARK: - CLLocation.translation

        
    func testTranslationMidLatitude500() {
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
        assertCorrectTranslationDistance(start: start, distanceMeters: 500, bearing: 0, lon:-122.3128663, lat: 47.6280828887704)
        assertCorrectTranslationDistance(start: start, distanceMeters: 500, bearing: 45, lon: -122.308162416608, lat: 47.6267656259013)
        assertCorrectTranslationDistance(start: start, distanceMeters: 500, bearing: 90, lon:-122.306214407755, lat: 47.6235856071536)
        assertCorrectTranslationDistance(start: start, distanceMeters: 500, bearing:135, lon:-122.308162987107, lat: 47.620405779481)
            assertCorrectTranslationDistance(start: start, distanceMeters: 500, bearing:180, lon:-122.3128663, lat: 47.6190887076871)
            assertCorrectTranslationDistance(start: start, distanceMeters: 500, bearing:225, lon:-122.317569612893, lat: 47.620405779481)
            assertCorrectTranslationDistance(start: start, distanceMeters: 500, bearing:270, lon:-122.319518192245, lat: 47.6235856071536)
            assertCorrectTranslationDistance(start: start, distanceMeters: 500, bearing:315, lon:-122.317570183392, lat: 47.6267656259013)
        }

        func testTranslationMidLatitude10000() {
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
            assertCorrectTranslationDistance(start: start, distanceMeters: 10000, bearing: 0, lon:-122.3128663, lat: 47.7135269024092)
            assertCorrectTranslationDistance(start: start, distanceMeters: 10000, bearing:45, lon:-122.218680106776, lat: 47.6871452814007)
            assertCorrectTranslationDistance(start: start, distanceMeters: 10000, bearing:90, lon:-122.179828585245, lat: 47.6235086614964)
            assertCorrectTranslationDistance(start: start, distanceMeters: 10000, bearing:135, lon:-122.218908306631, lat: 47.5599484713877)
            assertCorrectTranslationDistance(start: start, distanceMeters: 10000, bearing:180, lon:-122.3128663, lat: 47.5336432805981)
            assertCorrectTranslationDistance(start: start, distanceMeters: 10000, bearing:225, lon:-122.406824293369, lat: 47.5599484713877)
            assertCorrectTranslationDistance(start: start, distanceMeters: 10000, bearing:270, lon:-122.445904014755, lat: 47.6235086614964)
            assertCorrectTranslationDistance(start: start, distanceMeters: 10000, bearing:315, lon:-122.407052493224, lat: 47.6871452814007)
        }

        func testTranslationMidLatitude50000() {
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
            assertCorrectTranslationDistance(start: start, distanceMeters: 50000, bearing:0, lon:-122.3128663, lat: 48.0732771512326)
            assertCorrectTranslationDistance(start: start, distanceMeters: 50000, bearing:45, lon:-121.839637614568, lat: 47.9405975715807)
            assertCorrectTranslationDistance(start: start, distanceMeters: 50000, bearing:90, lon:-121.647693382546, lat: 47.6216573806133)
            assertCorrectTranslationDistance(start: start, distanceMeters: 50000, bearing:135, lon:-121.845342666805, lat: 47.3046277647178)
            assertCorrectTranslationDistance(start: start, distanceMeters: 50000, bearing:180, lon:-122.3128663, lat: 47.1738590246445)
            assertCorrectTranslationDistance(start: start, distanceMeters: 50000, bearing:225, lon:-122.780389933195, lat: 47.3046277647178)
            assertCorrectTranslationDistance(start: start, distanceMeters: 50000, bearing:270, lon:-122.978039217454, lat: 47.6216573806133)
            assertCorrectTranslationDistance(start: start, distanceMeters: 50000, bearing:315, lon:-122.786094985432, lat: 47.9405975715807)
        }

        func testTranslationFarNorth500() {
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
            assertCorrectTranslationDistance(start: start, distanceMeters: 500, bearing:0, lon:-122.3128663, lat: 85.0044768604693)
            assertCorrectTranslationDistance(start: start, distanceMeters: 500, bearing:45, lon:-122.27652381425, lat: 85.003164618309)
            assertCorrectTranslationDistance(start: start, distanceMeters: 500, bearing:90, lon:-122.261502726378, lat: 84.9999980009648)
            assertCorrectTranslationDistance(start: start, distanceMeters: 500, bearing:135, lon:-122.276569684625, lat: 84.9968333823477)
            assertCorrectTranslationDistance(start: start, distanceMeters: 500, bearing:180, lon:-122.3128663, lat: 84.9955231389167)
            assertCorrectTranslationDistance(start: start, distanceMeters: 500, bearing:225, lon:-122.349162915375, lat: 84.9968333823477)
            assertCorrectTranslationDistance(start: start, distanceMeters: 500, bearing:270, lon:-122.364229873622, lat: 84.9999980009648)
            assertCorrectTranslationDistance(start: start, distanceMeters: 500, bearing:315, lon:-122.34920878575, lat: 85.003164618309)
        }

        func testTranslationFarNorth10000() {
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
            assertCorrectTranslationDistance(start: start, distanceMeters: 10000, bearing:0, lon:-122.3128663, lat: 85.0895370934438)
            assertCorrectTranslationDistance(start: start, distanceMeters: 10000, bearing:45, lon:-121.57722387973, lat: 85.0629073941419)
            assertCorrectTranslationDistance(start: start, distanceMeters: 10000, bearing:90, lon:-121.285703772561, lat: 84.9992004496645)
            assertCorrectTranslationDistance(start: start, distanceMeters: 10000, bearing:135, lon:-121.595572036496, lat: 84.936292772585)
            assertCorrectTranslationDistance(start: start, distanceMeters: 10000, bearing:180, lon:-122.3128663, lat: 84.9104626609434)
            assertCorrectTranslationDistance(start: start, distanceMeters: 10000, bearing:225, lon:-123.030160563504, lat: 84.936292772585)
            assertCorrectTranslationDistance(start: start, distanceMeters: 10000, bearing:270, lon:-123.340028827439, lat: 84.9992004496645)
            assertCorrectTranslationDistance(start: start, distanceMeters: 10000, bearing:315, lon:-123.04850872027, lat: 85.0629073941419)
        }

        func testTranslationFarNorth50000() {
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
            assertCorrectTranslationDistance(start: start, distanceMeters: 50000, bearing:0, lon:-122.3128663, lat: 85.447683098238)
            assertCorrectTranslationDistance(start: start, distanceMeters: 50000, bearing:45, lon:-118.441917077449, lat: 85.3059018482087)
            assertCorrectTranslationDistance(start: start, distanceMeters: 50000, bearing:90, lon:-117.190097318035, lat: 84.9800494382655)
            assertCorrectTranslationDistance(start: start, distanceMeters: 50000, bearing:135, lon:-118.900615692524, lat: 84.6740447063519)
            assertCorrectTranslationDistance(start: start, distanceMeters: 50000, bearing:180, lon:-122.3128663, lat: 84.5523107615602)
            assertCorrectTranslationDistance(start: start, distanceMeters: 50000, bearing:225, lon:-125.725116907476, lat: 84.6740447063519)
            assertCorrectTranslationDistance(start: start, distanceMeters: 50000, bearing:270, lon:-127.435635281965, lat: 84.9800494382655)
            assertCorrectTranslationDistance(start: start, distanceMeters: 50000, bearing:315, lon:-126.183815522551, lat: 85.3059018482087)
        }

        func testTranslationLowLatitude500() {
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
            assertCorrectTranslationDistance(start: start, distanceMeters: 500, bearing:0, lon:-122.3128663, lat: 5.00452150216546)
            assertCorrectTranslationDistance(start: start, distanceMeters: 500, bearing:45, lon:-122.309678209556, lat: 5.00319717715266)
            assertCorrectTranslationDistance(start: start, distanceMeters: 500, bearing:90, lon:-122.308357681126, lat: 4.99999998449507)
            assertCorrectTranslationDistance(start: start, distanceMeters: 500, bearing:135, lon:-122.309678240478, lat: 4.99680280703131)
            assertCorrectTranslationDistance(start: start, distanceMeters: 500, bearing:180, lon:-122.3128663, lat: 4.99547849721233)
            assertCorrectTranslationDistance(start: start, distanceMeters: 500, bearing:225, lon:-122.316054359522, lat: 4.99680280703131)
            assertCorrectTranslationDistance(start: start, distanceMeters: 500, bearing:270, lon:-122.317374918874, lat: 4.99999998449507)
            assertCorrectTranslationDistance(start: start, distanceMeters: 500, bearing:315, lon:-122.316054390444, lat: 5.00319717715266)
        }

        func testTranslationLowLatitude10000() {
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
            assertCorrectTranslationDistance(start: start, distanceMeters: 10000, bearing:0, lon:-122.3128663, lat: 5.09042992434887)
            assertCorrectTranslationDistance(start: start, distanceMeters: 10000, bearing:45, lon:-122.249098589414, lat: 5.06394052429685)
            assertCorrectTranslationDistance(start: start, distanceMeters: 10000, bearing:90, lon:-122.222693923089, lat: 4.99999379803119)
            assertCorrectTranslationDistance(start: start, distanceMeters: 10000, bearing:135, lon:-122.249110958015, lat: 4.93605314928675)
            assertCorrectTranslationDistance(start: start, distanceMeters: 10000, bearing:180, lon:-122.3128663, lat: 4.90956982676742)
            assertCorrectTranslationDistance(start: start, distanceMeters: 10000, bearing:225, lon:-122.376621641985, lat: 4.93605314928675)
            assertCorrectTranslationDistance(start: start, distanceMeters: 10000, bearing:270, lon:-122.403038676911, lat: 4.99999379803119)
            assertCorrectTranslationDistance(start: start, distanceMeters: 10000, bearing:315, lon:-122.376634010586, lat: 5.06394052429685)
        }

        func testTranslationLowLatitude50000() {
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
            assertCorrectTranslationDistance(start: start, distanceMeters: 50000, bearing:0, lon:-122.3128663, lat: 5.4521470438799)
            assertCorrectTranslationDistance(start: start, distanceMeters: 50000, bearing:45, lon:-121.99390085599, lat: 5.31963770686063)
            assertCorrectTranslationDistance(start: start, distanceMeters: 50000, bearing:90, lon:-121.862004483307, lat: 4.99984495156423)
            assertCorrectTranslationDistance(start: start, distanceMeters: 50000, bearing:135, lon:-121.994210074066, lat: 4.68020413013662)
            assertCorrectTranslationDistance(start: start, distanceMeters: 50000, bearing:180, lon:-122.3128663, lat: 4.54784673415444)
            assertCorrectTranslationDistance(start: start, distanceMeters: 50000, bearing:225, lon:-122.631522525934, lat: 4.68020413013662)
            assertCorrectTranslationDistance(start: start, distanceMeters: 50000, bearing:270, lon:-122.763728116693, lat: 4.99984495156423)
            assertCorrectTranslationDistance(start: start, distanceMeters: 50000, bearing:315, lon:-122.63183174401, lat: 5.31963770686063)
        }

        func testTranslationSouthernHemisphere500() {
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
            assertCorrectTranslationDistance(start: start, distanceMeters: 500, bearing:0, lon:-122.3128663, lat: -39.9954968987312)
            assertCorrectTranslationDistance(start: start, distanceMeters: 500, bearing:45, lon:-122.308726225035, lat: -39.9968157529746)
            assertCorrectTranslationDistance(start: start, distanceMeters: 500, bearing:90, lon:-122.30701107789, lat: -39.9999998520994)
            assertCorrectTranslationDistance(start: start, distanceMeters: 500, bearing:135, lon:-122.308725840415, lat: -40.00318409737)
            assertCorrectTranslationDistance(start: start, distanceMeters: 500, bearing:180, lon:-122.3128663, lat: -40.0045030977592)
            assertCorrectTranslationDistance(start: start, distanceMeters: 500, bearing:225, lon:-122.317006759585, lat: -40.00318409737)
            assertCorrectTranslationDistance(start: start, distanceMeters: 500, bearing:270, lon:-122.318721522109, lat: -39.9999998520994)
            assertCorrectTranslationDistance(start: start, distanceMeters: 500, bearing:315, lon:-122.317006374965, lat: -39.9968157529746)
        }

        func testTranslationSouthernHemisphere10000() {
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
            assertCorrectTranslationDistance(start: start, distanceMeters: 10000, bearing:0, lon:-122.3128663, lat: -39.9099373079262)
            assertCorrectTranslationDistance(start: start, distanceMeters: 10000, bearing:45, lon:-122.230137797083, lat: -39.9362866650944)
            assertCorrectTranslationDistance(start: start, distanceMeters: 10000, bearing:90, lon:-122.195761925015, lat: -39.9999408398175)
            assertCorrectTranslationDistance(start: start, distanceMeters: 10000, bearing:135, lon:-122.229983949109, lat: -40.0636534726882)
            assertCorrectTranslationDistance(start: start, distanceMeters: 10000, bearing:180, lon:-122.3128663, lat: -40.0900612882388)
            assertCorrectTranslationDistance(start: start, distanceMeters: 10000, bearing:225, lon:-122.395748650891, lat: -40.0636534726882)
            assertCorrectTranslationDistance(start: start, distanceMeters: 10000, bearing:270, lon:-122.429970674985, lat: -39.9999408398175)
            assertCorrectTranslationDistance(start: start, distanceMeters: 10000, bearing:315, lon:-122.395594802917, lat: -39.9362866650943)
        }

        func testTranslationSouthernHemisphere50000() {
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
            assertCorrectTranslationDistance(start: start, distanceMeters: 50000, bearing:0, lon:-122.3128663, lat: -39.5496725166091)
            assertCorrectTranslationDistance(start: start, distanceMeters: 50000, bearing:45, lon:-121.900752491598, lat: -39.6808395104955)
            assertCorrectTranslationDistance(start: start, distanceMeters: 50000, bearing:90, lon:-121.727352509562, lat: -39.9985210178516)
            assertCorrectTranslationDistance(start: start, distanceMeters: 50000, bearing:135, lon:-121.896906254532, lat: -40.3176638863652)
            assertCorrectTranslationDistance(start: start, distanceMeters: 50000, bearing:180, lon:-122.3128663, lat: -40.4502923882122)
            assertCorrectTranslationDistance(start: start, distanceMeters: 50000, bearing:225, lon:-122.728826345467, lat: -40.3176638863652)
            assertCorrectTranslationDistance(start: start, distanceMeters: 50000, bearing:270, lon:-122.898380090438, lat: -39.9985210178516)
            assertCorrectTranslationDistance(start: start, distanceMeters: 50000, bearing:315, lon:-122.724980108402, lat: -39.6808395104955)
        }


    /// Uses the same geographic points as the previous mid-latitude 500 meter tests. Any expansion of this particular test would
    /// warrant a bit of Python code to generate the PostGIS calls and emit the `assertCorrectTranslationComputations`
    /// invocations.
    func testTranslationMidLatitude500Old() {
        
        assertCorrectTranslationComputations(bearing: 45, radius: 500, lon0: 122.3128663, lat0: 47.6235858, east0: -13615805.9939818, north0:  6044459.82841367 ,lon1:  -122.308162416608, lat1: 47.6267656259013, east1: -13615282.3600778, north1: 6044985.0335112)
        assertCorrectTranslationComputations(bearing: 90, radius: 500, lon0: 122.3128663, lat0: 47.6235858, east0: -13615805.9939818, north0:  6044459.82841367 ,lon1:  -122.306214407755, lat1: 47.6235856071536, east1: -13615065.5087242, north1: 6044459.7965626)
        assertCorrectTranslationComputations(bearing: 135, radius: 500, lon0: 122.3128663, lat0: 47.6235858, east0: -13615805.9939818, north0:  6044459.82841367 ,lon1:  -122.308162987107, lat1: 47.620405779481, east1: -13615282.4235855, north1: 6043934.6231210)
        assertCorrectTranslationComputations(bearing: 180, radius: 500, lon0: 122.3128663, lat0: 47.6235858, east0: -13615805.9939818, north0:  6044459.82841367 ,lon1:  -122.3128663, lat1: 47.6190887076871, east1: -13615805.9939818, north1: 6043717.1077554)
        assertCorrectTranslationComputations(bearing: 225, radius: 500, lon0: 122.3128663, lat0: 47.6235858, east0: -13615805.9939818, north0:  6044459.82841367 ,lon1:  -122.317569612893, lat1: 47.620405779481, east1: -13616329.564378, north1: 6043934.6231210)
        assertCorrectTranslationComputations(bearing: 270, radius: 500, lon0: 122.3128663, lat0: 47.6235858, east0: -13615805.9939818, north0:  6044459.82841367 ,lon1:  -122.319518192245, lat1: 47.6235856071536, east1: -13616546.4792393, north1: 6044459.7965626)
        assertCorrectTranslationComputations(bearing: 315, radius: 500, lon0: 122.3128663, lat0: 47.6235858, east0: -13615805.9939818, north0:  6044459.82841367 ,lon1:  -122.317570183392, lat1: 47.626765625901, east1: -13616329.6278857, north1: 6044985.0335112)
	 

    }
    
    // MARK: - PostGIS
    // MARK: coordinateWithBearing
    /*
     Here is the original transcript of the PostGIS session for coordinateWithBearing/assertCorrectBearingProjection.
     
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
     (8 rows)

     
      select bearing,ST_AsText(ST_Project('POINT(-122.3128663 47.6235858)'::geography, 10000, radians(bearing)))
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

      select bearing,ST_AsText(ST_Project('POINT(-122.3128663 47.6235858)'::geography, 50000, radians(bearing)))
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

      select bearing,ST_AsText(ST_Project('POINT(-122.3128663 85)'::geography, 50000, radians(bearing)))
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

      select bearing,ST_AsText(ST_Project('POINT(-122.3128663 85)'::geography, 10000, radians(bearing)))
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

      select bearing,ST_AsText(ST_Project('POINT(-122.3128663 85)'::geography, 500, radians(bearing)))
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

               select bearing,ST_AsText(ST_Project('POINT(-122.3128663 5)'::geography, 500, radians(bearing)))
                        from (
                            values (0),(45),(90),(135),(180),(225),(270),(315)
                        ) s(bearing);
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

     
               select bearing,ST_AsText(ST_Project('POINT(-122.3128663 5)'::geography, 500, radians(bearing)))
                        from (
                            values (0),(45),(90),(135),(180),(225),(270),(315)
                        ) s(bearing);
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

     
               select bearing,ST_AsText(ST_Project('POINT(-122.3128663 5)'::geography, 500, radians(bearing)))
                        from (
                            values (0),(45),(90),(135),(180),(225),(270),(315)
                        ) s(bearing);
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

     
               select bearing,ST_AsText(ST_Project('POINT(-122.3128663 5)'::geography, 10000, radians(bearing)))
                        from (
                            values (0),(45),(90),(135),(180),(225),(270),(315)
                        ) s(bearing);
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

     
               select bearing,ST_AsText(ST_Project('POINT(-122.3128663 5)'::geography, 50000, radians(bearing)))
                        from (
                            values (0),(45),(90),(135),(180),(225),(270),(315)
                        ) s(bearing);
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

               select bearing,ST_AsText(ST_Project('POINT(-122.3128663 -40)'::geography, 500, radians(bearing)))
                        from (
                            values (0),(45),(90),(135),(180),(225),(270),(315)
                        ) s(bearing);
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

     
               select bearing,ST_AsText(ST_Project('POINT(-122.3128663 -40)'::geography, 10000, radians(bearing)))
                        from (
                            values (0),(45),(90),(135),(180),(225),(270),(315)
                        ) s(bearing);
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

     
               select bearing,ST_AsText(ST_Project('POINT(-122.3128663 -40)'::geography, 50000, radians(bearing)))
                        from (
                            values (0),(45),(90),(135),(180),(225),(270),(315)
                        ) s(bearing);
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
    
    // MARK: bearing to point

    /*
    select ST_AsText(destination),degrees(ST_Azimuth('POINT(-122.3128663 47.6235858)'::geography, destination))
             from (
    values ('POINT(-122.3128663 47.6280828887704)'::geography),
    ('POINT(-122.308162416608 47.6267656259013)'::geography),
    ('POINT(-122.306214407755 47.6235856071536)'::geography),
    ('POINT(-122.308162987107 47.620405779481)'::geography),
    ('POINT(-122.3128663 47.6190887076871)'::geography),
    ('POINT(-122.317569612893 47.620405779481)'::geography),
    ('POINT(-122.319518192245 47.6235856071536)'::geography),
    ('POINT(-122.317570183392 47.6267656259013)'::geography)
              ) s(destination);
     */

    // MARK: test data for testing translations
    /*
     Reproject to Web Mercator (EPSG 3857, informally 900913.
     
     These points came from the circular sweep, 45 degree increments, at 500 meter radius used in
     select ST_AsText(ST_Transform(ST_SetSRID(ST_MakePoint(-122.3128663, 47.6235858), 4326), 3857)) as start,
         ST_AsText(ST_Transform(ST_SetSRID(destination, 4326), 3857)) as finish
              from (
     values (ST_MakePoint(-122.3128663, 47.6280828887704)),
     (ST_MakePoint(-122.308162416608, 47.6267656259013)),
     (ST_MakePoint(-122.306214407755, 47.6235856071536)),
     (ST_MakePoint(-122.308162987107, 47.620405779481)),
     (ST_MakePoint(-122.3128663, 47.6190887076871)),
     (ST_MakePoint(-122.317569612893, 47.620405779481)),
     (ST_MakePoint(-122.319518192245, 47.6235856071536)),
     (ST_MakePoint(-122.317570183392, 47.6267656259013))
               ) s(destination)

                        start                   |                  finish
     -------------------------------------------+-------------------------------------------
      POINT(-13615805.9939818 6044459.82841367) | POINT(-13615805.9939818 6045202.61238399)
      POINT(-13615805.9939818 6044459.82841367) | POINT(-13615282.3600778 6044985.03351121)
      POINT(-13615805.9939818 6044459.82841367) | POINT(-13615065.5087242 6044459.79656261)
      POINT(-13615805.9939818 6044459.82841367) | POINT(-13615282.4235855 6043934.62312109)
      POINT(-13615805.9939818 6044459.82841367) | POINT(-13615805.9939818 6043717.10775543)
      POINT(-13615805.9939818 6044459.82841367) | POINT(-13616329.564378 6043934.62312109)
      POINT(-13615805.9939818 6044459.82841367) | POINT(-13616546.4792393 6044459.79656261)
      POINT(-13615805.9939818 6044459.82841367) | POINT(-13616329.6278857 6044985.03351121)
     (8 rows)
     */
}
