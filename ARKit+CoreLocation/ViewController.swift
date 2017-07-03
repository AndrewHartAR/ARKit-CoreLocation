//
//  ViewController.swift
//  ARKit+CoreLocation
//
//  Created by Andrew Hart on 02/07/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate {
    let sceneLocationView = SceneLocationView()
    
    let mapView = MKMapView()
    var userAnnotation: MKPointAnnotation?
    
    var updateUserLocationTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(sceneLocationView)
        
        mapView.delegate = self
        mapView.showsUserLocation = true
        view.addSubview(mapView)
        
        updateUserLocationTimer = Timer.scheduledTimer(
            timeInterval: 1,
            target: self,
            selector: #selector(ViewController.updateUserLocation),
            userInfo: nil,
            repeats: true)
        
        //Give it a chance to get the user's location, then update the mapview region
        DispatchQueue.main.asyncAfter(timeInterval: 3) {
            let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            let region = MKCoordinateRegion(center: self.mapView.userLocation.coordinate, span: span)
            self.mapView.region = region
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //Set to true to display an arrow which points north.
        //Checkout the comments in the property description on this,
        //it could use some improvement.
        sceneLocationView.displayDebuggingArrow = false
        sceneLocationView.run()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneLocationView.pause()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        sceneLocationView.frame = CGRect(
            x: 0,
            y: 0,
            width: self.view.frame.size.width,
            height: self.view.frame.size.height)
        
        mapView.frame = CGRect(
            x: 0,
            y: self.view.frame.size.height / 2,
            width: self.view.frame.size.width,
            height: self.view.frame.size.height / 2)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    @objc func updateUserLocation() {
        sceneLocationView.currentLocation {
            (location) in
            if location != nil {
                DispatchQueue.main.async {
                    if self.userAnnotation == nil {
                        self.userAnnotation = MKPointAnnotation()
                        self.mapView.addAnnotation(self.userAnnotation!)
                    }
                        
                    self.userAnnotation?.coordinate = location!.coordinate
                    self.userAnnotation!.title = "My Location, acc: \(location!.horizontalAccuracy)"
                }
            }
        }
    }
    
    //MARK: MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let marker = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: nil)
        marker.displayPriority = .required
        
        return marker
    }
}

extension DispatchQueue {
    func asyncAfter(timeInterval: TimeInterval, execute: @escaping () -> Void) {
        self.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(timeInterval * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: execute)
    }
}
