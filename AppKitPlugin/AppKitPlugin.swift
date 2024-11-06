//
//  AppKitPlugin.swift
//  AppKitPlugin
//
//  Created by Andrew McLean on 5/23/24.
//

import AppKit
import Foundation
import Sparkle
import OSLog

@objc
class AppKitPlugin: NSObject, Plugin {

    private let log: Logger = .init(subsystem: Bundle.main.bundleIdentifier!, category: "AppKitPlugin")
    
    private lazy var appUpdater: AppUpdater = .init()
    
    required override init() {
        super.init()
    }
    
    // Called from the Catalyst app
    func startUpdater() {
        appUpdater.startUpdater()
    }
    
    func checkForUpdates(_ action: AnyObject) {
        appUpdater.checkForUpdates(action)
    }
    
    func checkForUpdatesInBackground() {
        appUpdater.checkForUpdatesInBackground()
    }
    
    func checkForFeedForUpdate() {
        appUpdater.checkForFeedForUpdate()
    }
    
    func resetUpdateCycle() {
        appUpdater.resetUpdateCycle()
    }
    
    func resetUpdateCycleAfterShortDelay() {
        appUpdater.resetUpdateCycleAfterShortDelay()
    }
    
    func getLastUpdateCheckDate() -> Date? {
        return appUpdater.getLastUpdateCheckDate()
    }
    
    func getUpdateCheckInterval() -> TimeInterval {
        return appUpdater.getUpdateCheckInterval()
    }
    
    func getAutomaticallyCheckForUpdates() -> Bool {
        return appUpdater.getAutomaticallyCheckForUpdates()
    }
    
    func setAutomaticallyCheckForUpdates(_ value: Bool) {
        appUpdater.setAutomaticallyCheckForUpdates(value)
    }
    
    func getAutomaticallyDownloadsUpdates() -> Bool {
        return appUpdater.getAutomaticallyDownloadsUpdates()
    }
    
    func setAutomaticallyDownloadsUpdates(_ value: Bool) {
        appUpdater.setAutomaticallyDownloadsUpdates(value)
    }
    
    func addAppUpdateObserver(_ observer: any AppUpdateObserver) {
        appUpdater.addAppUpdateObserver(observer)
    }
    
    func removeAppUpdateObserver(_ observer: any AppUpdateObserver) {
        appUpdater.removeAppUpdateObserver(observer)
    }
}

