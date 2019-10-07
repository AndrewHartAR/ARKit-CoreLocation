//
//  PickerViewController.swift
//  Node Demos
//
//  Created by Hal Mueller on 9/29/19.
//  Copyright © 2019 Project Dent. All rights reserved.
//

import UIKit
import ARCL

class PickerViewController: UITableViewController, UITextFieldDelegate {

    // Originally, the hard-coded factor to raise an annotation's label within the viewport was 1.1.
    var annotationHeightAdjustmentFactor = 1.1

    var scalingScheme = ScalingScheme.normal
    // I have absolutely no idea what reasonable values for these scaling parameters would be.
    var threshold1: Double = 100.0
    var scale1: Float = 0.85
    var threshold2: Double = 400.0
    var scale2: Float = 0.5
    var buffer: Double = 100.0

    @IBOutlet weak var annoHeightAdjustFactorField: UITextField!
    @IBOutlet weak var scalingSchemeSegController: UISegmentedControl!
    @IBOutlet weak var threshold1Field: UITextField!
    @IBOutlet weak var scale1Field: UITextField!
    @IBOutlet weak var threshold2Field: UITextField!
    @IBOutlet weak var scale2Field: UITextField!
    @IBOutlet weak var bufferField: UITextField!

    @IBOutlet var scalingParameterCells: [UITableViewCell]!
    @IBOutlet weak var threshold1Cell: UITableViewCell!
    @IBOutlet weak var scale1Cell: UITableViewCell!
    @IBOutlet weak var threshold2cell: UITableViewCell!
    @IBOutlet weak var scale2Cell: UITableViewCell!
    @IBOutlet weak var bufferCell: UITableViewCell!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        annoHeightAdjustFactorField.text = "\(annotationHeightAdjustmentFactor)"
        threshold1Field.text = "\(threshold1)"
        threshold2Field.text = "\(threshold2)"
        scale1Field.text = "\(scale1)"
        scale2Field.text = "\(scale2)"
        bufferField.text = "\(buffer)"
        updateScalingSchemeSegController()
        updateScalingParameterCells()
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
            destination.annotationHeightAdjustmentFactor = annotationHeightAdjustmentFactor
            destination.scalingScheme = scalingScheme
            
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

    @IBAction func threshold1Changed(_ sender: UITextField) {
        if let text = sender.text,
            let newValue = Double(text) {
            threshold1 = newValue
        }
    }

    @IBAction func threshold2Changed(_ sender: UITextField) {
        if let text = sender.text,
            let newValue = Double(text) {
            threshold2 = newValue
        }
    }

    @IBAction func scale1Changed(_ sender: UITextField) {
        if let text = sender.text,
            let newValue = Float(text) {
            scale1 = newValue
        }
    }

    @IBAction func scale2Changed(_ sender: UITextField) {
        if let text = sender.text,
            let newValue = Float(text) {
            scale2 = newValue
        }
    }

    @IBAction func bufferChanged(_ sender: UITextField) {
        if let text = sender.text,
            let newValue = Double(text) {
            buffer = newValue
        }
    }

    @IBAction func scalingSchemeChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            scalingScheme = .normal
        case 1:
            scalingScheme = .tiered(threshold: threshold1, scale: scale1)
        case 2:
            scalingScheme = .doubleTiered(firstThreshold: threshold1, firstScale: scale1, secondThreshold: threshold2, secondScale: scale2)
        case 3:
            scalingScheme = .linear(threshold: threshold1)
        case 4:
            scalingScheme = .linearBuffer(threshold: threshold1, buffer: buffer)
        default:
            scalingScheme = .normal
        }
        updateScalingParameterCells()
    }

    fileprivate func updateScalingParameterCells() {
        for cell in scalingParameterCells {
            print(cell)
            cell.accessoryType = .none
        }
        switch scalingScheme {
        case .normal:
            break
        case .tiered:
            threshold1Cell.accessoryType = .checkmark
            scale1Cell.accessoryType = .checkmark
        case .doubleTiered:
            threshold1Cell.accessoryType = .checkmark
            scale1Cell.accessoryType = .checkmark
            threshold2cell.accessoryType = .checkmark
            scale2Cell.accessoryType = .checkmark
        case .linear:
            threshold1Cell.accessoryType = .checkmark
        case .linearBuffer:
            threshold1Cell.accessoryType = .checkmark
            bufferCell.accessoryType = .checkmark
        }
    }
    fileprivate func updateScalingSchemeSegController() {
        switch scalingScheme {
        case .normal:
            scalingSchemeSegController.selectedSegmentIndex = 0
        case .tiered:
            scalingSchemeSegController.selectedSegmentIndex = 1
        case .doubleTiered:
            scalingSchemeSegController.selectedSegmentIndex = 2
        case .linear:
            scalingSchemeSegController.selectedSegmentIndex = 3
        case .linearBuffer:
            scalingSchemeSegController.selectedSegmentIndex = 4
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

