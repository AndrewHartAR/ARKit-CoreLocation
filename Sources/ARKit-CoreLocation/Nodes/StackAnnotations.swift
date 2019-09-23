//
//  StackAnnotations.swift
//  ARKit+CoreLocation
//
//  Created by Jacopo Gasparetto on 18/09/2019.
//
//  Credits to https://github.com/DanijelHuis/HDAugmentedReality

import Foundation
import SceneKit

@available(iOS 11.0, *)
extension SceneLocationView {
    	
	func stackAnnotations() {
		guard self.locationNodes.count > 0 else { return }
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.3
        
        // Filter only locationNodes that should be stacked
        var sortedLocationNodes = self.locationNodes.filter{$0.shouldStackAnnotation} as! [LocationAnnotationNode]
        
        // Sort nodes by distance with the user
        if let userLocation = self.sceneLocationManager.currentLocation {
            sortedLocationNodes = sortedLocationNodes.sorted(by:
                {$0.location.distance(from: userLocation) < $1.location.distance(from: userLocation)})
        }
        
		for locationNode1 in sortedLocationNodes {
			// Dectecting collision
			let node1 = locationNode1.childNodes.first!
            
			var hasCollision = false
			var i = 0
			while i < sortedLocationNodes.count {
				let locationNode2 = sortedLocationNodes[i]
				               
                if (locationNode2 == locationNode1) {
					// If collision, start over because movement could cause additional collisions
					if hasCollision {
						hasCollision = false
						i = 0
						continue
					}
					break
				}
                
                let node2 = locationNode2.childNodes.first!
                
				// If the angle between two nodes and the user is less than a threshold and the vertical distance
                // between the node centers is less than deltaY trheshold a collision occured and move the node up
                let angle = angleBetweenTwoPointsAndUser(pointA: node1.worldPosition, pointB: node2.worldPosition)
                let angleMin = CGFloat(2.5 * atan(node1.scale.x / 100)) // You can change 2.5 to your requirements
                
                let deltaY = abs(node1.worldPosition.y - node2.worldPosition.y)
                let deltaYMin = 2 * node1.boundingBox.max.y * node1.scale.y
                
                // We have a collision, move the node 1 up
                if deltaY < deltaYMin && angle < angleMin {
                    node1.position.y += node2.boundingBox.max.y + stackingOffset
					hasCollision = true
				}
				i += 1
			}
		}
        
        // Traslate all nodes down by half of the maximum y position among all nodes.
        // This could be improved without moving (i.e. keeping at y = 0) whose nodes that dont have other nodes on top
        if let heighestNode = sortedLocationNodes.max(by:
            {a, b in a.childNodes.first!.worldPosition.y < b.childNodes.first!.worldPosition.y}) {
            for locationNode in sortedLocationNodes {
                locationNode.childNodes.first!.position.y = locationNode.childNodes.first!.position.y -
                    heighestNode.childNodes.first!.worldPosition.y / 2
            }
        }
        SCNTransaction.commit()
	}
	
	/// Compute the angle between the user position and two points on the xz plane using the cosine
	/// c^2 = a^2 + b^2 - 2ab * cos(x) -> x = arccos[(a^2 + b^2 - c^2) / 2ab]
	private func angleBetweenTwoPointsAndUser(pointA: SCNVector3, pointB: SCNVector3) -> CGFloat {
        if let userLocation = self.currentScenePosition {
			let A = CGPoint(x: CGFloat(pointA.x), y: CGFloat(pointA.z))
			let B = CGPoint(x: CGFloat(pointB.x), y: CGFloat(pointB.z))
			let U = CGPoint(x: CGFloat(userLocation.x), y: CGFloat(userLocation.z))
			
            let a = A.distance(to: U)
            let b = B.distance(to: U)
            let c = A.distance(to: B)
			return acos((a*a + b*b - c*c) / (2 * a*b))
		} else {
			return 0.0
		}
	}
}



extension CGPoint {
    /// Calculate the distance between two points in 2D
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
    }
}

extension SCNVector3 {
	var description: String {
		return "(x: \(x), y: \(y), z: \(z))"
	}
	
    /// Compute distance between two 3D points
	func distance(vector: SCNVector3) -> Float {
		return sqrt(pow((self.x - vector.x), 2) + pow(self.y - vector.y, 2) + pow((self.z - vector.z), 2))
	}
    
    /// Compute the z-distance between 3D points of xy plane
    func zDistance(to vector: SCNVector3) -> CGFloat {
        let A = CGPoint(x: CGFloat(x), y: CGFloat(z))
        let B = CGPoint(x: CGFloat(vector.x), y: CGFloat(vector.z))
        return A.distance(to: B)
    }
}

