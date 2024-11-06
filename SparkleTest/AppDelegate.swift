//
//  AppDelegate.swift
//  SparkleTest
//
//  Created by Andrew McLean on 5/23/24.
//



import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var plugin: Plugin!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        plugin = loadPlugin()
        #if DEBUG
        print("DEBUG MODE Enabled")
        #endif
        plugin.startUpdater()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}

}

extension AppDelegate {
    
    private func loadPlugin() -> Plugin? {
        /// 1. Form the plugin's bundle URL
        let bundleFileName = "AppKitPlugin.bundle"
        guard let bundleURL = Bundle.main.builtInPlugInsURL?
            .appendingPathComponent(bundleFileName) else {
            return nil
        }

        /// 2. Create a bundle instance with the plugin URL
        guard let bundle = Bundle(url: bundleURL) else {
            return nil
        }

        /// 3. Load the bundle and our plugin class
        let className = "AppKitPlugin.AppKitPlugin"
        guard let pluginClass = bundle.classNamed(className) as? Plugin.Type else {
            return nil
        }

        /// 4. Create an instance of the plugin class
        return pluginClass.init()
    }
    
}

extension AppDelegate {
    
    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)
        
        // Ensure that the builder is modifying the menu bar system.
        guard builder.system == UIMenuSystem.main else { return }
        
        let checkForUpdatesAction = UIAction(title: "Check for Updates...") { [weak self] action in
            self?.plugin.checkForUpdates(action)
        }
        
        let menu = UIMenu(title: "", options: .displayInline, children: [checkForUpdatesAction])
        builder.insertSibling(menu, afterMenu: .about)
    }
    
}
