//
//  SceneLocationView+AddLikeMapKit.swift
//  ARKit+CoreLocation
//
//  Created by Adrian Schoenig on 30.07.17.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import MapKit
import SceneKit

extension SceneLocationView {
  
  func addAnnotation(_ annotation: MKAnnotation) {
    guard let altitude = currentLocation()?.altitude else { return }

    let node = LocationAnnotationNode(annotation: annotation, altitude: altitude)
    addLocationNodeWithConfirmedLocation(locationNode: node)
  }
  
  func addAnnotations(_ annotations: [MKAnnotation]) {
    annotations.forEach(addAnnotation)
  }
  
  func addPolyline(_ polyline: MKPolyline) {
    guard let altitude = currentLocation()?.altitude else { return }
    
    LocationNode.create(polyline: polyline, altitude: altitude - 2)
      .forEach(addLocationNodeWithConfirmedLocation)
  }
  
  func addPolylines(_ polylines: [MKPolyline]) {
    polylines.forEach(addPolyline)
  }
  
}

extension LocationAnnotationNode {
  
  convenience init(annotation: MKAnnotation, image: UIImage? = nil, altitude: CLLocationDistance? = nil) {
    
    let location = CLLocation(coordinate: annotation.coordinate, altitude: altitude ?? 0)
    
    self.init(location: location, image: image ?? #imageLiteral(resourceName: "pin"))
    
    scaleRelativeToDistance = false
  }
  
}

extension LocationNode {
  
  static func create(polyline: MKPolyline, altitude: CLLocationDistance)  -> [LocationNode] {
    let points = polyline.points()
    
    let lightNode = SCNNode()
    lightNode.light = SCNLight()
    lightNode.light!.type = .ambient
    lightNode.light!.intensity = 25
    lightNode.light!.attenuationStartDistance = 100
    lightNode.light!.attenuationEndDistance = 100
    lightNode.position = SCNVector3(x: 0, y: 10, z: 0)
    lightNode.castsShadow = false
    lightNode.light!.categoryBitMask = 3
    
    let lightNode3 = SCNNode()
    lightNode3.light = SCNLight()
    lightNode3.light!.type = .omni
    lightNode3.light!.intensity = 100
    lightNode3.light!.attenuationStartDistance = 100
    lightNode3.light!.attenuationEndDistance = 100
    lightNode3.light!.castsShadow = true
    lightNode3.position = SCNVector3(x: -10, y: 10, z: -10)
    lightNode3.castsShadow = false
    lightNode3.light!.categoryBitMask = 3
    
    var nodes = [LocationNode]()
    
    for i in 0..<polyline.pointCount - 1 {
      let currentPoint = points[i]
      let currentCoordinate = MKCoordinateForMapPoint(currentPoint)
      let currentLocation = CLLocation(coordinate: currentCoordinate, altitude: altitude)
      
      let nextPoint = points[i + 1]
      let nextCoordinate = MKCoordinateForMapPoint(nextPoint)
      let nextLocation = CLLocation(coordinate: nextCoordinate, altitude: altitude)
      
      let distance = currentLocation.distance(from: nextLocation)
      
      let box = SCNBox(width: 1, height: 0.2, length: CGFloat(distance), chamferRadius: 0)
      box.firstMaterial?.diffuse.contents =  UIColor(hue: 0.589, saturation: 0.98, brightness: 1.0, alpha: 1)
      
      let bearing = 0 - bearingBetweenLocations(point1: currentLocation, point2: nextLocation)
      
      let boxNode = SCNNode(geometry: box)
      boxNode.pivot = SCNMatrix4MakeTranslation(0, 0, 0.5 * Float(distance))
      boxNode.eulerAngles.y = Float(bearing).degreesToRadians
      boxNode.categoryBitMask = 3
      boxNode.addChildNode(lightNode)
      boxNode.addChildNode(lightNode3)
      
      let locationNode = LocationNode(location: currentLocation)
      locationNode.addChildNode(boxNode)
      nodes.append(locationNode)
    }
    return nodes
  }
  
  private static func bearingBetweenLocations(point1 : CLLocation, point2 : CLLocation) -> Double {
    let lat1 = point1.coordinate.latitude.degreesToRadians
    let lon1 = point1.coordinate.longitude.degreesToRadians
    
    let lat2 = point2.coordinate.latitude.degreesToRadians
    let lon2 = point2.coordinate.longitude.degreesToRadians
    
    let dLon = lon2 - lon1
    
    let y = sin(dLon) * cos(lat2)
    let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
    let radiansBearing = atan2(y, x)
    
    return radiansBearing.radiansToDegrees
  }
  
}
