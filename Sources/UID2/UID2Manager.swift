//
//  OpenPassManager.swift
//  
//
//  Created by Brad Leege on 1/20/23.
//

import Combine
import Foundation

@available(iOS 13.0, *)
public final actor UID2Manager {
    
    /// Singleton access point for UID2Manager
    public static let shared = UID2Manager()
    
    /// Enable or Disable Automatic Refresh via RepeatingTimer
    public var automaticRefreshEnabled = true {
        didSet {
            if automaticRefreshEnabled {
                timer.resume()
            } else {
                timer.suspend()
            }
        }
    }
    
    // MARK: - Publishers
            
    /// Current Identity data for the user
    @Published public private(set) var identity: UID2Identity?
    
    /// Public Identity Status Notifications
    @Published public private(set) var identityStatus: IdentityStatus?
    
    // MARK: - Core Components

    /// UID2Client for Network API  requests
    private let uid2Client: UID2Client
    
    private let timer: RepeatingTimer
            
    /// Default UID2 Server URL
    /// Override default by setting `UID2ApiUrl` in app's Info.plist
    /// https://github.com/IABTechLab/uid2docs/tree/main/api/v2#environments
    private let defaultUid2ApiUrl = "https://prod.uidapi.com"
    
    /// Default Timer Refresh Period in Milliseconds
    /// Override default by setting `UID2RefreshRetryTime` in app's Info.plist
    private let defaultUid2RefreshRetry: Int = 5000
            
    private init() {
        
        // SDK Supplied Properties
        let properties = SDKPropertyLoader.load()
        
        // App Supplied Properites
        var apiUrl = defaultUid2ApiUrl
        if let apiUrlOverride = Bundle.main.object(forInfoDictionaryKey: "UID2ApiUrl") as? String, !apiUrlOverride.isEmpty {
            apiUrl = apiUrlOverride
        }
        uid2Client = UID2Client(uid2APIURL: apiUrl)

        var refreshTime = defaultUid2RefreshRetry
        if let refreshTimeOverride = Bundle.main.object(forInfoDictionaryKey: "UID2RefreshRetryTime") as? Int {
            refreshTime = refreshTimeOverride
        }
        self.timer = RepeatingTimer(retryTimeInMilliseconds: refreshTime)
        self.timer.eventHandler = {
            Task {
                guard let identity = KeychainManager.shared.getIdentityFromKeychain(),
                      let validated = await self.validateAndSetIdentity(identity: identity, status: nil, statusText: nil) else {
                    return
                }
                await self.triggerRefreshOrSetTimer(validIdentity: validated)
            }
        }

        // Try to load from Keychain if available
        // Use case for app manually stopped and re-opened
        Task {
            if let identity = KeychainManager.shared.getIdentityFromKeychain() {
                await setIdentity(identity)
            }
        }
    }
 
    // MARK: - Public Identity Lifecycle
    
    // iOS Way to Provid Initial Setup from Outside
    // Web Way --> https://github.com/IABTechLab/uid2-web-integrations/blob/5a8295c47697cdb1fe36997bc2eb2e39ae143f8b/src/uid2Sdk.ts#L153-L154
    public func setIdentity(_ identity: UID2Identity) async {
        if let validatedIdentity = await validateAndSetIdentity(identity: identity, status: nil, statusText: nil) {
            triggerRefreshOrSetTimer(validIdentity: validatedIdentity)
        }
    }

    public func resetIdentity() async {
        self.identity = nil
        self.identityStatus = nil
        KeychainManager.shared.deleteIdentityFromKeychain()
    }
    
    public func refreshIdentity() async {
        guard let identity = identity else {
            return
        }
        refreshToken(identity: identity)
    }
    
    public func getAdvertisingToken() -> String? {
        return self.identity?.advertisingToken
    }
    
    // MARK: - Internal Identity Lifecycle
    
    private func hasExpired(expiry: Int64, now: Int64 = Date().millisecondsSince1970) -> Bool {
        return expiry <= now
    }
    
    private func getIdentityPackage(identity: UID2Identity?) -> IdentityPackage {
        
        guard let identity = identity else {
            return IdentityPackage(valid: false, errorMessage: "Identity not available", identity: nil, status: .noIdentity)
        }
        
        if identity.advertisingToken.isEmpty {
            return IdentityPackage(valid: false, errorMessage: "advertising_token is not available or is not valid", identity: nil, status: .invalid)
        }
        
        if identity.refreshToken.isEmpty {
            return IdentityPackage(valid: false, errorMessage: "refresh_token is not available or is not valid", identity: nil, status: .invalid)
        }
        
        if hasExpired(expiry: identity.refreshExpires) {
            return IdentityPackage(valid: false, errorMessage: "Identity expired, refresh expired", identity: nil, status: .refreshExpired)
        }
        
        if hasExpired(expiry: identity.identityExpires) {
            return IdentityPackage(valid: true, errorMessage: "Identity expired, refresh still valid", identity: identity, status: .expired)
        }
     
        if self.identity == nil || self.identity?.advertisingToken == identity.advertisingToken {
            return IdentityPackage(valid: true, errorMessage: "Identity established", identity: identity, status: .established)
        }
        
        return IdentityPackage(valid: true, errorMessage: "Identity refreshed", identity: identity, status: .refreshed)
    }
    
    @discardableResult
    private func validateAndSetIdentity(identity: UID2Identity?, status: IdentityStatus?, statusText: String?) async -> UID2Identity? {

        // Process Opt Out
        if let status = status, status == .optOut {
            self.identity = nil
            KeychainManager.shared.deleteIdentityFromKeychain()
            self.identityStatus = .optOut
            return nil
        }
        
        // Process Remaining IdentityStatus Options
        let validity = getIdentityPackage(identity: identity)

        // Notify Subscribers
        self.identityStatus = validity.status
        
        guard let validIdentity = validity.identity else {
            return nil
        }
        
        if validIdentity.advertisingToken == self.identity?.advertisingToken {
            return validIdentity
        }
        
        self.identity = validIdentity
        KeychainManager.shared.saveIdentityToKeychain(validIdentity)
        
        return validIdentity
    }

    // MARK: - Refresh and Timer
    
    private func refreshToken(identity: UID2Identity) {
        
        Task {
            do {
                let apiResponse = try await uid2Client.refreshIdentity(refreshToken: identity.refreshToken,
                                                                       refreshResponseKey: identity.refreshResponseKey)
                await self.validateAndSetIdentity(identity: apiResponse.identity, status: apiResponse.status, statusText: apiResponse.message)
            } catch {
                // No Op
                // Retry will automatically occur due to timer
            }
        }

    }
        
    private func triggerRefreshOrSetTimer(validIdentity: UID2Identity) {
        
        if hasExpired(expiry: validIdentity.refreshFrom) {
            self.refreshToken(identity: validIdentity)
        } else {
            if automaticRefreshEnabled {
                timer.resume()
            }
        }

    }

}
