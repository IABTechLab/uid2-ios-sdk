//
//  OpenPassManager.swift
//  
//
//  Created by Brad Leege on 1/20/23.
//

import Combine
import Foundation
import OSLog

public final actor UID2Manager {
    
    /// Singleton access point for UID2Manager
    public static let shared = UID2Manager()
    
    /// Enable or Disable Automatic Refresh via RepeatingTimer
    public var automaticRefreshEnabled = true {
        didSet {
            Task {
                await checkIdentityExpiration()
                await checkIdentityRefresh()
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
    
    private let keychainManager = KeychainManager()

    /// Background Task for Refreshing UID2 Identity
    private var refreshJob: Task<(), Error>?

    /// Background Task for Checking On UID2 Identity Refresh Token Expiration
    private var checkRefreshExpiresJob: Task<(), Error>?

    /// Background Task for Checking On UID2 Identity Expiration
    private var checkIdentityExpiresJob: Task<(), Error>?

    /// Logger
    private let log: OSLog

    // MARK: - Defaults
    
    /// Default UID2 Server URL
    /// Override default by setting `UID2ApiUrl` in app's Info.plist
    /// https://github.com/IABTechLab/uid2docs/tree/main/api/v2#environments
    private let defaultUid2ApiUrl = "https://prod.uidapi.com"
    
    private init() {
        // App Supplied Properites
        let environment: Environment
        if let apiUrlOverride = Bundle.main.object(forInfoDictionaryKey: "UID2ApiUrl") as? String, 
            !apiUrlOverride.isEmpty,
            let apiUrl = URL(string: apiUrlOverride) {
            environment = Environment(endpoint: apiUrl)
        } else {
            environment = UID2Settings.shared.environment
        }

        sdkVersion = UID2SDKProperties.getUID2SDKVersion()
        let clientVersion = "\(sdkVersion.major).\(sdkVersion.minor).\(sdkVersion.patch)"

        let isLoggingEnabled = UID2Settings.shared.isLoggingEnabled
        self.log = isLoggingEnabled
            ? .init(subsystem: "com.uid2", category: "UID2Manager")
            : .disabled
        uid2Client = UID2Client(
            sdkVersion: clientVersion,
            isLoggingEnabled: isLoggingEnabled,
            environment: environment
        )

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
        os_log("Setting external identity", log: log, type: .debug)
        if let _ = await validateAndSetIdentity(identity: identity, status: nil, statusText: nil) {
            await checkIdentityExpiration()
            await checkIdentityRefresh()
        }
    }
    
    /// Reset UID2 Identity state in UID2Manager
    public func resetIdentity() async {
        os_log("Resetting identity", log: log, type: .debug)
        self.identity = nil
        self.identityStatus = .noIdentity
        await keychainManager.deleteIdentityFromKeychain()
        await checkIdentityExpiration()
        await checkIdentityRefresh()
    }
    
    /// Manually Refresh UID2 Identity
    public func refreshIdentity() async {
        os_log("Refreshing identity", log: log, type: .debug)
        guard let identity = identity else {
            return
        }
        await refreshToken(identity: identity)
        await checkIdentityRefresh()
    }
    
    /// Get Advertising Token if Valid
    /// - Returns: Adversting Token if valid, nil if not valid
    public func getAdvertisingToken() -> String? {
        
        if identityStatus == .established || identityStatus == .refreshed {
            return identity?.advertisingToken
        }
        
        return nil
    }

    /// Actor Safe way to toggle automaticRefreshEnabled property
    /// - Parameter enable: True to enable, False to disable
    public func setAutomaticRefreshEnabled(_ enable: Bool) {
        self.automaticRefreshEnabled = enable
    }

    /// Generates a new identity.
    ///
    /// Once set, assuming it's valid, it will be monitored so that we automatically refresh the token(s) when required.
    /// This will also be persisted locally, so that when the application re-launches, we reload this Identity.
    /// - Parameters:
    ///   - identity: The DII or hash to create an identity token from
    ///   - subscriptionID: The subscription id that was obtained when configuring your account.
    ///   - serverPublicKey: The public key that was obtained when configuring your account.
    ///   - appName: The app's identifier. If `nil`, defaults to `Bundle.main.bundleIdentifier` which is appropriate in most cases.
    public func generateIdentity(
        _ identity: IdentityType,
        subscriptionID: String,
        serverPublicKey: String,
        appName: String? = nil
    ) async throws {
        assert((appName ?? Bundle.main.bundleIdentifier) != nil, "An appName must be provided or a main bundleIdentifier set")
        guard let appName = appName ?? Bundle.main.bundleIdentifier else {
            throw TokenGenerationError.configuration(message: "An appName must be provided or a main bundleIdentifier set")
        }
        let apiResponse = try await uid2Client.generateIdentity(
            identity,
            subscriptionID: subscriptionID,
            serverPublicKey: serverPublicKey,
            appName: appName
        )
        refreshJob?.cancel()
        refreshJob = nil

        await self.validateAndSetIdentity(identity: apiResponse.identity, status: apiResponse.status, statusText: apiResponse.message)
    }

    // MARK: - Internal Identity Lifecycle
    
    private func setIdentityPackage(_ identity: IdentityPackage) async {
        if let _ = await validateAndSetIdentity(identity: identity.identity,
                                                status: identity.status,
                                                statusText: identity.errorMessage) {
            
            // An identity's status can change based upon the current time and it's expiration. We will schedule some work
            // to detect when it changes so that we can report it accordingly.
            await checkIdentityExpiration()

            // After a new identity has been set, we have to work out how we're going to potentially refresh it. If the
            // identity is null, because it's been reset of the identity has opted out, we don't need to do anything.
            await checkIdentityRefresh()
        }
    }
    
    private func loadStateFromDisk() async {
        if let identity = await keychainManager.getIdentityFromKeychain() {
            // Has Opted Out?
            //  - Handled by setIdentityPackage() validateAndSetIdentity()
            // Has Identity Token Expired with valid RefreshToken?
            //  - Handled by setIdentityPackage() triggerRefreshOrSetTimer()
            os_log("Restoring previously persisted identity", log: log, type: .debug)
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
     
        if self.identity == nil || self.identity?.advertisingToken == identity.advertisingToken && self.identityStatus != .refreshed {
            return IdentityPackage(valid: true, errorMessage: "Identity established", identity: identity, status: .established)
        }
        
        return IdentityPackage(valid: true, errorMessage: "Identity refreshed", identity: identity, status: .refreshed)
    }
    
    @discardableResult
    private func validateAndSetIdentity(identity: UID2Identity?, status: IdentityStatus?, statusText: String?) async -> UID2Identity? {

        // Process Opt Out
        if let status = status, status == .optOut {
            os_log("User opt-out detected", log: log, type: .debug)
            self.identity = nil
            self.identityStatus = .optOut
            let identityPackageOptOut = IdentityPackage(valid: false, errorMessage: "User Opted Out", identity: nil, status: .optOut)
            await keychainManager.deleteIdentityFromKeychain()
            await keychainManager.saveIdentityToKeychain(identityPackageOptOut)
            return nil
        }

        if let status = status, status == .established {
            self.identity = identity
            self.identityStatus = status
            // Not needed for loadFromDisk, but is needed for initial setting of Identity
            let identityPackage = IdentityPackage(valid: true, errorMessage: statusText, identity: identity, status: .established)
            os_log("Updating storage (Status: %@)", log: log, status.debugDescription)
            await keychainManager.saveIdentityToKeychain(identityPackage)
            return identity
        }
        
        // Process Remaining IdentityStatus Options
        let validatedIdentityPackage = await getIdentityPackage(identity: identity)

        os_log("Updating identity (Identity: %@, Status: %@)", log: log,
               validatedIdentityPackage.identity != nil ? "true" : "false",
               validatedIdentityPackage.status.debugDescription
        )

        // Notify Subscribers
        self.identityStatus = validatedIdentityPackage.status
        
        guard let validIdentity = validatedIdentityPackage.identity else {
            return nil
        }
        
        if validIdentity.advertisingToken == self.identity?.advertisingToken {
            return validIdentity
        }

        os_log("Updating storage (Status: %@)", log: log, validatedIdentityPackage.status.debugDescription)
        self.identity = validIdentity
        await keychainManager.saveIdentityToKeychain(validatedIdentityPackage)

        await checkIdentityRefresh()
        await checkIdentityExpiration()
        
        return validIdentity
    }

    // MARK: - Refresh and Timer
    
    private func checkIdentityRefresh() async {
        refreshJob?.cancel()
        refreshJob = nil

        if !automaticRefreshEnabled {
            return
        }
        
        if let identity = identity {
            // If the identity is already suitable for a refresh, we can do so immediately. Otherwise, we will work out
            // how long it is until a refresh is required and schedule it accordingly.
            if await hasExpired(expiry: identity.refreshFrom) {
                refreshJob = Task {
                    await refreshToken(identity: identity)
                }
            } else {
                refreshJob = Task {
                    let delayInNanoseconds = await calculateDelay(futureCompletionTime: identity.refreshFrom)
                    try await Task.sleep(nanoseconds: delayInNanoseconds)
                    await refreshToken(identity: identity)
                }
            }
        }
    }
    
    /// The identity status can change as we reach specific time events. We want to observe these and make sure that when
    /// they are reached, we can report them accordingly to our consumer.
    private func checkIdentityExpiration() async {
        checkRefreshExpiresJob?.cancel()
        checkRefreshExpiresJob = nil
        
        checkIdentityExpiresJob?.cancel()
        checkIdentityExpiresJob = nil
                
        if let identity = identity {
            
            // If the expiration time of being able to refresh is in the future, we will schedule a job to detect if we
            // pass it. This will allow us to reevaluate our state and update accordingly.
            if await !hasExpired(expiry: identity.refreshExpires) {
                checkRefreshExpiresJob = Task {
                    let delayInNanoseconds = await calculateDelay(futureCompletionTime: identity.refreshExpires)
                    try await Task.sleep(nanoseconds: delayInNanoseconds)
                    os_log("Detected refresh has expired", log: log, type: .debug)
                    await validateAndSetIdentity(identity: identity, status: nil, statusText: nil)
                }
            }
            
            if await !hasExpired(expiry: identity.identityExpires) {
                checkIdentityExpiresJob = Task {
                    let delayInNanoseconds = await calculateDelay(futureCompletionTime: identity.identityExpires)
                    try await Task.sleep(nanoseconds: delayInNanoseconds)
                    os_log("Detected identity has expired", log: log, type: .debug)
                    await validateAndSetIdentity(identity: identity, status: nil, statusText: nil)
                }
            }
            
        }
    }
    
    /// Calculate the delay that Identity Checks use
    /// - Parameter futureCompletionTime: The time in milliseconds to end the
    /// - Returns: Delay in nanonseconds (UInt64) or 0 if futureCompletionTime is less than now
    private func calculateDelay(futureCompletionTime: Int64) async -> UInt64 {
        let now = Date().millisecondsSince1970
        if futureCompletionTime < now {
            return UInt64(0)
        }
        
        let diffToNow = futureCompletionTime - now
        let delayInNanoseconds = UInt64(diffToNow * 1000000)
        return delayInNanoseconds
    }
    
    /// Calls Refresh API to refresh the UID2 Identity
    /// - Parameter identity: Current Identity containing Refresh Token and Refresh Response Key
    private func refreshToken(identity: UID2Identity) async {
        os_log("Refreshing (Attempt: 1/1)", log: log, type: .debug)
        do {
            let apiResponse = try await uid2Client.refreshIdentity(refreshToken: identity.refreshToken,
                                                                   refreshResponseKey: identity.refreshResponseKey)
            os_log("Successfully refreshed identity", log: log, type: .debug)
            await self.validateAndSetIdentity(identity: apiResponse.identity, status: apiResponse.status, statusText: apiResponse.message)
        } catch {
            let nsError = error as NSError
            if !(nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled) {
                os_log("Error when trying to refresh identity", log: log, type: .error)
            }
            // No Op
            // Retry will automatically occur due to timer
        }

    }

}
