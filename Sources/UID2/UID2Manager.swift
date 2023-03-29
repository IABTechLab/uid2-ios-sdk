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
    @Published public private(set) var identityStatus: IdentityStatus = .noIdentity
    
    // MARK: - Core Components

    /// UID2 SDK Version
    public let sdkVersion: (major: Int, minor: Int, patch: Int)
    
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
        self.sdkVersion = UID2SDKProperties.getUID2SDKVersion()
        
        // App Supplied Properites
        var apiUrl = defaultUid2ApiUrl
        if let apiUrlOverride = Bundle.main.object(forInfoDictionaryKey: "UID2ApiUrl") as? String, !apiUrlOverride.isEmpty {
            apiUrl = apiUrlOverride
        }
        var clientVersion = "\(sdkVersion.major).\(sdkVersion.minor).\(sdkVersion.patch)"
        if self.sdkVersion == (major: 0, minor: 0, patch: 0) {
            clientVersion = "unknown"
        }
        
        uid2Client = UID2Client(uid2APIURL: apiUrl, sdkVersion: clientVersion)

        var refreshTime = defaultUid2RefreshRetry
        if let refreshTimeOverride = Bundle.main.object(forInfoDictionaryKey: "UID2RefreshRetryTime") as? Int {
            refreshTime = refreshTimeOverride
        }
        self.timer = RepeatingTimer(retryTimeInMilliseconds: refreshTime)
        self.timer.eventHandler = {
            Task {
                guard let identity = await self.identity,
                      let validated = await self.validateAndSetIdentity(identity: identity, status: nil, statusText: nil) else {
                    return
                }
                await self.triggerRefreshOrSetTimer(validIdentity: validated)
            }
        }
        
        // Try to load from Keychain if available
        // Use case for app manually stopped and re-opened
        Task {
            await loadStateFromDisk()
        }
    }
    
    // MARK: - Public Identity Lifecycle
    
    // iOS Way to Provide Initial Setup from Outside
    // Web Way --> https://github.com/IABTechLab/uid2-web-integrations/blob/5a8295c47697cdb1fe36997bc2eb2e39ae143f8b/src/uid2Sdk.ts#L153-L154
    
    /// Set UID2 Identity for UID2Manager to manage
    /// - Parameter identity: UID2 Identity for UID2Manager to manage
    public func setIdentity(_ identity: UID2Identity) async {
        if let validatedIdentity = await validateAndSetIdentity(identity: identity, status: nil, statusText: nil) {
            await triggerRefreshOrSetTimer(validIdentity: validatedIdentity)
        }
    }
    
    /// Reset UID2 Identity state in UID2Manager
    public func resetIdentity() async {
        self.identity = nil
        self.identityStatus = .noIdentity
        KeychainManager.shared.deleteIdentityFromKeychain()
    }
    
    /// Manually Refresh UID2 Identity
    public func refreshIdentity() async {
        guard let identity = identity else {
            return
        }
        await refreshToken(identity: identity)
    }
    
    /// Get Advertising Token if Valid
    /// - Returns: Adversting Token if valid, nil if not valid
    public func getAdvertisingToken() async -> String? {
        
        guard let identity = self.identity else {
            self.identityStatus = .noIdentity
            return nil
        }

        let identityPackage = await getIdentityPackage(identity: identity)
        
        self.identityStatus = identityPackage.status
        
        if identityPackage.status == .established || identityPackage.status == .refreshed {
            return identity.advertisingToken
        }
        
        return nil
    }

    /// Actor Safe way to toggle automaticRefreshEnabled property
    /// - Parameter enable: True to enable, False to disable
    public func setAutomaticRefreshEnabled(_ enable: Bool) {
        self.automaticRefreshEnabled = enable
    }
    
    // MARK: - Internal Identity Lifecycle
    
    private func setIdentityPackage(_ identity: IdentityPackage) async {
        if let validatedIdentity = await validateAndSetIdentity(identity: identity.identity,
                                                                status: identity.status,
                                                                statusText: identity.errorMessage) {
            await triggerRefreshOrSetTimer(validIdentity: validatedIdentity)
        }
    }
    
    private func loadStateFromDisk() async {
        if let identity = KeychainManager.shared.getIdentityFromKeychain() {
            // Has Opted Out?
            //  - Handled by setIdentityPackage() validateAndSetIdentity()
            // Has Identity Token Expired with valid RefreshToken?
            //  - Handled by setIdentityPackage() triggerRefreshOrSetTimer()
            await setIdentityPackage(identity)
        }
    }
    
    private func hasExpired(expiry: Int64, now: Int64 = Date().millisecondsSince1970) async -> Bool {
        return expiry <= now
    }
    
    private func getIdentityPackage(identity: UID2Identity?) async -> IdentityPackage {
                
        guard let identity = identity else {
            return IdentityPackage(valid: false, errorMessage: "Identity not available", identity: nil, status: .noIdentity)
        }
        
        if identity.advertisingToken.isEmpty {
            return IdentityPackage(valid: false, errorMessage: "advertising_token is not available or is not valid", identity: nil, status: .invalid)
        }
        
        if identity.refreshToken.isEmpty {
            return IdentityPackage(valid: false, errorMessage: "refresh_token is not available or is not valid", identity: nil, status: .invalid)
        }
        
        if await hasExpired(expiry: identity.refreshExpires) {
            return IdentityPackage(valid: false, errorMessage: "Identity expired, refresh expired", identity: nil, status: .refreshExpired)
        }
        
        if await hasExpired(expiry: identity.identityExpires) {
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
            self.identityStatus = .optOut
            let identityPackageOptOut = IdentityPackage(valid: false, errorMessage: "User Opted Out", identity: nil, status: .optOut)
            KeychainManager.shared.deleteIdentityFromKeychain()
            KeychainManager.shared.saveIdentityToKeychain(identityPackageOptOut)
            return nil
        }
        
        if let status = status, status == .established {
            self.identity = identity
            self.identityStatus = .established
            // Not needed for loadFromDisk, but is needed for initial setting of Identity
            let identityPackage = IdentityPackage(valid: true, errorMessage: statusText, identity: identity, status: .established)
            KeychainManager.shared.saveIdentityToKeychain(identityPackage)
            return identity
        }
        
        // Process Remaining IdentityStatus Options
        let validatedIdentityPackage = await getIdentityPackage(identity: identity)

        // Notify Subscribers
        self.identityStatus = validatedIdentityPackage.status
        
        guard let validIdentity = validatedIdentityPackage.identity else {
            return nil
        }
        
        if validIdentity.advertisingToken == self.identity?.advertisingToken {
            return validIdentity
        }
        
        self.identity = validIdentity
        KeychainManager.shared.saveIdentityToKeychain(validatedIdentityPackage)
        
        return validIdentity
    }

    // MARK: - Refresh and Timer
    
    private func refreshToken(identity: UID2Identity) async {
        
        do {
            let apiResponse = try await uid2Client.refreshIdentity(refreshToken: identity.refreshToken,
                                                                   refreshResponseKey: identity.refreshResponseKey)
            await self.validateAndSetIdentity(identity: apiResponse.identity, status: apiResponse.status, statusText: apiResponse.message)
        } catch {
            // No Op
            // Retry will automatically occur due to timer
        }

    }
        
    private func triggerRefreshOrSetTimer(validIdentity: UID2Identity) async {
        
        if await hasExpired(expiry: validIdentity.refreshFrom) {
            await self.refreshToken(identity: validIdentity)
        } else {
            if automaticRefreshEnabled {
                timer.resume()
            }
        }

    }

}
