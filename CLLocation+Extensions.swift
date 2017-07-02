//
//  CLLocation+Extensions.swift
//  brand new
//
//  Created by Andrew Hart on 02/07/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import Foundation
import CoreLocation

///Translation in meters between 2 locations
struct LocationTranslation {
    var latitudeTranslation: Double
    var longitudeTranslation: Double
}

extension CLLocation {
    ///Translation between two locations, in meters
    ///While using `distance` would give a single measurement of the distance,
    ///This function calculates the distance along latitude and longitude coordinates.
    func translation(toLocation location: CLLocation) -> LocationTranslation {
        let inbetweenLocation = CLLocation(latitude: self.coordinate.latitude, longitude: location.coordinate.longitude)
        
        let distanceLatitude = location.distance(from: inbetweenLocation)
        
        let latitudeTranslation: Double
        
        if location.coordinate.latitude > inbetweenLocation.coordinate.latitude {
            latitudeTranslation = distanceLatitude
        } else {
            latitudeTranslation = 0 - distanceLatitude
        }
        
        let distanceLongitude = self.distance(from: inbetweenLocation)
        
        let longitudeTranslation: Double
        
        if self.coordinate.longitude > inbetweenLocation.coordinate.longitude {
            longitudeTranslation = 0 - distanceLongitude
        } else {
            longitudeTranslation = distanceLongitude
        }
        
        return LocationTranslation(latitudeTranslation: latitudeTranslation, longitudeTranslation: longitudeTranslation)
    }
}
