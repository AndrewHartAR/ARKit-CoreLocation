//
//  SettingsViewController.swift
//  ARKit+CoreLocation
//
//  Created by Eric Internicola on 2/19/19.
//  Copyright © 2019 Project Dent. All rights reserved.
//

import MapKit
import UIKit

@available(iOS 11.0, *)
class SettingsViewController: UIViewController {

    weak var arclViewController: ARCLViewController?

    @IBOutlet weak var showMapSwitch: UISwitch!
    @IBOutlet weak var showPointsOfInterest: UISwitch!
    @IBOutlet weak var showRouteDirections: UISwitch!
    @IBOutlet weak var addressText: UITextField!
    @IBOutlet weak var searchResultTable: UITableView!
    @IBOutlet weak var refreshControl: UIActivityIndicatorView!

    var mapSearchResults: [MKMapItem]?
    var existingRoutes: [MKRoute]?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        showMapSwitch.isOn = arclViewController?.showMap ?? false
        searchResultTable.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }

    @IBAction
    func toggledSwitch(_ sender: UISwitch) {
        if sender == showMapSwitch {
            arclViewController?.showMap = sender.isOn
        } else if sender == showPointsOfInterest {
            showRouteDirections.isOn = !sender.isOn
        } else if sender == showRouteDirections {
            showPointsOfInterest.isOn = !sender.isOn
            if sender.isOn {
                addressText.becomeFirstResponder()
            }
        }
    }

    @IBAction
    func tappedSearch(_ sender: Any) {
        guard let text = addressText.text, !text.isEmpty else {
            return
        }
        searchForLocation()
    }
}

// MARK: - DataSource

@available(iOS 11.0, *)
extension SettingsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let mapSearchResults = mapSearchResults else {
            return 0
        }

        return mapSearchResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        guard let mapSearchResults = mapSearchResults, indexPath.row < mapSearchResults.count else {
            return cell
        }
        cell.textLabel?.text = mapSearchResults[indexPath.row].placemark.debugDescription

        return cell
    }
}

// MARK: - UITableViewDelegate

@available(iOS 11.0, *)
extension SettingsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let mapSearchResults = mapSearchResults, indexPath.row < mapSearchResults.count else {
            return
        }
        let selectedMapItem = mapSearchResults[indexPath.row]
        getDirections(to: selectedMapItem)
    }

}

// MARK: - Implementation

@available(iOS 11.0, *)
private extension SettingsViewController {

    func getDirections(to mapLocation: MKMapItem) {
        refreshControl.startAnimating()

        let request = MKDirections.Request()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = mapLocation
        request.requestsAlternateRoutes = false

        let directions = MKDirections(request: request)

        directions.calculate(completionHandler: { response, error in
            defer {
                DispatchQueue.main.async { [weak self] in
                    self?.refreshControl.stopAnimating()
                }
            }
            if let error = error {
                return print("Error getting directions: \(error.localizedDescription)")
            }
            guard let response = response else {
                return assertionFailure("No error, but no response, either.")
            }

            DispatchQueue.main.async { [weak self] in
                if let existingRoutes = self?.existingRoutes {
                    self?.arclViewController?.sceneLocationView.removeRoutes(routes: existingRoutes)
                }
                self?.arclViewController?.sceneLocationView.addRoutes(routes: response.routes)
                self?.existingRoutes = response.routes
                self?.navigationController?.popViewController(animated: true)
            }
        })
    }

    /// Searches for the location that was entered into the address text
    func searchForLocation() {
        guard let addressText = addressText.text, !addressText.isEmpty else {
            return assertionFailure("We've goto some issues")
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = addressText

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let error = error {
                return assertionFailure("Error searching for \(addressText): \(error.localizedDescription)")
            }
            guard let response = response, response.mapItems.count > 0 else {
                return assertionFailure("No response or empty response")
            }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                self.mapSearchResults = response.mapItems
                self.searchResultTable.reloadData()
            }
            response.mapItems.forEach { location in
                guard let name = location.name else {
                    return
                }
                print("\(name): \(location.placemark.coordinate)")
            }
        }
    }
}
