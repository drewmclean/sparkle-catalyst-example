//
//  AppUpdater.swift
//  AppKitPlugin
//
//  Created by Andrew McLean on 8/22/24.
//

import Foundation
import OSLog
import Sparkle

final class AppUpdater : NSObject {
    private let log: Logger = .init(subsystem: Bundle.main.bundleIdentifier!, category: "AppUpdater")
    
    private var observers: [AppUpdateObserver] = []
    
    private var latestVersion: String = ""
    private var latestBuild: String = ""
    
    private let installedVersion: String
    private let installedBuild: String
    
    private var userAllowedRelaunch: Bool? = nil
    
    private lazy var updaterController: SPUStandardUpdaterController = .init(startingUpdater: false, updaterDelegate: self, userDriverDelegate: self)
    
    required override init() {
        self.installedVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        self.installedBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        
        super.init()
    }
    
    func startUpdater() {
        guard let feedURL: String = updaterController.updater.feedURL?.absoluteString else {
            log.error("Sparkle failed to start updater because the SUUpdateFeedURL Info.plist key is not defined.")
            return
        }
        
        let lastUpdateCheckDate: String = self.getLastUpdateCheckDate()?.description ?? "n/a"
            
        updaterController.updater.updateCheckInterval = 60 * 60 * 1 // every 1 hour

        updaterController.startUpdater()
        
        log.info("-----------------------------")
        log.info("- Starting Sparkle updater")
        log.debug("-     updateFeedURL: \(feedURL)")
        log.info("-     autoChecksForUpdates: \(self.getAutomaticallyCheckForUpdates())")
        log.info("-     autoDownloadsUpdates: \(self.getAutomaticallyDownloadsUpdates())")
        log.info("-     lastUpdateCheckDate: \(lastUpdateCheckDate)")
        log.info("-     updateCheckIntervalSeconds: \(self.getUpdateCheckInterval())")
        log.info("-----------------------------")
    }
    
    func checkForUpdates(_ action: AnyObject) {
        log.info("Manually checking for updates...")
        updaterController.checkForUpdates(action)
    }
    
    func checkForUpdatesInBackground() {
        log.info("Manually checking for updates in background...")
        updaterController.updater.checkForUpdatesInBackground()
    }
    
    func checkForFeedForUpdate() {
        log.info("Checking for update information...")
        guard let url = updaterController.updater.feedURL else {
            return
        }

        fetchSparkleFeed(url: url) { [weak self] data in
            guard
                let data,
                let self = self
            else { return }

            let parser = SparkleFeedParser()

            parser.parse(data: data) { [weak self] version, build in
                guard let self else { return }

                self.latestVersion = version
                self.latestBuild = build

                DispatchQueue.main.async {
                    self.notifyUpdateAvailableObservers()
                }
            }
        }
    }
    
    func resetUpdateCycle() {
        updaterController.updater.resetUpdateCycle()
    }
    
    func resetUpdateCycleAfterShortDelay() {
        updaterController.updater.resetUpdateCycleAfterShortDelay()
    }
    
    func getLastUpdateCheckDate() -> Date? {
        return updaterController.updater.lastUpdateCheckDate
    }
    
    func getUpdateCheckInterval() -> TimeInterval {
        return updaterController.updater.updateCheckInterval
    }
    
    func getAutomaticallyCheckForUpdates() -> Bool {
        return updaterController.updater.automaticallyChecksForUpdates
    }
    
    func setAutomaticallyCheckForUpdates(_ value: Bool) {
        updaterController.updater.automaticallyChecksForUpdates = value
    }
    
    func getAutomaticallyDownloadsUpdates() -> Bool {
        return updaterController.updater.automaticallyDownloadsUpdates
    }
    
    func setAutomaticallyDownloadsUpdates(_ value: Bool) {
        updaterController.updater.automaticallyDownloadsUpdates = value
    }
    
    func addAppUpdateObserver(_ observer: AppUpdateObserver) {
        if !observers.contains(where: { $0 === observer }) {
            observers.append(observer)
        }
    }
    
    func removeAppUpdateObserver(_ observer: AppUpdateObserver) {
        observers = observers.filter { $0 !== observer }
    }
    
    private func getUpdateIsAvailable() -> Bool {
        let result: ComparisonResult = SUStandardVersionComparator().compareVersion(installedBuild, toVersion: latestBuild)
        return result == .orderedAscending
    }
    
    private func notifyUpdateAvailableObservers() {
        guard
            latestVersion.isEmpty == false,
            latestBuild.isEmpty == false
        else { return }
        
        let updateIsAvailable: Bool = getUpdateIsAvailable()
        
        for observer in observers {
            observer.updateIsAvailableDidChange(
                updateIsAvailable: updateIsAvailable,
                latestVersion: latestVersion,
                latestBuild: latestBuild
            )
        }
    }
    
}

extension AppUpdater : SPUStandardUserDriverDelegate {
    
    func standardUserDriverWillShowModalAlert() {
        log.info("addUpdateAvailableObserver")
    }
    
