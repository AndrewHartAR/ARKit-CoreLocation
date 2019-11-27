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

        let distanceAccuracyMeters = 0.01 * distanceMeters // 1% of distance
        // 1 nautical mile ~= 2000 yards. 1 degree of latitude = 60 nautical miles.
        let distanceAccuracyNauticalMiles =
            Measurement.init(value: distanceAccuracyMeters, unit: UnitLength.meters).converted(to: UnitLength.nauticalMiles).value
        let latitudeAccuracy = distanceAccuracyNauticalMiles / 60.0
        let longitudeAccuracy = distanceAccuracyNauticalMiles / (60.0 * cos(start.coordinate.latitude.degreesToRadians))

        let startPoint = start.coordinate
        let resultPoint = startPoint.coordinateWithBearing(bearing: bearing, distanceMeters: distanceMeters)

        // Calculated lat/lon must be within limits.
        XCTAssertEqual(resultPoint.latitude, lat, accuracy: latitudeAccuracy, "latitude difference exceeds limit", file: file, line: line)
        XCTAssertEqual(resultPoint.longitude, lon, accuracy: longitudeAccuracy, "longitude difference exceeds limit", file: file, line: line)
        
        // Calculated location must be no farther than 100 meters from correct location.
        let resultLocation = CLLocation.init(coordinate: resultPoint, altitude: 0)
        let distanceError = resultLocation.distance(from: CLLocation.init(latitude: lat, longitude: lon))
        XCTAssertLessThan(distanceError, distanceAccuracyMeters, "distance between correct and computed locations exceeds limit", file: file, line: line)

        // Angular error less than 1 degrees, if the error distance is perpendicular to the line of sight.
        // An angular error of 2.5 degrees is about the width of your thumb at arm's length.
        let maxAngularError = 1.0.degreesToRadians
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

    /// Test the `CLLocation` extension function `translation(toLocation:)`. Translation from point defined by `lat0, lon0` (Point 0)
    ///  to  `lat1, lon1` (Point 1) must be correct to within 1% of  actual distance, and 1/2 degree in bearing.
    /// Above 85 degrees, required accuracy is much more forgiving: 2% and 3 degrees.
    /// Also tests that reverse translations get back to original spot.
    func assertCorrectTranslation(start: CLLocation, distanceMeters: Double, bearing: Double, lonTruth: Double, latTruth: Double, file: StaticString = #file,
                                              line: UInt = #line) {
        let requiredAccuracy: Double
        let maxBearingErrorDegrees: Double

        // Note: At high latitudes, the translation(toLocation:) function gives lower accuracy than it does near the equator.
        // We'll allow higher errors for now, in lieu of rewriting translation(toLocation:).
        if abs(start.coordinate.latitude) < 85.0 {
            requiredAccuracy = distanceMeters * 0.01 // 1% of actual distance
            maxBearingErrorDegrees = 0.5
        } else {
            requiredAccuracy = distanceMeters * 0.02 // 2% of actual distance
            maxBearingErrorDegrees = 3.0
        }
        let trueEndLocation = CLLocation(latitude: latTruth, longitude: lonTruth)

        let translation = start.translation(toLocation: trueEndLocation)
        let translationDistance = sqrt(translation.latitudeTranslation * translation.latitudeTranslation + translation.longitudeTranslation * translation.longitudeTranslation)
        XCTAssertEqual(distanceMeters, translationDistance, accuracy: requiredAccuracy, "distance error exceeds \(requiredAccuracy)", file: file, line: line)
        
        let translationAngle = (450.0 - atan2(translation.latitudeTranslation, translation.longitudeTranslation).radiansToDegrees).truncatingRemainder(dividingBy: 360.0)
        XCTAssertEqual(translationAngle, bearing, accuracy: maxBearingErrorDegrees, "bearing error exceeds \(maxBearingErrorDegrees)", file: file, line: line)

        let inverseTranslation = trueEndLocation.translation(toLocation: start)
        // would like to see this below 0.5 meters
        let translationMetersAccuracy = abs(start.coordinate.latitude) < 85.0 ? 220.0 : 2500.0
        XCTAssertEqual(translation.latitudeTranslation, inverseTranslation.latitudeTranslation * -1, accuracy: translationMetersAccuracy,
                       "inverse translation latitude error exceeds \(translationMetersAccuracy) meters", file: file, line: line)
        XCTAssertEqual(translation.longitudeTranslation, inverseTranslation.longitudeTranslation * -1, accuracy: translationMetersAccuracy,
                       "inverse translation longitude error exceeds \(translationMetersAccuracy) meters", file: file, line: line)
        XCTAssertEqual(translation.altitudeTranslation, inverseTranslation.altitudeTranslation * -1, accuracy: translationMetersAccuracy,
                       "inverse translation altitude error exceeds \(translationMetersAccuracy) meters", file: file, line: line)

        // A minimal check that our computed translation sends us to the correct destination.
        // Exercises .translatedLocation(with:) a bit.
        // This code is here mainly to mark the path for someone to address accuracy later.
        // I'm using a huge error bound, 1.2 nautical miles of latitude. Test fails if I lower it.
        // TODO: rewrite .translatedLocation(with:) and .translation(toLocation:) to improve the accuracy.
        let translatedLocationAccuracyDegrees = 0.02 // really ought to be below 0.0001
        let translatedEnd = start.translatedLocation(with: translation)
        XCTAssertEqual(translatedEnd.coordinate.latitude, trueEndLocation.coordinate.latitude, accuracy: translatedLocationAccuracyDegrees,
                       "translated latitude error exceeds \(translatedLocationAccuracyDegrees)", file: file, line: line)
        XCTAssertEqual(translatedEnd.coordinate.longitude, trueEndLocation.coordinate.longitude, accuracy: translatedLocationAccuracyDegrees,
                       "translated longitude error exceeds \(translatedLocationAccuracyDegrees)", file: file, line: line)

        let endInverseTranslated = translatedEnd.translatedLocation(with: inverseTranslation)
        XCTAssertEqual(endInverseTranslated.coordinate.latitude, start.coordinate.latitude, accuracy: translatedLocationAccuracyDegrees,
                       "end's inverse translated latitude more \(translatedLocationAccuracyDegrees) degrees from start", file: file, line: line)
        XCTAssertEqual(endInverseTranslated.coordinate.longitude, start.coordinate.longitude, accuracy: translatedLocationAccuracyDegrees,
                       "end's inverse translated longitude more \(translatedLocationAccuracyDegrees) degrees from start", file: file, line: line)
        XCTAssertEqual(start.distance(from: endInverseTranslated), 0.0, accuracy: translationMetersAccuracy,
                       "end's inverse translated location more than \(translationMetersAccuracy) meters from start", file: file, line: line)
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
        assertCorrectTranslation(start: start, distanceMeters: 500, bearing: 0, lonTruth:-122.3128663, latTruth: 47.6280828887704)
        assertCorrectTranslation(start: start, distanceMeters: 500, bearing: 45, lonTruth: -122.308162416608, latTruth: 47.6267656259013)
        assertCorrectTranslation(start: start, distanceMeters: 500, bearing: 90, lonTruth:-122.306214407755, latTruth: 47.6235856071536)
        assertCorrectTranslation(start: start, distanceMeters: 500, bearing:135, lonTruth:-122.308162987107, latTruth: 47.620405779481)
        assertCorrectTranslation(start: start, distanceMeters: 500, bearing:180, lonTruth:-122.3128663, latTruth: 47.6190887076871)
        assertCorrectTranslation(start: start, distanceMeters: 500, bearing:225, lonTruth:-122.317569612893, latTruth: 47.620405779481)
        assertCorrectTranslation(start: start, distanceMeters: 500, bearing:270, lonTruth:-122.319518192245, latTruth: 47.6235856071536)
        assertCorrectTranslation(start: start, distanceMeters: 500, bearing:315, lonTruth:-122.317570183392, latTruth: 47.6267656259013)
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
        assertCorrectTranslation(start: start, distanceMeters: 10000, bearing: 0, lonTruth:-122.3128663, latTruth: 47.7135269024092)
        assertCorrectTranslation(start: start, distanceMeters: 10000, bearing:45, lonTruth:-122.218680106776, latTruth: 47.6871452814007)
        assertCorrectTranslation(start: start, distanceMeters: 10000, bearing:90, lonTruth:-122.179828585245, latTruth: 47.6235086614964)
        assertCorrectTranslation(start: start, distanceMeters: 10000, bearing:135, lonTruth:-122.218908306631, latTruth: 47.5599484713877)
        assertCorrectTranslation(start: start, distanceMeters: 10000, bearing:180, lonTruth:-122.3128663, latTruth: 47.5336432805981)
        assertCorrectTranslation(start: start, distanceMeters: 10000, bearing:225, lonTruth:-122.406824293369, latTruth: 47.5599484713877)
        assertCorrectTranslation(start: start, distanceMeters: 10000, bearing:270, lonTruth:-122.445904014755, latTruth: 47.6235086614964)
        assertCorrectTranslation(start: start, distanceMeters: 10000, bearing:315, lonTruth:-122.407052493224, latTruth: 47.6871452814007)
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
        assertCorrectTranslation(start: start, distanceMeters: 50000, bearing:0, lonTruth:-122.3128663, latTruth: 48.0732771512326)
        assertCorrectTranslation(start: start, distanceMeters: 50000, bearing:45, lonTruth:-121.839637614568, latTruth: 47.9405975715807)
        assertCorrectTranslation(start: start, distanceMeters: 50000, bearing:90, lonTruth:-121.647693382546, latTruth: 47.6216573806133)
        assertCorrectTranslation(start: start, distanceMeters: 50000, bearing:135, lonTruth:-121.845342666805, latTruth: 47.3046277647178)
        assertCorrectTranslation(start: start, distanceMeters: 50000, bearing:180, lonTruth:-122.3128663, latTruth: 47.1738590246445)
        assertCorrectTranslation(start: start, distanceMeters: 50000, bearing:225, lonTruth:-122.780389933195, latTruth: 47.3046277647178)
        assertCorrectTranslation(start: start, distanceMeters: 50000, bearing:270, lonTruth:-122.978039217454, latTruth: 47.6216573806133)
        assertCorrectTranslation(start: start, distanceMeters: 50000, bearing:315, lonTruth:-122.786094985432, latTruth: 47.9405975715807)
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
        assertCorrectTranslation(start: start, distanceMeters: 500, bearing:0, lonTruth:-122.3128663, latTruth: 85.0044768604693)
        assertCorrectTranslation(start: start, distanceMeters: 500, bearing:45, lonTruth:-122.27652381425, latTruth: 85.003164618309)
        assertCorrectTranslation(start: start, distanceMeters: 500, bearing:90, lonTruth:-122.261502726378, latTruth: 84.9999980009648)
        assertCorrectTranslation(start: start, distanceMeters: 500, bearing:135, lonTruth:-122.276569684625, latTruth: 84.9968333823477)
        assertCorrectTranslation(start: start, distanceMeters: 500, bearing:180, lonTruth:-122.3128663, latTruth: 84.9955231389167)
        assertCorrectTranslation(start: start, distanceMeters: 500, bearing:225, lonTruth:-122.349162915375, latTruth: 84.9968333823477)
        assertCorrectTranslation(start: start, distanceMeters: 500, bearing:270, lonTruth:-122.364229873622, latTruth: 84.9999980009648)
        assertCorrectTranslation(start: start, distanceMeters: 500, bearing:315, lonTruth:-122.34920878575, latTruth: 85.003164618309)
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
        assertCorrectTranslation(start: start, distanceMeters: 10000, bearing:0, lonTruth:-122.3128663, latTruth: 85.0895370934438)
        assertCorrectTranslation(start: start, distanceMeters: 10000, bearing:45, lonTruth:-121.57722387973, latTruth: 85.0629073941419)
        assertCorrectTranslation(start: start, distanceMeters: 10000, bearing:90, lonTruth:-121.285703772561, latTruth: 84.9992004496645)
        assertCorrectTranslation(start: start, distanceMeters: 10000, bearing:135, lonTruth:-121.595572036496, latTruth: 84.936292772585)
        assertCorrectTranslation(start: start, distanceMeters: 10000, bearing:180, lonTruth:-122.3128663, latTruth: 84.9104626609434)
        assertCorrectTranslation(start: start, distanceMeters: 10000, bearing:225, lonTruth:-123.030160563504, latTruth: 84.936292772585)
        assertCorrectTranslation(start: start, distanceMeters: 10000, bearing:270, lonTruth:-123.340028827439, latTruth: 84.9992004496645)
        assertCorrectTranslation(start: start, distanceMeters: 10000, bearing:315, lonTruth:-123.04850872027, latTruth: 85.0629073941419)
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
        assertCorrectTranslation(start: start, distanceMeters: 50000, bearing:0, lonTruth:-122.3128663, latTruth: 85.447683098238)
        assertCorrectTranslation(start: start, distanceMeters: 50000, bearing:45, lonTruth:-118.441917077449, latTruth: 85.3059018482087)
        assertCorrectTranslation(start: start, distanceMeters: 50000, bearing:90, lonTruth:-117.190097318035, latTruth: 84.9800494382655)
        assertCorrectTranslation(start: start, distanceMeters: 50000, bearing:135, lonTruth:-118.900615692524, latTruth: 84.6740447063519)
        assertCorrectTranslation(start: start, distanceMeters: 50000, bearing:180, lonTruth:-122.3128663, latTruth: 84.5523107615602)
        assertCorrectTranslation(start: start, distanceMeters: 50000, bearing:225, lonTruth:-125.725116907476, latTruth: 84.6740447063519)
        assertCorrectTranslation(start: start, distanceMeters: 50000, bearing:270, lonTruth:-127.435635281965, latTruth: 84.9800494382655)
        assertCorrectTranslation(start: start, distanceMeters: 50000, bearing:315, lonTruth:-126.183815522551, latTruth: 85.3059018482087)
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
        assertCorrectTranslation(start: start, distanceMeters: 500, bearing:0, lonTruth:-122.3128663, latTruth: 5.00452150216546)
        assertCorrectTranslation(start: start, distanceMeters: 500, bearing:45, lonTruth:-122.309678209556, latTruth: 5.00319717715266)
        assertCorrectTranslation(start: start, distanceMeters: 500, bearing:90, lonTruth:-122.308357681126, latTruth: 4.99999998449507)
        assertCorrectTranslation(start: start, distanceMeters: 500, bearing:135, lonTruth:-122.309678240478, latTruth: 4.99680280703131)
        assertCorrectTranslation(start: start, distanceMeters: 500, bearing:180, lonTruth:-122.3128663, latTruth: 4.99547849721233)
        assertCorrectTranslation(start: start, distanceMeters: 500, bearing:225, lonTruth:-122.316054359522, latTruth: 4.99680280703131)
        assertCorrectTranslation(start: start, distanceMeters: 500, bearing:270, lonTruth:-122.317374918874, latTruth: 4.99999998449507)
        assertCorrectTranslation(start: start, distanceMeters: 500, bearing:315, lonTruth:-122.316054390444, latTruth: 5.00319717715266)
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
        assertCorrectTranslation(start: start, distanceMeters: 10000, bearing:0, lonTruth:-122.3128663, latTruth: 5.09042992434887)
        assertCorrectTranslation(start: start, distanceMeters: 10000, bearing:45, lonTruth:-122.249098589414, latTruth: 5.06394052429685)
        assertCorrectTranslation(start: start, distanceMeters: 10000, bearing:90, lonTruth:-122.222693923089, latTruth: 4.99999379803119)
        assertCorrectTranslation(start: start, distanceMeters: 10000, bearing:135, lonTruth:-122.249110958015, latTruth: 4.93605314928675)
        assertCorrectTranslation(start: start, distanceMeters: 10000, bearing:180, lonTruth:-122.3128663, latTruth: 4.90956982676742)
        assertCorrectTranslation(start: start, distanceMeters: 10000, bearing:225, lonTruth:-122.376621641985, latTruth: 4.93605314928675)
        assertCorrectTranslation(start: start, distanceMeters: 10000, bearing:270, lonTruth:-122.403038676911, latTruth: 4.99999379803119)
        assertCorrectTranslation(start: start, distanceMeters: 10000, bearing:315, lonTruth:-122.376634010586, latTruth: 5.06394052429685)
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
        assertCorrectTranslation(start: start, distanceMeters: 50000, bearing:0, lonTruth:-122.3128663, latTruth: 5.4521470438799)
        assertCorrectTranslation(start: start, distanceMeters: 50000, bearing:45, lonTruth:-121.99390085599, latTruth: 5.31963770686063)
        assertCorrectTranslation(start: start, distanceMeters: 50000, bearing:90, lonTruth:-121.862004483307, latTruth: 4.99984495156423)
        assertCorrectTranslation(start: start, distanceMeters: 50000, bearing:135, lonTruth:-121.994210074066, latTruth: 4.68020413013662)
        assertCorrectTranslation(start: start, distanceMeters: 50000, bearing:180, lonTruth:-122.3128663, latTruth: 4.54784673415444)
        assertCorrectTranslation(start: start, distanceMeters: 50000, bearing:225, lonTruth:-122.631522525934, latTruth: 4.68020413013662)
        assertCorrectTranslation(start: start, distanceMeters: 50000, bearing:270, lonTruth:-122.763728116693, latTruth: 4.99984495156423)
        assertCorrectTranslation(start: start, distanceMeters: 50000, bearing:315, lonTruth:-122.63183174401, latTruth: 5.31963770686063)
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
        assertCorrectTranslation(start: start, distanceMeters: 500, bearing:0, lonTruth:-122.3128663, latTruth: -39.9954968987312)
        assertCorrectTranslation(start: start, distanceMeters: 500, bearing:45, lonTruth:-122.308726225035, latTruth: -39.9968157529746)
        assertCorrectTranslation(start: start, distanceMeters: 500, bearing:90, lonTruth:-122.30701107789, latTruth: -39.9999998520994)
        assertCorrectTranslation(start: start, distanceMeters: 500, bearing:135, lonTruth:-122.308725840415, latTruth: -40.00318409737)
        assertCorrectTranslation(start: start, distanceMeters: 500, bearing:180, lonTruth:-122.3128663, latTruth: -40.0045030977592)
        assertCorrectTranslation(start: start, distanceMeters: 500, bearing:225, lonTruth:-122.317006759585, latTruth: -40.00318409737)
        assertCorrectTranslation(start: start, distanceMeters: 500, bearing:270, lonTruth:-122.318721522109, latTruth: -39.9999998520994)
        assertCorrectTranslation(start: start, distanceMeters: 500, bearing:315, lonTruth:-122.317006374965, latTruth: -39.9968157529746)
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
        assertCorrectTranslation(start: start, distanceMeters: 10000, bearing:0, lonTruth:-122.3128663, latTruth: -39.9099373079262)
        assertCorrectTranslation(start: start, distanceMeters: 10000, bearing:45, lonTruth:-122.230137797083, latTruth: -39.9362866650944)
        assertCorrectTranslation(start: start, distanceMeters: 10000, bearing:90, lonTruth:-122.195761925015, latTruth: -39.9999408398175)
        assertCorrectTranslation(start: start, distanceMeters: 10000, bearing:135, lonTruth:-122.229983949109, latTruth: -40.0636534726882)
        assertCorrectTranslation(start: start, distanceMeters: 10000, bearing:180, lonTruth:-122.3128663, latTruth: -40.0900612882388)
        assertCorrectTranslation(start: start, distanceMeters: 10000, bearing:225, lonTruth:-122.395748650891, latTruth: -40.0636534726882)
        assertCorrectTranslation(start: start, distanceMeters: 10000, bearing:270, lonTruth:-122.429970674985, latTruth: -39.9999408398175)
        assertCorrectTranslation(start: start, distanceMeters: 10000, bearing:315, lonTruth:-122.395594802917, latTruth: -39.9362866650943)
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
        assertCorrectTranslation(start: start, distanceMeters: 50000, bearing:0, lonTruth:-122.3128663, latTruth: -39.5496725166091)
        assertCorrectTranslation(start: start, distanceMeters: 50000, bearing:45, lonTruth:-121.900752491598, latTruth: -39.6808395104955)
        assertCorrectTranslation(start: start, distanceMeters: 50000, bearing:90, lonTruth:-121.727352509562, latTruth: -39.9985210178516)
        assertCorrectTranslation(start: start, distanceMeters: 50000, bearing:135, lonTruth:-121.896906254532, latTruth: -40.3176638863652)
        assertCorrectTranslation(start: start, distanceMeters: 50000, bearing:180, lonTruth:-122.3128663, latTruth: -40.4502923882122)
        assertCorrectTranslation(start: start, distanceMeters: 50000, bearing:225, lonTruth:-122.728826345467, latTruth: -40.3176638863652)
        assertCorrectTranslation(start: start, distanceMeters: 50000, bearing:270, lonTruth:-122.898380090438, latTruth: -39.9985210178516)
        assertCorrectTranslation(start: start, distanceMeters: 50000, bearing:315, lonTruth:-122.724980108402, latTruth: -39.6808395104955)
    }
    
    // MARK: - CLLocation.earthRadiusMeters
    func testEarthRadiusMeters() {
        // source: https://planetcalc.com/7721/
        let requiredAccuracyKM = 0.001
        XCTAssertEqual(CLLocationCoordinate2DMake( 90.0, 0.0).earthRadiusMeters() / 1000.0, 6356.752, accuracy: requiredAccuracyKM)
        XCTAssertEqual(CLLocationCoordinate2DMake(-90.0, 0.0).earthRadiusMeters() / 1000.0, 6356.752, accuracy: requiredAccuracyKM)
        XCTAssertEqual(CLLocationCoordinate2DMake( 80.0, 0.0).earthRadiusMeters() / 1000.0, 6357.402, accuracy: requiredAccuracyKM)
        XCTAssertEqual(CLLocationCoordinate2DMake(-80.0, 0.0).earthRadiusMeters() / 1000.0, 6357.402, accuracy: requiredAccuracyKM)
        XCTAssertEqual(CLLocationCoordinate2DMake( 70.0, 0.0).earthRadiusMeters() / 1000.0, 6359.272, accuracy: requiredAccuracyKM)
        XCTAssertEqual(CLLocationCoordinate2DMake(-70.0, 0.0).earthRadiusMeters() / 1000.0, 6359.272, accuracy: requiredAccuracyKM)
        XCTAssertEqual(CLLocationCoordinate2DMake( 60.0, 0.0).earthRadiusMeters() / 1000.0, 6362.132, accuracy: requiredAccuracyKM)
        XCTAssertEqual(CLLocationCoordinate2DMake(-60.0, 0.0).earthRadiusMeters() / 1000.0, 6362.132, accuracy: requiredAccuracyKM)
        XCTAssertEqual(CLLocationCoordinate2DMake( 50.0, 0.0).earthRadiusMeters() / 1000.0, 6365.632, accuracy: requiredAccuracyKM)
        XCTAssertEqual(CLLocationCoordinate2DMake(-50.0, 0.0).earthRadiusMeters() / 1000.0, 6365.632, accuracy: requiredAccuracyKM)
        XCTAssertEqual(CLLocationCoordinate2DMake( 40.0, 0.0).earthRadiusMeters() / 1000.0, 6369.345, accuracy: requiredAccuracyKM)
        XCTAssertEqual(CLLocationCoordinate2DMake(-40.0, 0.0).earthRadiusMeters() / 1000.0, 6369.345, accuracy: requiredAccuracyKM)
        XCTAssertEqual(CLLocationCoordinate2DMake( 30.0, 0.0).earthRadiusMeters() / 1000.0, 6372.824, accuracy: requiredAccuracyKM)
        XCTAssertEqual(CLLocationCoordinate2DMake(-30.0, 0.0).earthRadiusMeters() / 1000.0, 6372.824, accuracy: requiredAccuracyKM)
        XCTAssertEqual(CLLocationCoordinate2DMake( 20.0, 0.0).earthRadiusMeters() / 1000.0, 6375.654, accuracy: requiredAccuracyKM)
        XCTAssertEqual(CLLocationCoordinate2DMake(-20.0, 0.0).earthRadiusMeters() / 1000.0, 6375.654, accuracy: requiredAccuracyKM)
        XCTAssertEqual(CLLocationCoordinate2DMake( 10.0, 0.0).earthRadiusMeters() / 1000.0, 6377.497, accuracy: requiredAccuracyKM)
        XCTAssertEqual(CLLocationCoordinate2DMake(-10.0, 0.0).earthRadiusMeters() / 1000.0, 6377.497, accuracy: requiredAccuracyKM)
        XCTAssertEqual(CLLocationCoordinate2DMake(  0.0, 0.0).earthRadiusMeters() / 1000.0, 6378.137, accuracy: requiredAccuracyKM)
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
