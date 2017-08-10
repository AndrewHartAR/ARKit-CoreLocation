//
//  ViewController.swift
//  ARKit+CoreLocation
//
//  Created by Andrew Hart on 02/07/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import UIKit
import SceneKit
import MapKit
import CocoaLumberjack

class ViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var infoLabel: UILabel!

    @IBOutlet weak var contentView: UIView!
    let sceneLocationView = SceneLocationView()

    var userAnnotation: MKPointAnnotation?
    var locationEstimateAnnotation: MKPointAnnotation?

    var updateUserLocationTimer: Timer?
    var updateInfoLabelTimer: Timer?

    var centerMapOnUserLocation: Bool = true

    ///Whether to display some debugging data
    ///This currently displays the coordinate of the best location estimate
    ///The initial value is respected
    let displayDebugging = false

    let adjustNorthByTappingSidesOfScreen = false

    override func viewDidLoad() {
        super.viewDidLoad()

        updateInfoLabelTimer = Timer.scheduledTimer(timeInterval: 0.1,
                                                    target: self,
                                                    selector: #selector(ViewController.updateInfoLabel),
                                                    userInfo: nil,
                                                    repeats: true)

        //Set to true to display an arrow which points north.
        //Checkout the comments in the property description and on the readme on this.
//        sceneLocationView.orientToTrueNorth = false

//        sceneLocationView.locationEstimateMethod = .coreLocationDataOnly
        sceneLocationView.showAxesNode = true
        sceneLocationView.locationViewDelegate = self

        sceneLocationView.showFeaturePoints = displayDebugging

        //Currently set to Canary Wharf
        let pinCoordinate = CLLocationCoordinate2D(latitude: 51.504607, longitude: -0.019592)
        let pinLocation = CLLocation(coordinate: pinCoordinate, altitude: 236)
        let pinImage = UIImage(named: "pin")!
        let pinLocationNode = LocationAnnotationNode(location: pinLocation, image: pinImage)
        sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: pinLocationNode)

        contentView.addSubview(sceneLocationView)
        sceneLocationView.frame = contentView.bounds

        if !mapView.isHidden {
            updateUserLocationTimer = Timer.scheduledTimer(timeInterval: 0.5,
                                                           target: self,
                                                           selector: #selector(ViewController.updateUserLocation),
                                                           userInfo: nil,
                                                           repeats: true)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DDLogDebug("run")
        sceneLocationView.run()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        DDLogDebug("pause")
        // Pause the view's session
        sceneLocationView.pause()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sceneLocationView.frame = contentView.bounds
    }

    @objc func updateUserLocation() {
//        guard let currentLocation = sceneLocationView.currentLocation else { return }
//
//        DispatchQueue.main.async {
//            if let bestEstimate = self.sceneLocationView.bestLocationEstimate,
//                let position = self.sceneLocationView.currentScenePosition {
//                DDLogDebug("")
//                DDLogDebug("Fetch current location")
//                DDLogDebug("best location estimate, position: \(bestEstimate.position), \(bestEstimate.location.debugLog)")
//                DDLogDebug("current position: \(position)")
//
//                let translation = bestEstimate.translatedLocation(to: position)
//
//                DDLogDebug("translation: \(translation)")
//                DDLogDebug("translated location: \(currentLocation)")
//                DDLogDebug("")
//            }
//
//            if self.userAnnotation == nil {
//                self.userAnnotation = MKPointAnnotation()
//                self.mapView.addAnnotation(self.userAnnotation!)
//            }
//
//            UIView.animate(withDuration: 0.5, delay: 0, options: .allowUserInteraction, animations: {
//                self.userAnnotation?.coordinate = currentLocation.coordinate
//            }, completion: nil)
//
//            if self.centerMapOnUserLocation {
//                UIView.animate(withDuration: 0.45,
//                               delay: 0,
//                               options: .allowUserInteraction,
//                               animations: {
//                    self.mapView.setCenter(self.userAnnotation!.coordinate, animated: false)
//                }, completion: { _ in
//                    self.mapView.region.span = MKCoordinateSpan(latitudeDelta: 0.0005, longitudeDelta: 0.0005)
//                })
//            }
//
//            if self.displayDebugging {
//                let bestLocationEstimate = self.sceneLocationView.bestLocationEstimate
//
//                if bestLocationEstimate != nil {
//                    if self.locationEstimateAnnotation == nil {
//                        self.locationEstimateAnnotation = MKPointAnnotation()
//                        self.mapView.addAnnotation(self.locationEstimateAnnotation!)
//                    }
//
//                    self.locationEstimateAnnotation!.coordinate = bestLocationEstimate!.location.coordinate
//                } else {
//                    if self.locationEstimateAnnotation != nil {
//                        self.mapView.removeAnnotation(self.locationEstimateAnnotation!)
//                        self.locationEstimateAnnotation = nil
//                    }
//                }
//            }
//        }
    }

    @objc func updateInfoLabel() {
        if let position = sceneLocationView.currentScenePosition {
            infoLabel.text = "x: \(position.x.short), y: \(position.y.short), z: \(position.z.short)\n"
        }

        if let eulerAngles = sceneLocationView.currentEulerAngles {
            infoLabel.text!.append("Euler x: \(eulerAngles.x.short), y: \(eulerAngles.y.short), z: \(eulerAngles.z.short)\n")
        }

//        if let heading = sceneLocationView.locationManager.heading,
//            let accuracy = sceneLocationView.locationManager.headingAccuracy {
//            infoLabel.text!.append("Heading: \(heading)º, accuracy: \(Int(round(accuracy)))º\n")
//        }

        let comp = Calendar.current.dateComponents([.hour, .minute, .second, .nanosecond], from: Date())
        if let hour = comp.hour, let minute = comp.minute, let second = comp.second, let nanosecond = comp.nanosecond {
            infoLabel.text!.append("\(hour.short):\(minute.short):\(second.short):\(nanosecond.short3)")
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first,
            let view = touch.view else { return }

        if mapView == view || mapView.recursiveSubviews().contains(view) {
            centerMapOnUserLocation = false
        } else {
            let location = touch.location(in: self.view)

            if location.x <= 40 && adjustNorthByTappingSidesOfScreen {
                print("left side of the screen")
                sceneLocationView.moveSceneHeadingAntiClockwise()
            } else if location.x >= view.frame.size.width - 40 && adjustNorthByTappingSidesOfScreen {
                print("right side of the screen")
                sceneLocationView.moveSceneHeadingClockwise()
            } else {
                let image = UIImage(named: "pin")!
                let annotationNode = LocationAnnotationNode(location: nil, image: image)
                annotationNode.scaleRelativeToDistance = true
                sceneLocationView.addLocationNodeForCurrentPosition(locationNode: annotationNode)
            }
        }
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation),
           let pointAnnotation = annotation as? MKPointAnnotation else { return nil }

        let marker = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: nil)

        if pointAnnotation == self.userAnnotation {
            marker.displayPriority = .required
            marker.glyphImage = UIImage(named: "user")
        } else {
            marker.displayPriority = .required
            marker.markerTintColor = UIColor(hue: 0.267, saturation: 0.67, brightness: 0.77, alpha: 1.0)
            marker.glyphImage = UIImage(named: "compass")
        }

        return marker
    }
}

extension ViewController: SceneLocationViewDelegate {
    func sceneLocationViewDidAddSceneLocationEstimate(sceneLocationView: SceneLocationView,
                                                      position: SCNVector3,
                                                      location: CLLocation) {
        DDLogDebug("add scene location estimate, position: \(position), \(location.debugLog)")
    }

    func sceneLocationViewDidRemoveSceneLocationEstimate(sceneLocationView: SceneLocationView,
                                                         position: SCNVector3,
                                                         location: CLLocation) {
        DDLogDebug("remove scene location estimate, position: \(position), \(location.debugLog)")
    }
}

extension DispatchQueue {
    func asyncAfter(timeInterval: TimeInterval, execute: @escaping () -> Void) {
        self.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(timeInterval * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC),
            execute: execute)
    }
}

extension UIView {
    func recursiveSubviews() -> [UIView] {
        var recursiveSubviews = self.subviews

        subviews.forEach { recursiveSubviews.append(contentsOf: $0.recursiveSubviews()) }

        return recursiveSubviews
    }
}
