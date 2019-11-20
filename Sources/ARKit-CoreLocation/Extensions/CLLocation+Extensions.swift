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

    func translatedLocation(with translation: LocationTranslation) -> CLLocation {
        let latitudeCoordinate = self.coordinate.coordinateWithBearing(bearing: 0,
                                                                       distanceMeters: translation.latitudeTranslation)

        let longitudeCoordinate = self.coordinate.coordinateWithBearing(bearing: 90,
                                                                        distanceMeters: translation.longitudeTranslation)

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
}

public extension CLLocation {
    var debugLog: String {
        return "location: \(self.coordinate), accuracy: \(self.horizontalAccuracy), date: \(self.timestamp)"
    }
}

public extension CLLocationCoordinate2D {

    /// Returns a new `CLLocationCoordinate2D` at the given bearing and distance from the original point.
    /// This function uses neither a geodesic nor a rhumb line formula. Instead, it uses a rectangular approximation of a sphere.
    /// For very short distances, this method is probably accurate enough, but for long distances, a geodesic (great circle)
    /// formula is required instead. Unit testing shows inaccuracy even as close as 500 meters.
    /// - Parameter bearing: bearing in degrees clockwise from north.
    /// - Parameter distanceMeters: distance in meters.
    func coordinateWithBearing(bearing: Double, distanceMeters: Double) -> CLLocationCoordinate2D {
        //The numbers for earth radius may be _off_ here
        //but this gives a reasonably accurate result..
        //Any correction here is welcome.
        let distRadiansLat = distanceMeters.metersToLatitude // earth radius in meters latitude
        let distRadiansLong = distanceMeters.metersToLongitude // earth radius in meters longitude

        let lat1 = self.latitude * Double.pi / 180
        let lon1 = self.longitude * Double.pi / 180

        let lat2 = asin(sin(lat1) * cos(distRadiansLat) + cos(lat1) * sin(distRadiansLat) * cos(bearing))
        let lon2 = lon1 + atan2(sin(bearing) * sin(distRadiansLong) * cos(lat1), cos(distRadiansLong) - sin(lat1) * sin(lat2))

        return CLLocationCoordinate2D(latitude: lat2 * 180 / Double.pi, longitude: lon2 * 180 / Double.pi)
    }
}
