//
//  Plugin.swift
//  SparkleTest
//
//  Created by Andrew McLean on 5/23/24.
//

import Foundation

@objc(Plugin)
protocol Plugin: NSObjectProtocol {
    init()

    func startUpdater()
    func checkForUpdates(_ action: AnyObject)
    func checkForUpdatesInBackground()
    func checkForFeedForUpdate()
    
    func resetUpdateCycle()
    func resetUpdateCycleAfterShortDelay()
    
    func getLastUpdateCheckDate() -> Date?
    func getUpdateCheckInterval() -> TimeInterval
    func getAutomaticallyCheckForUpdates() -> Bool
    func setAutomaticallyCheckForUpdates(_ value: Bool)
    
    func getAutomaticallyDownloadsUpdates() -> Bool
    func setAutomaticallyDownloadsUpdates(_ value: Bool)
    
    func addAppUpdateObserver(_ observer: AppUpdateObserver)
    func removeAppUpdateObserver(_ observer: AppUpdateObserver)
}

