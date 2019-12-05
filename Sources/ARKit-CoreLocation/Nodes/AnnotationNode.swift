////
////  SceneAnnotation.swift
////  ARKit+CoreLocation
////
////  Created by Andrew Hart on 02/07/2017.
////  Copyright © 2017 Project Dent. All rights reserved.
////

import Foundation
import SceneKit
import CoreLocation

/// This node type enables the client to have access to the view or image that
/// was used to initialize the `LocationAnnotationNode`. An `AnnotationNode` will
/// be a child node of a `LocationAnnotationNode`.
open class AnnotationNode: SCNNode {
    public var view: UIView?
    public var image: UIImage?
    public var layer: CALayer?

    public init(view: UIView?, image: UIImage?, layer: CALayer? = nil) {
        super.init()
        self.view = view
        self.image = image
        self.layer = layer
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

