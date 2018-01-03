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
    func locationManagerDidUpdateLocation(_ locationManager: LocationManager, location: CLLocation)
    func locationManagerDidUpdateHeading(_ locationManager: LocationManager, heading: CLLocationDirection, accuracy: CLLocationDirection)
}

///Handles retrieving the location and heading from CoreLocation
///Does not contain anything related to ARKit or advanced location
class LocationManager: NSObject, CLLocationManagerDelegate {
    weak var delegate: LocationManagerDelegate?
    
    private var locationManager: CLLocationManager?
    
    var currentLocation: CLLocation?
    
    public var heading: CLLocationDirection?
    public var headingAccuracy: CLLocationDegrees?
    
    // Used for True North Correction
    public var courseAvgX: Double = 0
    public var courseAvgY: Double = 0
    public var course: Double = 0
    public var avgCourse: Double = 0
    public var courseAngle: Double = 0
    public var northAngle: Double = 0
    
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
        if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways ||
            CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse {
            return
        }
        
        if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.denied ||
            CLLocationManager.authorizationStatus() == CLAuthorizationStatus.restricted {
            return
        }
        
        self.locationManager?.requestWhenInUseAuthorization()
    }
    
    // MARK: - True North Correction from ARCL Slack
    func getVectorAvg(latestReading: Double) -> Double {
        
        let deg2Rad = 180 / Double.pi
        // convert reading to radians
        let theta = latestReading / deg2Rad
        
        // running average
        courseAvgX = courseAvgX * 0.5 + cos(theta) * 0.5;
        courseAvgY = courseAvgY * 0.5 + sin(theta) * 0.5;
        
        // get the result in degrees
        var avgAngleDeg =  atan2(courseAvgY, courseAvgX) * deg2Rad;
        
        // result is -180 to 180. change this to 0-360.
        if(avgAngleDeg < 0){ avgAngleDeg = avgAngleDeg + 360}
        
        return avgAngleDeg;
    }
    
    func updateVectorAverage(location: CLLocation) {
        self.course = location.course
        print("location.course: \(course)" )
        self.avgCourse = getVectorAvg(latestReading: course)
        print("avgCourse: \(avgCourse)")
        
        self.courseAngle = (360.0 - avgCourse + course) * -1.0
        self.northAngle = (360.0 - course) * -1.0
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            self.delegate?.locationManagerDidUpdateLocation(self, location: location)
        }
        
        self.currentLocation = manager.location
        if let location = manager.location {
            updateVectorAverage(location: location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if newHeading.headingAccuracy >= 0 {
            self.heading = newHeading.trueHeading
        } else {
            self.heading = newHeading.magneticHeading
        }
        
        self.headingAccuracy = newHeading.headingAccuracy
        
        self.delegate?.locationManagerDidUpdateHeading(self, heading: self.heading!, accuracy: newHeading.headingAccuracy)
    }
    
    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        return true
    }
}

