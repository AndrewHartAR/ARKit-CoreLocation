//
//  Utils.swift
//  ARKit+CoreLocation
//
//  Created by Ilya Seliverstov on 09/08/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import UIKit

class Utils {
    fileprivate init () { }

    class func getStoryboard(_ storyboard: String = "Main") -> UIStoryboard {
        return UIStoryboard(name: storyboard, bundle: Bundle.main)
    }

    class func createViewController<T: UIViewController>(_ identifier: String, storyboard: String = "Main") -> T {
        return Utils.getStoryboard(storyboard)
            .instantiateViewController(withIdentifier: identifier) as! T // swiftlint:disable:this force_cast
    }
}
