//
//  CGRect+Extensions.swift
//  ARKit+CoreLocation
//
//  Created by Andrew Hart on 09/07/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import UIKit
import MapKit

extension MKCoordinateRegion {
    ///Gives a rect where each of these rects intersect
    ///If a rect does not intersect, the intersection of the previous rects is returned
    static func bestPossibleIntersectingRegion(regions: [MKCoordinateRegion]) -> MKCoordinateRegion? {
        if regions.count == 0 {
            return nil
        }
        
        var intersectingRegion: MKCoordinateRegion?
        
        return intersectingRegion
        
//        for region in regions {
//            if intersectingRect == nil {
//                intersectingRect = rect
//            } else {
//                if !intersectingRect!.intersects(rect) {
//                    return intersectingRect
//                } else {
//                    intersectingRect = intersectingRect!.intersection(rect)
//                }
//            }
//        }
//
//        return intersectingRect
    }
    
    func intersection(with region: MKCoordinateRegion) -> MKCoordinateRegion? {
        let rect = self.rect()
        let regionRect = region.rect()
        
        if !rect.intersects(regionRect) {
            return nil
        }
        
        let intersectionRect = rect.intersection(regionRect)
        
        let intersectionCenter = CLLocationCoordinate2D(
            latitude: Double(intersectionRect.origin.y + (intersectionRect.size.height / 2)),
            longitude: Double(intersectionRect.origin.x + (intersectionRect.size.width / 2)))
        let intersectionSpan = MKCoordinateSpan(
            latitudeDelta: Double(intersectionRect.size.height),
            longitudeDelta: Double(intersectionRect.size.height))
        let intersection = MKCoordinateRegion(
            center: intersectionCenter, span: intersectionSpan)
        
        return intersection
    }
    
    func rect() -> CGRect {
        return CGRect(
            x: self.center.longitude - (self.span.longitudeDelta / 2),
            y: self.center.latitude - (self.span.latitudeDelta / 2),
            width: self.span.longitudeDelta,
            height: self.span.latitudeDelta)
    }
}
