//
//  AppDelegate.swift
//  ARKit+CoreLocation
//
//  Created by Andrew Hart on 02/07/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import CocoaLumberjack
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        DDLog.add(DDTTYLogger.sharedInstance) // TTY = Xcode console
        let fileLogger: DDFileLogger = DDFileLogger() // File Logger
        fileLogger.rollingFrequency = TimeInterval(60 * 60 * 24)  // 24 hours
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
        DDLog.add(fileLogger)

        DDLogDebug("NEW SESSION")

        UIApplication.shared.isIdleTimerDisabled = true

        self.window = UIWindow(frame: UIScreen.main.bounds)

        self.window!.makeKeyAndVisible()

        if #available(iOS 11.0, *) {
            let vc = ViewController()
            self.window!.rootViewController = vc
        } else {
            self.window!.rootViewController = NotSupportedViewController()
        }

        return true
    }
}
