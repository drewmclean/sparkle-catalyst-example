//
//  AppUpdateObserver.swift
//  AppKitPlugin
//
//  Created by Andrew McLean on 8/22/24.
//

import Foundation

@objc(AppUpdateObserver)
protocol AppUpdateObserver: NSObjectProtocol {
    typealias RelaunchRequestHandler = (Bool) -> Void
    
    func updateIsAvailableDidChange(updateIsAvailable: Bool, latestVersion: String, latestBuild: String)
    func updaterRequestedRelaunch(completion: RelaunchRequestHandler?)
    
}
