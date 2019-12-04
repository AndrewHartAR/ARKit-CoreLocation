//
//  CLLocation+Extensions.swift
//  ARKit+CoreLocation
//
//  Created by Andrew Hart on 02/07/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import Foundation
import CoreLocation

///Translation in meters between 2 locations
public struct LocationTranslation {
    public var latitudeTranslation: Double
    public var longitudeTranslation: Double
    public var altitudeTranslation: Double

    /// This explicit definition is needed because the "free" init function is marked fileprivate by default,
    /// so LocationTranslation isn't available to client apps.
    public init(latitudeTranslation: Double, longitudeTranslation: Double, altitudeTranslation: Double) {
        self.latitudeTranslation = latitudeTranslation
        self.longitudeTranslation = longitudeTranslation
        self.altitudeTranslation = altitudeTranslation
    }
}

public extension CLLocation {
    convenience init(coordinate: CLLocationCoordinate2D, altitude: CLLocationDistance) {
        self.init(coordinate: coordinate, altitude: altitude, horizontalAccuracy: 0, verticalAccuracy: 0, timestamp: Date())
    }

    /// Translates distance in meters between two locations.
    /// Returns the result as the distance in latitude and distance in longitude.
    /// The approximation used here gives reasonable accuracy out to a radius of 50 km except at high latitudes.
    /// TODO: rewrite .translation(toLocation:) to improve the accuracy. See unit test notes.
    func translation(toLocation location: CLLocation) -> LocationTranslation {
        let inbetweenLocation = CLLocation(latitude: self.coordinate.latitude, longitude: location.coordinate.longitude)

        let distanceLatitude = location.distance(from: inbetweenLocation)

        let latitudeTranslation = location.coordinate.latitude > inbetweenLocation.coordinate.latitude ? distanceLatitude
                                                                                                        : -distanceLatitude

        let distanceLongitude = distance(from: inbetweenLocation)

        let longitudeTranslation = coordinate.longitude > inbetweenLocation.coordinate.longitude ? -distanceLongitude
                                                                                                    : distanceLongitude

        let altitudeTranslation = location.altitude - self.altitude

        return LocationTranslation( latitudeTranslation: latitudeTranslation,
                                    longitudeTranslation: longitudeTranslation,
                                    altitudeTranslation: altitudeTranslation)
    }

    /// TODO: rewrite .translatedLocation(with:) to improve the accuracy. See unit test notes.
    func translatedLocation(with translation: LocationTranslation) -> CLLocation {
        let latitudeCoordinate = self.coordinate.coordinateWithBearing(bearing: 0,
                                                                       distanceMeters: translation.latitudeTranslation)

        let longitudeCoordinate = self.coordinate.coordinateWithBearing(bearing: 90,
                                                                        distanceMeters: translation.longitudeTranslation)
        // NB: Great Circle geometry means that abs(longitudeCoordinate.latitude) < abs(self.coordinate.latitude)
        // (or equal, if self is on the equator).
        let coordinate = CLLocationCoordinate2D( latitude: latitudeCoordinate.latitude, longitude: longitudeCoordinate.longitude)

        let altitude = self.altitude + translation.altitudeTranslation

        return CLLocation(coordinate: coordinate,
                          altitude: altitude,
                          horizontalAccuracy: self.horizontalAccuracy,
                          verticalAccuracy: self.verticalAccuracy,
                          timestamp: self.timestamp)
    }

    /// Bearing from `self` to another point. Returns bearing in +/- degrees from north 
    /// This function uses the haversine formula to compute a geodesic (great circle), assuming a spherical earth.
    /// Note that, especially at high latitudes and with relatively distant points, `a.bearing(between: b)`
    /// is not necessarily 180 degrees opposite to `b.bearing(between: a)`.
    /// - Parameter point: second point to compute bearing to.
    func bearing(between point: CLLocation) -> Double {
        let lat1 = self.coordinate.latitude.degreesToRadians
        let lon1 = self.coordinate.longitude.degreesToRadians

        let lat2 = point.coordinate.latitude.degreesToRadians
        let lon2 = point.coordinate.longitude.degreesToRadians

        let dLon = lon2 - lon1

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        return atan2(y, x).radiansToDegrees
    }

