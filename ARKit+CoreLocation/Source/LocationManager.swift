//
//  LocationManager.swift
//  ARKit+CoreLocation
//
//  Created by Andrew Hart on 02/07/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import Foundation
import CoreLocation

protocol LocationManagerDelegate: class {
    func locationManagerDidUpdateLocation(_ locationManager: LocationManager,
                                          location: CLLocation)
    func locationManagerDidUpdateHeading(_ locationManager: LocationManager,
                                         heading: CLLocationDirection,
                                         accuracy: CLLocationDirection)
}

///Handles retrieving the location and heading from CoreLocation
///Does not contain anything related to ARKit or advanced location
class LocationManager: NSObject {
    weak var delegate: LocationManagerDelegate?

    private var locationManager: CLLocationManager?

    var currentLocation: CLLocation?

    var heading: CLLocationDirection?
    var headingAccuracy: CLLocationDegrees?

    override init() {
        super.init()

        self.locationManager = CLLocationManager()
        self.locationManager!.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        self.locationManager!.distanceFilter = kCLDistanceFilterNone
        self.locationManager!.headingFilter = kCLHeadingFilterNone
        self.locationManager!.pausesLocationUpdatesAutomatically = false
        self.locationManager!.delegate = self
        self.locationManager!.startUpdatingHeading()
        self.locationManager!.startUpdatingLocation()

        self.locationManager!.requestWhenInUseAuthorization()

        self.currentLocation = self.locationManager!.location
    }

    func requestAuthorization() {
        if CLLocationManager.authorizationStatus() == .authorizedAlways ||
            CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            return
        }

        if CLLocationManager.authorizationStatus() == .denied ||
            CLLocationManager.authorizationStatus() == .restricted {
            return
        }

        locationManager?.requestWhenInUseAuthorization()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {

    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locations.forEach {
            delegate?.locationManagerDidUpdateLocation(self, location: $0)
        }

        self.currentLocation = manager.location
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = newHeading.headingAccuracy >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        headingAccuracy = newHeading.headingAccuracy

        delegate?.locationManagerDidUpdateHeading(self, heading: heading!, accuracy: newHeading.headingAccuracy)
    }

    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        return true
    }
}
