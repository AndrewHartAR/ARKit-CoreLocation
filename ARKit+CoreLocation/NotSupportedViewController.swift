//
//  NotSupportedViewController.swift
//  ARKit+CoreLocation
//
//  Created by Vihan Bhargava on 9/2/17.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import UIKit

class NotSupportedViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .white
        
        let label = UILabel()
        label.textAlignment = .center
        label.text = "iOS 11+ required"
        
        self.view.addSubview(label)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
    }
    
}