    /// Returns the midpoint between two locations
    /// Note: Only usable for short distances like MKPolyline segments
    func approxMidpoint(to: CLLocation) -> CLLocation {
        return CLLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: (coordinate.latitude + to.coordinate.latitude) / 2,
                longitude: (coordinate.longitude + to.coordinate.longitude) / 2
            ),
            altitude: (altitude + to.altitude) / 2
        )
    } // approxMidpoint(to:)

}

public extension CLLocation {
    var debugLog: String {
        return "location: \(self.coordinate), accuracy: \(self.horizontalAccuracy), date: \(self.timestamp)"
    }
}

public extension CLLocationCoordinate2D {

    /// Returns a new `CLLocationCoordinate2D` at the given bearing and distance from the original point.
    /// This function uses a great circle on ellipse formula.
    /// - Parameter bearing: bearing in degrees clockwise from north.
    /// - Parameter distanceMeters: distance in meters.
    func coordinateWithBearing(bearing: Double, distanceMeters: Double) -> CLLocationCoordinate2D {
        // From https://www.movable-type.co.uk/scripts/latlong.html:
        //    All these formulas are for calculations on the basis of a spherical earth (ignoring ellipsoidal effects) –
        //    which is accurate enough* for most purposes… [In fact, the earth is very slightly ellipsoidal; using a
        //    spherical model gives errors typically up to 0.3%1 – see notes for further details].
        //
        //  Destination point given distance and bearing from start point**
        //
        //  Given a start point, initial bearing, and distance, this will calculate the destina­tion point and
        //      final bearing travelling along a (shortest distance) great circle arc.
        //
        //  Formula:    φ2 = asin( sin φ1 ⋅ cos δ + cos φ1 ⋅ sin δ ⋅ cos θ )
        //  λ2 = λ1 + atan2( sin θ ⋅ sin δ ⋅ cos φ1, cos δ − sin φ1 ⋅ sin φ2 )
        //  where    φ is latitude, λ is longitude, θ is the bearing (clockwise from north),
        //           δ is the angular distance d/R; d being the distance travelled, R the earth’s radius
        //
        //  JavaScript: (all angles in radians)
        //  var φ2 = Math.asin( Math.sin(φ1)*Math.cos(d/R) +
        //                      Math.cos(φ1)*Math.sin(d/R)*Math.cos(brng) );
        //  var λ2 = λ1 + Math.atan2(Math.sin(brng)*Math.sin(d/R)*Math.cos(φ1),
        //                           Math.cos(d/R)-Math.sin(φ1)*Math.sin(φ2));
        //  The longitude can be normalised to −180…+180 using (lon+540)%360-180
        //
        //  Excel:
        //  (all angles
        //  in radians)
        //  lat2: =ASIN(SIN(lat1)*COS(d/R) + COS(lat1)*SIN(d/R)*COS(brng))
        //  lon2: =lon1 + ATAN2(COS(d/R)-SIN(lat1)*SIN(lat2), SIN(brng)*SIN(d/R)*COS(lat1))
        //  * Remember that Excel reverses the arguments to ATAN2 – see notes below
        //  For final bearing, simply take the initial bearing from the end point to the start point and
        //  reverse it with (brng+180)%360.
        //

        let phi = self.latitude.degreesToRadians
        let lambda = self.longitude.degreesToRadians
        let theta = bearing.degreesToRadians

        let sigma = distanceMeters / self.earthRadiusMeters()

        let phi2 = asin(sin(phi) * cos(sigma) + cos(phi) * sin(sigma) * cos(theta))
        let lambda2 = lambda + atan2(sin(theta) * sin(sigma) * cos(phi), cos(sigma) - sin(phi) * sin(phi2))

        let result = CLLocationCoordinate2D(latitude: phi2.radiansToDegrees, longitude: lambda2.radiansToDegrees)
        return result
    }

    /// Return the WGS-84 radius of the earth, in meters, at the given point.
    func earthRadiusMeters() -> Double {
        // source: https://planetcalc.com/7721/ from https://en.wikipedia.org/wiki/Earth_radius#Geocentric_radius
        let WGS84EquatorialRadius  = 6_378_137.0
        let WGS84PolarRadius = 6_356_752.3

        // shorter versions to make formulas easier to read
        let a = WGS84EquatorialRadius
        let b = WGS84PolarRadius
        let phi = self.latitude.degreesToRadians

        let numerator = pow(a * a * cos(phi), 2) + pow(b * b * sin(phi), 2)
        let denominator = pow(a * cos(phi), 2) + pow(b * sin(phi), 2)
        let radius = sqrt(numerator/denominator)
        return radius
    }
}
