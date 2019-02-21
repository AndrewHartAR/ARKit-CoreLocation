//
//  LocationCell.swift
//  ARKit+CoreLocation
//
//  Created by Eric Internicola on 2/20/19.
//  Copyright © 2019 Project Dent. All rights reserved.
//

import MapKit
import UIKit

class LocationCell: UITableViewCell {

    var currentLocation: CLLocation? {
        didSet {
            updateCell()
        }
    }
    var mapItem: MKMapItem? {
        didSet {
            updateCell()
        }
    }

    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!

    override func prepareForReuse() {
        super.prepareForReuse()
        distanceLabel.text = nil
        titleLabel.text = nil
    }

}

// MARK: - Implementation

extension LocationCell {

    func updateCell() {
        guard let mapItem = mapItem else {
            return
        }
        titleLabel.text = mapItem.titleLabelText

        guard let currentLocation = currentLocation else {
            distanceLabel.text = "📡"
            return
        }
        guard let mapItemLocation = mapItem.placemark.location else {
            distanceLabel.text = "🤷‍♂️"
            return
        }

        distanceLabel.text = String(format: "%.0f km", mapItemLocation.distance(from: currentLocation)/1000)
    }

}

private extension MKMapItem {

    var titleLabelText: String {
        var result = ""

        if let name = name {
            result += name
        }
        if let addressDictionary = placemark.addressDictionary {
            if let street = addressDictionary["Street"] as? String {
                result += "\n\(street)"
            }
            if let city = addressDictionary["City"] as? String,
                let state = addressDictionary["State"] as? String,
                let zip = addressDictionary["ZIP"] as? String {
                result += "\n\(city), \(state) \(zip)"
            }
        } else if let location = placemark.location {
            result += "\n\(location.coordinate)"
        }

        return result
    }

}
