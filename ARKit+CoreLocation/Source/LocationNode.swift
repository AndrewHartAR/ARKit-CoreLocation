//
//  LocationNode.swift
//  ARKit+CoreLocation
//
//  Created by Andrew Hart on 02/07/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import Foundation
import SceneKit
import CoreLocation

/// A location node can be added to a scene using a coordinate.
/// Its scale and position should not be adjusted, as these are used for scene layout purposes
/// To adjust the scale and position of items within a node, you can add them to a child node and adjust them there
open class LocationNode: SCNNode {
    /// Location can be changed and confirmed later by SceneLocationView.
    public var location: CLLocation!
    
    /// Whether the location of the node has been confirmed.
    /// This is automatically set to true when you create a node using a location.
    /// Otherwise, this is false, and becomes true once the user moves 100m away from the node,
    /// except when the locationEstimateMethod is set to use Core Location data only,
    /// as then it becomes true immediately.
    public var locationConfirmed = false
    
    /// Whether a node's position should be adjusted on an ongoing basis
    /// based on its' given location.
    /// This only occurs when a node's location is within 100m of the user.
    /// Adjustment doesn't apply to nodes without a confirmed location.
    /// When this is set to false, the result is a smoother appearance.
    /// When this is set to true, this means a node may appear to jump around
    /// as the user's location estimates update,
    /// but the position is generally more accurate.
    /// Defaults to true.
    public var continuallyAdjustNodePositionWhenWithinRange = true
    
    /// Whether a node's position and scale should be updated automatically on a continual basis.
    /// This should only be set to false if you plan to manually update position and scale
    /// at regular intervals. You can do this with `SceneLocationView`'s `updatePositionOfLocationNode`.
    public var continuallyUpdatePositionAndScale = true
    
    public init(location: CLLocation?) {
        self.location = location
        self.locationConfirmed = location != nil
        super.init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

open class LocationAnnotationNode: LocationNode {
    /// Whether the node should be scaled relative to its distance from the camera
    /// Default value (false) scales it to visually appear at the same size no matter the distance
    /// Setting to true causes annotation nodes to scale like a regular node
    /// Scaling relative to distance may be useful with local navigation-based uses
    /// For landmarks in the distance, the default is correct
    public var scaleRelativeToDistance = false
    
    /// Creates a new location node with an image as the indicator.
    ///
    /// - Parameters:
    ///   - location: `CLLocation` object with location of node or nil
    ///   - image: UIImage to display
    public convenience init(location: CLLocation?, image: UIImage) {
        self.init(
            location: location,
            geometry: SCNPlane(width: image.size.width / 100, height: image.size.height / 100),
            content: image
        )
    }
    
    /// Creates a new location node displaying a UIView. UIView should prefferable not be
    /// displayed on the screen otherwise it will have to be copied. The `UIView` should
    /// have implemented `NSCoder` properly otherwise this will return `nil`.
    ///
    /// - Parameters:
    ///   - location: `CLLocation` object with location of node or nil
    ///   - uiView: UIView to display.
    public convenience init?(location: CLLocation?, uiView: UIView) {
        var view: UIView = uiView
        
        if uiView.superview != nil {
            guard let uiViewCopy = NSKeyedUnarchiver.unarchiveObject(
                with: NSKeyedArchiver.archivedData(withRootObject: uiView)
            ) as? UIView else { return nil }
            
            view = uiViewCopy
        }
     
        // Just in case
        view.removeFromSuperview()
        
        self.init(
            location: location,
            layer: view.layer
        )
    }
    
    /// Creates a new location node displaying a CALayer. The CALayer should be being displayed anywhere
    /// otherwise it might not accurately be displayed.
    ///
    /// - Parameters:
    ///   - location: `CLLocation` object with location of node or nil
    ///   - layer: CALayer to display.
    public convenience init(location: CLLocation?, layer: CALayer) {
        self.init(
            location: location,
            geometry: SCNPlane(width: layer.bounds.width, height: layer.bounds.height),
            content: layer
        )
    }
    
    /// Creates a LocationNode with a geometry and some contents as the texture. This uses content as the
    /// first texture. If you are using a geometry with more than one material (e.g. SCNBox) you may need
    /// to add more materials using `node.geometry.materials`.
    ///
    /// - Parameters:
    ///   - location: `CLLocation` object with location of node or nil
    ///   - geometry: desired geometry of the object (sets `self.geometry`)
    ///   - content: Content passed to `SCNMaterialProperty()`'s `contents` field on the geometry.
    public convenience init(location: CLLocation?, geometry: SCNGeometry, content: Any?) {
        self.init(location: location)
        
        self.geometry = geometry
        
        let material = SCNMaterial()
        material.diffuse.contents = content
        material.lightingModel = .constant
        
        geometry.firstMaterial = material
    }
    
    /// Creates a node with at a location and with a billboard constraint so it always faces the user.
    ///
    /// - Parameter location: `CLLocation` object with location of node or nil
    public override init(location: CLLocation?) {
        super.init(location: location)
        
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        self.constraints = [billboardConstraint]
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
