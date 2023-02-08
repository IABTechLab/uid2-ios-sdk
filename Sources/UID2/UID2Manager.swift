//
//  OpenPassManager.swift
//  
//
//  Created by Brad Leege on 1/20/23.
//

import Combine
import Foundation

@available(iOS 13.0, *)
@MainActor
public final class UID2Manager {
    
    /// Singleton access point for UID2Manager
    public static let shared = UID2Manager()
    
    /// Publishers
    
    /// Current IdentityPackage Data
    @Published public private(set) var identityPackage: IdentityPackage?
            
    /// UID2Client for Network API  requests
    private let uid2Client: UID2Client
            
    /// Default UID2 Server URL
    /// Override default by setting `UID2ApiUrl` in app's Info.plist
    /// https://github.com/IABTechLab/uid2docs/tree/main/api/v2#environments
    private let defaultUid2ApiUrl = "https://prod.uidapi.com"
    
    private let timer = RepeatingTimer(timeInterval: 3)
    
    private init() {
        var apiUrl = defaultUid2ApiUrl
        if let apiUrlOverride = Bundle.main.object(forInfoDictionaryKey: "UID2ApiUrl") as? String, !apiUrlOverride.isEmpty {
            apiUrl = apiUrlOverride
        }
        uid2Client = UID2Client(uid2APIURL: apiUrl)
        
        timer.eventHandler = {
            print("Timer Fired at \(Date())")
            self.refreshIdentityPackage()
        }

        // Try to load from Keychain if available
        // Use case for app manually stopped and re-opened
//        reloadUID2Token()
    }
 
    public func setIdentityPackage(_ identityPackage: IdentityPackage) {
        // Is Token valid check?
        // If false, then refresh automatically or just throw error?

        self.identityPackage = identityPackage
        KeychainManager.shared.saveIdentityPackageToKeychain(identityPackage)
        
        // Start Refresh Countdown
        timer.suspend()
        timer.resume()
    }
    
    @discardableResult
    public func reloadIdentityPackage() -> Bool {
        if identityPackage != nil {
            return false
        }
        
        guard let identityPackage = KeychainManager.shared.getIdentityPackageFromKeychain() else {
            return false
        }
        setIdentityPackage(identityPackage)
        return true
    }
    
    public func resetIdentityPackage() {
        self.identityPackage = nil
        KeychainManager.shared.deleteIdentityPackageFromKeychain()
        timer.suspend()
    }
    
//    public func getUID2Token() throws -> UID2Token? {
//
//        // If null, then look in Keychain
//        if uid2Token == nil {
//            if let token = KeychainManager.shared.getUID2TokenFromKeychain() {
//                self.uid2Token = token
//            }
//            return nil
//        }
//
//        // Check for opt out
//        if uid2Token?.status == UID2Token.Status.optOut {
//            throw UID2Error.userHasOptedOut
//        }
//
//        // Check for Expired Token
//        if isTokenExpired() {
//            throw UID2Error.tokenIsExpired
//        }
//
//        let isTokenInRefreshRange = isTokenInRefreshRange()
//
//        if isTokenInRefreshRange {
//            // Fire non blocking background task to refresh
//            Task(priority: .medium, operation: {
//                refreshToken()
//            })
//        }
//
//        return uid2Token
//    }
    
    internal func isIdentityPackageInRefreshRange() -> Bool {
        guard let identityPackage = identityPackage,
              let refreshTokenFrom = identityPackage.refreshFrom else {
            return false
        }

        let now = Date().timeIntervalSince1970
        return now >= refreshTokenFrom && !identityPackage.isTokenExpired()
    }
    
    internal func refreshIdentityPackage() {

        guard let identityPackage = identityPackage,
              let refreshToken = identityPackage.refreshToken,
              let refreshResponseKey = identityPackage.refreshResponseKey else {
            return
        }
        
        // See details on refresh logic in Slack
        //  https://thetradedesk.slack.com/archives/G01SS5EQE91/p1675360339678219

        Task {
            guard let newIdentityPackage = try? await uid2Client.refreshIdentityPackage(refreshToken: refreshToken,
                                                                                        refreshResponseKey: refreshResponseKey) else {
                return
            }
            setIdentityPackage(newIdentityPackage)
        }
        
    }
}
