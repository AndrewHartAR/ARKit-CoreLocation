//
//  PickerViewController.swift
//  Node Demos
//
//  Created by Hal Mueller on 9/29/19.
//  Copyright © 2019 Project Dent. All rights reserved.
//

import UIKit

class PickerViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func showStackedNodes(_ sender: Any) {
    performSegue(withIdentifier: "showARCL", sender: sender)
        
    }

}

