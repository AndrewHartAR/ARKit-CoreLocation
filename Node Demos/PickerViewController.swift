//
//  PickerViewController.swift
//  Node Demos
//
//  Created by Hal Mueller on 9/29/19.
//  Copyright © 2019 Project Dent. All rights reserved.
//

import UIKit

class PickerViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var annotationHeightAdjustmentFactorField: UITextField!
    @IBOutlet weak var scalingTypeSegControl: UISegmentedControl!
    var annotationHeightAdjustmentFactor = 1.1

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        annotationHeightAdjustmentFactorField.text = "\(annotationHeightAdjustmentFactor)"
    }

    @IBAction func showStackedNodes(_ sender: Any) {
        performSegue(withIdentifier: "stackOfNodes", sender: sender)
    }

    @IBAction func showFieldOfNodes(_ sender: Any) {
        performSegue(withIdentifier: "fieldOfNodes", sender: sender)
    }

    @IBAction func showFieldOflabels(_ sender: Any) {
        performSegue(withIdentifier: "fieldOfLabels", sender: sender)
    }

    @IBAction func showFieldOfRadii(_ sender: Any) {
        performSegue(withIdentifier: "fieldOfRadii", sender: sender)
    }

    @IBAction func showSpriteKitNodes(_ sender: Any) {
        performSegue(withIdentifier: "spriteKitNodes", sender: sender)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? ARCLViewController {
            if segue.identifier == "stackOfNodes" {
                destination.demonstration = .stackOfNodes
            }
            else if segue.identifier == "fieldOfNodes" {
                destination.demonstration = .fieldOfNodes
            }
            else if segue.identifier == "fieldOfLabels" {
                destination.demonstration = .fieldOfLabels
            }
            else if segue.identifier == "fieldOfRadii" {
                destination.demonstration = .fieldOfRadii
            }
            else if segue.identifier == "spriteKitNodes" {
                destination.demonstration = .spriteKitNodes
            }
        }
    }

    @IBAction func yAnnoFactorChanged(_ sender: UITextField) {
        if let text = sender.text,
            let newValue = Double(text) {
            annotationHeightAdjustmentFactor = newValue
        }
    }

    @IBAction func backgroundTapped(_ sender: Any) {
        view.endEditing(true)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

