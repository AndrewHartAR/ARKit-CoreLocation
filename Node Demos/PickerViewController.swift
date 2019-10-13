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

    var locationEstimateMethod = LocationEstimateMethod.mostRelevantEstimate

    var arTrackingType = SceneLocationView.ARTrackingType.worldTracking

    var scalingScheme = ScalingScheme.normal
    // I have absolutely no idea what reasonable values for these scaling parameters would be.
    var threshold1: Double = 100.0
    var scale1: Float = 0.85
    var threshold2: Double = 400.0
    var scale2: Float = 0.5
    var buffer: Double = 100.0

    var continuallyAdjustNodePositionWhenWithinRange = true
    var continuallyUpdatePositionAndScale = true

    // MARK: - Outlets

    @IBOutlet weak var annoHeightAdjustFactorField: UITextField!
    @IBOutlet weak var locationEstimateMethodSegController: UISegmentedControl!
    @IBOutlet weak var trackingTypeSegController: UISegmentedControl!
    @IBOutlet weak var adjustNodePositionWithinRangeSwitch: UISwitch!
    @IBOutlet weak var updateNodePositionAndScaleSwitch: UISwitch!
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

    // MARK: - Lifecycle and text field delegate

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        annoHeightAdjustFactorField.text = "\(annotationHeightAdjustmentFactor)"

        updateLocationEstimateMethodSegController()

        updateTrackingTypeController()

        adjustNodePositionWithinRangeSwitch.isOn = continuallyAdjustNodePositionWhenWithinRange
        updateNodePositionAndScaleSwitch.isOn = continuallyUpdatePositionAndScale

        threshold1Field.text = "\(threshold1)"
        threshold2Field.text = "\(threshold2)"
        scale1Field.text = "\(scale1)"
        scale2Field.text = "\(scale2)"
        bufferField.text = "\(buffer)"
        updateScalingSchemeSegController()
        updateScalingParameterCells()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    // MARK: - demo launch actions

    @IBAction func showJustOneNode(_ sender: Any) {
        performSegue(withIdentifier: "justOneNode", sender: sender)
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

    @IBAction func showLiveNodes(_ sender: Any) {
        performSegue(withIdentifier: "liveNodes", sender: sender)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? ARCLViewController {
            destination.annotationHeightAdjustmentFactor = annotationHeightAdjustmentFactor
            destination.scalingScheme = scalingScheme
            destination.locationEstimateMethod = locationEstimateMethod
            destination.arTrackingType = arTrackingType
            destination.continuallyUpdatePositionAndScale = continuallyUpdatePositionAndScale
            destination.continuallyAdjustNodePositionWhenWithinRange = continuallyAdjustNodePositionWhenWithinRange

            if segue.identifier == "justOneNode" {
                destination.demonstration = .justOneNode
            }
            else if segue.identifier == "stackOfNodes" {
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
            else if segue.identifier == "liveNodes" {
                destination.demonstration = .dynamicNodes
            }
        }
    }

    // MARK: - Y annotation factor and some toggles

    @IBAction func yAnnoFactorChanged(_ sender: UITextField) {
        if let text = sender.text,
            let newValue = Double(text) {
            annotationHeightAdjustmentFactor = newValue
        }
    }

    @IBAction func locationEstimateMethodChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            locationEstimateMethod = .coreLocationDataOnly
        case 1:
            locationEstimateMethod = .mostRelevantEstimate
        default:
            locationEstimateMethod = .mostRelevantEstimate
        }
    }

    @IBAction func continuallyAdjustNodePositionWhenWithinRangeChanged(_ sender: UISwitch) {
        continuallyAdjustNodePositionWhenWithinRange = sender.isOn
    }

    @IBAction func continuallyUpdatePositionAndScaleChanged(_ sender: UISwitch) {
        continuallyUpdatePositionAndScale = sender.isOn
    }

    fileprivate func updateLocationEstimateMethodSegController() {
        switch locationEstimateMethod {
        case .coreLocationDataOnly:
            locationEstimateMethodSegController.selectedSegmentIndex = 0
        case .mostRelevantEstimate:
            locationEstimateMethodSegController.selectedSegmentIndex = 1
        }
    }

    @IBAction func trackingTypeChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            arTrackingType = SceneLocationView.ARTrackingType.worldTracking
        case 1:
            arTrackingType = SceneLocationView.ARTrackingType.orientationTracking
        default:
            arTrackingType = SceneLocationView.ARTrackingType.worldTracking
        }
    }

    fileprivate func updateTrackingTypeController() {
        switch arTrackingType {
        case .worldTracking:
            trackingTypeSegController.selectedSegmentIndex = 0
        case .orientationTracking:
            trackingTypeSegController.selectedSegmentIndex = 1
        }
    }

    // MARK: - Scaling scheme

    @IBAction func threshold1Changed(_ sender: UITextField) {
        if let text = sender.text,
            let newValue = Double(text) {
            threshold1 = newValue
        }
        recomputeScalingScheme()
    }

    @IBAction func threshold2Changed(_ sender: UITextField) {
        if let text = sender.text,
            let newValue = Double(text) {
            threshold2 = newValue
        }
        recomputeScalingScheme()
    }

    @IBAction func scale1Changed(_ sender: UITextField) {
        if let text = sender.text,
            let newValue = Float(text) {
            scale1 = newValue
        }
        recomputeScalingScheme()
    }

    @IBAction func scale2Changed(_ sender: UITextField) {
        if let text = sender.text,
            let newValue = Float(text) {
            scale2 = newValue
        }
        recomputeScalingScheme()
    }

    @IBAction func bufferChanged(_ sender: UITextField) {
        if let text = sender.text,
            let newValue = Double(text) {
            buffer = newValue
        }
        recomputeScalingScheme()
    }

    @IBAction func scalingSchemeChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            scalingScheme = .normal
        case 1:
            scalingScheme = .tiered(threshold: threshold1, scale: scale1)
        case 2:
            scalingScheme = .doubleTiered(firstThreshold: threshold1, firstScale: scale1,
                                          secondThreshold: threshold2, secondScale: scale2)
        case 3:
            scalingScheme = .linear(threshold: threshold1)
        case 4:
            scalingScheme = .linearBuffer(threshold: threshold1, buffer: buffer)
        default:
            scalingScheme = .normal
        }
        updateScalingParameterCells()
    }

    /// Yes, this code is very repetitive of `scalingSchemeChanged`. I could make it more DRY by adding
    /// a computed property to `ScalingScheme`, but I don't want to mess with library code any more than necessary just for this demo.
    /// https://medium.com/@PhiJay/why-swift-enums-with-associated-values-cannot-have-a-raw-value-21e41d5ec11 has a good discussion.
    fileprivate func recomputeScalingScheme() {
        switch scalingScheme {
        case .normal:
            scalingScheme = .normal
        case .tiered:
            scalingScheme = .tiered(threshold: threshold1, scale: scale1)
        case .doubleTiered:
            scalingScheme = .doubleTiered(firstThreshold: threshold1, firstScale: scale1, secondThreshold: threshold2, secondScale: scale2)
        case .linear:
            scalingScheme = .linear(threshold: threshold1)
        case .linearBuffer:
            scalingScheme = .linearBuffer(threshold: threshold1, buffer: buffer)
        }
    }

    fileprivate func updateScalingParameterCells() {
        for cell in scalingParameterCells {
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
}