    func standardUserDriverDidShowModalAlert() {
        log.info("standardUserDriverDidShowModalAlert")
        self.updaterController.userDriver.showUpdateInFocus()
    }
//    var supportsGentleScheduledUpdateReminders: Bool {
//        return false
//    }
    
//    func standardUserDriverShouldHandleShowingScheduledUpdate(_ update: SUAppcastItem, andInImmediateFocus immediateFocus: Bool) -> Bool {
//        // If the standard user driver will show the update in immediate focus (e.g. near app launch),
//        // then let Sparkle take care of showing the update.
//        // Otherwise we will handle showing any other scheduled updates
//        log.info("Sparkle standardUserDriverShouldHandleShowingScheduledUpdate immediateFocus: \(immediateFocus), sessionInProgress: \(self.updaterController.updater.sessionInProgress)")
//
//        return immediateFocus ||
//    }
//    
//    func standardUserDriverWillHandleShowingUpdate(_ handleShowingUpdate: Bool, forUpdate update: SUAppcastItem, state: SPUUserUpdateState) {
//        log.info("Sparkle standardUserDriverWillHandleShowingUpdate handleShowingUpdate: \(handleShowingUpdate) state: \(state.description)")
//        
//        // We will ignore updates that the user driver will handle showing
//        // This includes user initiated (non-scheduled) updates
//        guard !handleShowingUpdate else {
//            return
//        }
//        
//        // Notify observers that there is a new available update.
//        do {
//            latestVersion = update.displayVersionString
//            latestBuild = update.versionString
//            notifyUpdateAvailableObservers()
//        }
//    }
    
//    func standardUserDriverWillFinishUpdateSession() {
//        log.info("Sparkle standardUserDriverWillFinishUpdateSession")
//
//        notifyUpdateAvailableObservers()
//    }
    
}

extension AppUpdater : SPUUpdaterDelegate {
    
    func updater(_ updater: SPUUpdater, didDownloadUpdate item: SUAppcastItem) {
        log.info("Sparkle did download update: \(item.versionFull)")
    }
    
    func updater(_ updater: SPUUpdater, failedToDownloadUpdate item: SUAppcastItem, error: any Error) {
        log.error("Sparkle failed to download update item: \(item.versionFull), Error: \(error)")
    }
    
    func updater(_ updater: SPUUpdater, didExtractUpdate item: SUAppcastItem) {
        log.info("Sparkle did extract update item: \(item.versionFull)")
    }
    
    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        log.info("Sparkle did find valid update item: \(item.versionFull)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.updaterController.userDriver.showUpdateInFocus()
        }
    }
    
    func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        log.info("Sparkle did not find valid update")
    }
    
    func updater(_ updater: SPUUpdater, didFinishLoading appcast: SUAppcast) {
        log.info("Sparkle did did finish loading appcast")
        logAppcast(appcast)
    }
    
    func updater(_ updater: SPUUpdater, didFinishUpdateCycleFor updateCheck: SPUUpdateCheck, error: (any Error)?) {
        if let error {
            log.error("Sparkle update cycle finished with error: \(error)")
        } else {
            log.info("Sparkle update cycle finished. \(error)")
        }
    }
    
    func updater(_ updater: SPUUpdater, didAbortWithError error: any Error) {
        log.error("Sparkle didAbortWithError: \(error)")
    }
    
    func updater(_ updater: SPUUpdater, willScheduleUpdateCheckAfterDelay delay: TimeInterval) {
        log.info("Sparkle willScheduleUpdateCheckAfterDelay: \(delay)")
    }
    
    func updaterShouldRelaunchApplication(_ updater: SPUUpdater) -> Bool {
//        if let userAllowedRelaunch {
//            log.info("Sparkle updaterShouldRelaunchApplication userAllowedRelaunch: \(userAllowedRelaunch)")
//
//            return userAllowedRelaunch
//        }
//        
//        log.info("Sparkle updaterShouldRelaunchApplication true")
        return false
    }
    
    func updaterWillRelaunchApplication(_ updater: SPUUpdater) {
        log.info("Sparkle updaterWillRelaunchApplication")
    }
    
    func updater(_ updater: SPUUpdater, willInstallUpdate item: SUAppcastItem) {
        log.info("Sparkle willInstallUpdate")
    }
    
//    func updater(_ updater: SPUUpdater, willInstallUpdateOnQuit item: SUAppcastItem, immediateInstallationBlock immediateInstallHandler: @escaping () -> Void) -> Bool {
//            
//        return true
//    }
    
//    func updater(_ updater: SPUUpdater, shouldPostponeRelaunchForUpdate item: SUAppcastItem, untilInvokingBlock installHandler: @escaping () -> Void) -> Bool {
//        
//        userAllowedRelaunch = false
//        
//        log.info("Sparkle shouldPostponeRelaunchForUpdate observers: \(self.observers)")
//        
//        for observer in self.observers {
//            observer.updaterRequestedRelaunch { [weak self] allowedRelaunch in
//                guard let self else { return }
//                self.log.info("Sparkle user responded to userAllowedRelaunch: \(allowedRelaunch)")
//
//                self.userAllowedRelaunch = allowedRelaunch
//                
//                installHandler()
//            }
//        }
//        
//        return true
//    }
    
    private func fetchSparkleFeed(url: URL, completion: @escaping (Data?) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching feed: \(String(describing: error))")
                completion(nil)
                return
            }
            completion(data)
        }
        task.resume()
    }
    
    private func logAppcast(_ appcast: SUAppcast) {
        log.info("Appcast: ")
        for item in appcast.items {
            log.info("      \(item.versionFull)")
            log.info("       -----")
        }
    }
}
