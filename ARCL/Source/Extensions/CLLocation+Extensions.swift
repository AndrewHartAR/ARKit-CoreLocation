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
}

public extension CLLocation {
    public convenience init(coordinate: CLLocationCoordinate2D, altitude: CLLocationDistance) {
        self.init(coordinate: coordinate, altitude: altitude, horizontalAccuracy: 0, verticalAccuracy: 0, timestamp: Date())
    }

    ///Translates distance in meters between two locations.
    ///Returns the result as the distance in latitude and distance in longitude.
    public func translation(toLocation location: CLLocation) -> LocationTranslation {
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

    public func translatedLocation(with translation: LocationTranslation) -> CLLocation {
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
