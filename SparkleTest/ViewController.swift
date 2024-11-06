//
//  ViewController.swift
//  SparkleTest
//
//  Created by Andrew McLean on 5/23/24.
//

import UIKit
import OSLog

final class ViewController: UIViewController, AppUpdateObserver {
    
    private let log: Logger = .init(subsystem: Bundle.main.bundleIdentifier!, category: "ViewController")
    
    private let dateFormatter: DateFormatter = {
        let formatter: DateFormatter = .init()
        formatter.dateStyle = .short
        formatter.timeStyle = .long
        return formatter
    }()
    
    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .vertical
        sv.alignment = .fill
        sv.distribution = .fillProportionally
        sv.spacing = 20
        sv.backgroundColor = .systemBackground
        sv.clipsToBounds = true
        sv.layer.cornerRadius = 10
        sv.layer.cornerCurve = .continuous
        sv.isLayoutMarginsRelativeArrangement = true
        sv.layoutMargins = .init(top: 20, left: 20, bottom: 20, right: 20)
        return sv
    }()

    private let infoLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = .label
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 20, weight: .regular)
        return label
    }()

    private let autoCheckForUpdatesStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.alignment = .center
        sv.spacing = 10
        return sv
    }()
    
    private let autoCheckForUpdatesLabel: UILabel = {
        let label = UILabel()
        label.text = "Automatically Check for Updates"
        label.textColor = .label
        label.font = .systemFont(ofSize: 20, weight: .bold)
        return label
    }()
    
    private let autoCheckForUpdatesSwitch: UISwitch = .init()
    
    private let autoDownloadsUpdatesStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.alignment = .center
        sv.spacing = 10
        return sv
    }()
    
    private let autoDownloadsUpdatesLabel: UILabel = {
        let label = UILabel()
        label.text = "Automatically Downloads Updates"
        label.textColor = .label
        label.font = .systemFont(ofSize: 20, weight: .bold)
        return label
    }()
    
    private let autoDownloadsUpdatesSwitch: UISwitch = .init()
    
    private let checkFeedButton: UIButton = {
        let btn: UIButton = .init(type: .system)
        btn.configuration = .filled()
        btn.setTitle("Check Feed for Update", for: .normal)
        return btn
    }()
    
    private let checkForUpdatesInBGButton: UIButton = {
        let btn: UIButton = .init(type: .system)
        btn.configuration = .filled()
        btn.setTitle("Check for Updates in Background ", for: .normal)
        return btn
    }()
    
    private let resetUpdateCycleButton: UIButton = {
        let btn: UIButton = .init(type: .system)
        btn.configuration = .filled()
        btn.setTitle("Reset Update Cycle", for: .normal)
        return btn
    }()
    
    private let resetUpdateCycleAfterDelayButton: UIButton = {
        let btn: UIButton = .init(type: .system)
        btn.configuration = .filled()
        btn.setTitle("Reset Update Cycle After Delay", for: .normal)
        return btn
    }()
    
    private let refreshUIButton: UIButton = {
        let btn: UIButton = .init(type: .system)
        btn.configuration = .filled()
        btn.setTitle("Refresh UI", for: .normal)
        return btn
    }()
    
    public var plugin: Plugin? = nil
    
    private var updateIsAvailable: Bool = false
    private var latestVersion: String = ""
    private var latestBuild: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        plugin?.addAppUpdateObserver(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        updateUI()
        
        plugin?.checkForFeedForUpdate()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    deinit {
        plugin?.removeAppUpdateObserver(self)
    }
    
    private func setupUI() {
        view.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(infoLabel)

        // Auto check
        autoCheckForUpdatesStackView.addArrangedSubview(autoCheckForUpdatesLabel)
        autoCheckForUpdatesSwitch.addTarget(self, action: #selector(autoCheckForUpdatesSwitchValueChanged(_:)), for: .valueChanged)
        autoCheckForUpdatesStackView.addArrangedSubview(autoCheckForUpdatesSwitch)
        stackView.addArrangedSubview(autoCheckForUpdatesStackView)
        
        // Auto download
        autoDownloadsUpdatesStackView.addArrangedSubview(autoDownloadsUpdatesLabel)
        autoDownloadsUpdatesSwitch.addTarget(self, action: #selector(autoDownloadsUpdatesSwitchValueChanged(_:)), for: .valueChanged)
        autoDownloadsUpdatesStackView.addArrangedSubview(autoDownloadsUpdatesSwitch)
        stackView.addArrangedSubview(autoDownloadsUpdatesStackView)
        
        // Refresh UI Button
        refreshUIButton.addTarget(self, action: #selector(refreshUI(_:)), for: .touchUpInside)
        stackView.addArrangedSubview(refreshUIButton)
        
        checkForUpdatesInBGButton.addTarget(self, action: #selector(checkForUpdatesInBackground(_:)), for: .touchUpInside)
        stackView.addArrangedSubview(checkForUpdatesInBGButton)
        
        checkFeedButton.addTarget(self, action: #selector(checkForFeedForUpdate(_:)), for: .touchUpInside)
        stackView.addArrangedSubview(checkFeedButton)
        
        resetUpdateCycleButton.addTarget(self, action: #selector(resetUpdateCycle(_:)), for: .touchUpInside)
        stackView.addArrangedSubview(resetUpdateCycleButton)
        
        resetUpdateCycleAfterDelayButton.addTarget(self, action: #selector(resetUpdateCycleAfterShortDelay(_:)), for: .touchUpInside)
        stackView.addArrangedSubview(resetUpdateCycleAfterDelayButton)
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.widthAnchor.constraint(equalToConstant: 500)
        ])
    }
    
    func updateUI() {
        guard let plugin else {
            infoLabel.text = "Plugin not found."
            autoCheckForUpdatesStackView.isHidden = true
            autoDownloadsUpdatesStackView.isHidden = true
            return
        }
        
        guard
            let installedVersion: String = Bundle.main.shortVersionString,
            let installedBuild: String = Bundle.main.version
        else { return }
        
        var lastCheckedString: String = "n/a"
        if let lastChecked: Date = plugin.getLastUpdateCheckDate() {
            lastCheckedString = dateFormatter.string(from: lastChecked)
        }
        
        // Print the Documents directory
        var applicationPath: String = ""
        if let applicationDirectory = FileManager.default.urls(for: .applicationDirectory, in: .userDomainMask).first {
            applicationPath = applicationDirectory.path
        }
        
        infoLabel.text = """
        App Dir: \(applicationPath)
        
        Installed: \(installedVersion)-\(installedBuild) <> Latest: \(latestVersion)-\(latestBuild)
        Update Available: \(updateIsAvailable)
        Last Check: \(lastCheckedString)
        Check Interval: \(plugin.getUpdateCheckInterval()) seconds
        
        Bundle:
            SUAllowsAutomaticUpdates: \(String(describing: Bundle.main.sparkleAllowsAutomaticUpdates))
            SUScheduledCheckInterval: \(String(describing: Bundle.main.sparkleScheduledCheckInterval))
        User Defaults:
            SUScheduledCheckInterval: \(String(describing: UserDefaults.standard.sparkleScheduledCheckInterval))
            SUEnableAutomaticChecks: \(String(describing: UserDefaults.standard.sparkleEnableAutomaticChecks))
            SUAutomaticallyUpdate: \(String(describing: UserDefaults.standard.sparkleAutomaticallyUpdates))
        """
        
        autoCheckForUpdatesStackView.isHidden = false
        autoDownloadsUpdatesStackView.isHidden = false
        
        autoCheckForUpdatesSwitch.isOn = plugin.getAutomaticallyCheckForUpdates()
        autoDownloadsUpdatesSwitch.isOn = plugin.getAutomaticallyDownloadsUpdates()
    }
    
    func updateIsAvailableDidChange(updateIsAvailable: Bool, latestVersion: String, latestBuild: String) {
        log.info("VC:updateIsAvailableDidChange...")

        self.updateIsAvailable = updateIsAvailable
        self.latestVersion = latestVersion
        self.latestBuild = latestBuild
        
        updateUI()
    }
    
    func updaterRequestedRelaunch(completion: RelaunchRequestHandler?) {
        log.info("VC:updaterRequestedRelaunch...")

        
        let alert: UIAlertController = .init(title: "Update Installed", message: "Would you like to restart the app?", preferredStyle: .alert)
        
        alert.addAction(.init(title: "Restart", style: .default, handler: { _ in
            completion?(true)
        }))
        alert.addAction(.init(title: "Cancel", style: .cancel, handler: { _ in
            completion?(false)
        }))
        
        present(alert, animated: true)
    }
    
    @objc func autoCheckForUpdatesSwitchValueChanged(_ switchView: UISwitch) {
        plugin?.setAutomaticallyCheckForUpdates(switchView.isOn)
        updateUI()
    }
    
    @objc func autoDownloadsUpdatesSwitchValueChanged(_ switchView: UISwitch) {
        plugin?.setAutomaticallyDownloadsUpdates(switchView.isOn)
        updateUI()
    }
    
    @objc func refreshUI(_ button: UIButton) {
        updateUI()
    }
    
    @objc func checkForFeedForUpdate(_ button: UIButton) {
        plugin?.checkForFeedForUpdate()
        updateUI()
    }
    
    @objc func checkForUpdatesInBackground(_ button: UIButton) {
        plugin?.checkForUpdatesInBackground()
        updateUI()
    }
    
    @objc func resetUpdateCycle(_ button: UIButton) {
        plugin?.resetUpdateCycle()
        updateUI()
    }
    
    @objc func resetUpdateCycleAfterShortDelay(_ button: UIButton) {
        plugin?.resetUpdateCycleAfterShortDelay()
        updateUI()
    }
    
}

extension UserDefaults {
    
    var sparkleScheduledCheckInterval: Any? {
        return object(forKey: "SUScheduledCheckInterval")
    }
    
    var sparkleEnableAutomaticChecks: Any? {
        return object(forKey: "SUEnableAutomaticChecks")
    }
    
    var sparkleAutomaticallyUpdates: Any? {
        return object(forKey: "SUAutomaticallyUpdate")
    }
    
}

extension Bundle {
    
    var sparkleScheduledCheckInterval: Any? {
        return infoDictionary?["SUScheduledCheckInterval"] as? Any
    }
    
    var sparkleAllowsAutomaticUpdates: Any? {
        return infoDictionary?["SUAllowsAutomaticUpdates"] as? Any
    }
    
    var sparkleAutomaticallyUpdates: Any? {
        return infoDictionary?["SUAutomaticallyUpdate"] as? Any
    }
    
    var shortVersionString: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    var version: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
    
}

