//
//  Sparkle+Extensions.swift
//  AppKitPlugin
//
//  Created by Andrew McLean on 8/23/24.
//

import Foundation
import Sparkle

extension SUAppcastItem {

    var versionFull: String { return  "\(displayVersionString)-\(versionString)" }
    
    override open var description: String {
        return "SUAppcastItem(versionString: \(versionString), isCriticalUpdate: \(isCriticalUpdate),  contentLength: \(contentLength), attributeKeys: \(attributeKeys), propertiesDictionary: \(propertiesDictionary))"
    }
    
}

extension SPUUserUpdateChoice : CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .skip: return "skip"
        case .install: return "install"
        case .dismiss: return "dismiss"
        @unknown default: return "unknown"
        }
    }
    
}

extension SPUUserUpdateState {
    
    override open var description: String {
        return "SPUUserUpdateState(userInitiated: \(userInitiated), stage: \(stage))"
    }
    
}

extension SPUUserUpdateStage : CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .notDownloaded: return "notDownloaded"
        case .downloaded: return "downloaded"
        case .installing: return "installing"
        @unknown default: return "unknown"
        }
    }
    
}

extension SPUUpdateCheck : CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .updates: return "updates"
        case .updatesInBackground: return "updatesInBackground"
        case .updateInformation: return "updateInformation"
        @unknown default: return "unknown"
        }
    }
    
}

