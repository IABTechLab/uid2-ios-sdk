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
    
    /// Current UID2 Token Data
    @Published public private(set) var uid2Token: UID2Token?
        
    /// UID2Client for Network API  requests
    private let uid2Client: UID2Client
            
    /// Default UID2 Server URL
    /// Override default by setting `UID2ApiUrl` in app's Info.plist
    /// https://github.com/IABTechLab/uid2docs/tree/main/api/v2#environments
    private let defaultUid2ApiUrl = "https://prod.uidapi.com"
    
    private init() {
        var apiUrl = defaultUid2ApiUrl
        if let apiUrlOverride = Bundle.main.object(forInfoDictionaryKey: "UID2ApiUrl") as? String, !apiUrlOverride.isEmpty {
            apiUrl = apiUrlOverride
        }
        uid2Client = UID2Client(uid2APIURL: apiUrl)
    }
 
    public func setUID2Token(_ uid2Token: UID2Token) {
        self.uid2Token = uid2Token
        KeychainManager.shared.saveUID2TokenToKeychain(uid2Token)
    }
    
    public func getUID2Token() throws -> UID2Token? {
        
        // If null, then look in Keychain
        if uid2Token == nil {
            if let token = KeychainManager.shared.getUID2TokenFromKeychain() {
                self.uid2Token = token
            }
            return nil
        }
        
        // Check for opt out
        if uid2Token?.status == UID2Token.Status.optOut {
            throw UID2Error.userHasOptedOut
        }

        // Check for Expired Token
        if isTokenExpired() {
            throw UID2Error.tokenIsExpired
        }
                
        let isTokenInRefreshRange = isTokenInRefreshRange()
        
        if isTokenInRefreshRange {
            // Fire non blocking background task to refresh
            Task(priority: .medium, operation: {
                await refreshToken()
            })
        }

        return uid2Token
    }
    
    internal func isTokenExpired() -> Bool {
        guard let uid2Token = uid2Token,
              let refreshTokenExpires = uid2Token.refreshExpires else {
            return false
        }

        let now = Date().timeIntervalSince1970
        return now > refreshTokenExpires
    }

    internal func isTokenInRefreshRange() -> Bool {
        guard let uid2Token = uid2Token,
              let refreshTokenFrom = uid2Token.refreshFrom else {
            return false
        }

        let now = Date().timeIntervalSince1970
        return now >= refreshTokenFrom && !isTokenExpired()
    }
    
    internal func refreshToken() async {

        guard let uid2Token = uid2Token,
              let refreshToken = uid2Token.refreshToken,
              let refreshResponseKey = uid2Token.refreshResponseKey else {
            return
        }
        
        // See details on refresh logic in Slack
        //  https://thetradedesk.slack.com/archives/G01SS5EQE91/p1675360339678219

        if isTokenInRefreshRange() {
            guard let newUid2Token = try? await uid2Client.refreshUID2Token(refreshToken: refreshToken, refreshResponseKey: refreshResponseKey) else {
                return
            }
            setUID2Token(newUid2Token)
        }
        
    }
}
