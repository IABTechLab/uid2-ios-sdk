//
//  OpenPassManager.swift
//  
//
//  Created by Brad Leege on 1/20/23.
//

import Combine
import Foundation
import OSLog

// swiftlint:disable:next type_body_length
public final actor UID2Manager {
    private enum InitializationState {
        case pending
        case complete
    }

    public typealias OnInitialized = @Sendable () async -> Void
    private var initializationListeners: [OnInitialized] = []
    private var initializationState = InitializationState.pending

    public func addInitializationListener(_ listener: @escaping OnInitialized) {
        guard initializationState != .complete else {
            Task {
                await listener()
            }
            return
        }

        initializationListeners.append(listener)
    }

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

    private let broadcaster = Broadcaster<State?>()
    private let queue = Queue()

    /// Source of truth for both `identity` and `identityStatus` values.
    public private(set) var state: State? {
        didSet {
            if let state {
                identity = state.identity
                identityStatus = state.identityStatus
            } else {
                identity = nil
                identityStatus = .noIdentity
            }

            // Capture the current value in the queue operation
            queue.enqueue { [state] in
                await self.broadcaster.send(state)
            }
        }
    }

    public func stateValues() async -> AsyncStream<State?> {
        await broadcaster.values()
    }

    /// Current Identity data for the user. Derived from `state.identity`.
    @Published public private(set) var identity: UID2Identity?

    /// Public Identity Status Notifications. Derived from `state.identityStatus`.
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

    private let dateGenerator: DateGenerator

    // MARK: - Defaults
    
    internal init() {
        // App Supplied Properties
        let environment: Environment
        if let apiUrlOverride = Bundle.main.object(forInfoDictionaryKey: "UID2ApiUrl") as? String, 
            !apiUrlOverride.isEmpty,
            let apiUrl = URL(string: apiUrlOverride) {
            environment = Environment(endpoint: apiUrl)
        } else {
            environment = UID2Settings.shared.environment
        }

        let sdkVersion = UID2SDKProperties.getUID2SDKVersion()
        let clientVersion = "\(sdkVersion.major).\(sdkVersion.minor).\(sdkVersion.patch)"

        let isLoggingEnabled = UID2Settings.shared.isLoggingEnabled
        let log = isLoggingEnabled
            ? OSLog(subsystem: "com.uid2", category: "UID2Manager")
            : .disabled

        self.init(
            uid2Client: UID2Client(
                sdkVersion: clientVersion,
                isLoggingEnabled: isLoggingEnabled,
                environment: environment
            ),
            sdkVersion: sdkVersion,
            log: log
        )
    }

    internal init(
        uid2Client: UID2Client,
        sdkVersion: (major: Int, minor: Int, patch: Int),
        log: OSLog,
        dateGenerator: DateGenerator = .init { Date() }
    ) {
        self.uid2Client = uid2Client
        self.sdkVersion = sdkVersion
        self.log = log
        self.dateGenerator = dateGenerator

        // Try to load from Keychain if available
        // Use case for app manually stopped and re-opened
        Task {
            await loadStateFromDisk()
            await notifyInitializationListeners()
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
        self.state = nil
        await keychainManager.deleteIdentityFromKeychain()
        await checkIdentityExpiration()
        await checkIdentityRefresh()
    }
    
    /// Manually Refresh UID2 Identity
    public func refreshIdentity() async {
        os_log("Refreshing identity", log: log, type: .debug)
        guard let identity = state?.identity else {
            return
        }
        await refreshToken(identity: identity)
        await checkIdentityRefresh()
    }
    
    /// Get Advertising Token if Valid
    /// - Returns: Adversting Token if valid, nil if not valid
    public func getAdvertisingToken() -> String? {
        switch state {
        case .established(let identity),
             .refreshed(let identity):
            return identity.advertisingToken
        case .none,
             .optout,
             .expired,
             .refreshExpired,
             .invalid:
            return nil
        }
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

    private func loadStateFromDisk() async {
        guard let identity = await keychainManager.getIdentityFromKeychain() else {
            return
        }
        os_log("Restoring previously persisted identity", log: log, type: .debug)

        // Existing token optout and expiry are handled by validateAndSetIdentity()
        await validateAndSetIdentity(
            identity: identity.identity,
            status: identity.status,
            statusText: identity.errorMessage
        )
    }
    
    private func notifyInitializationListeners() async {
        await withTaskGroup(of: Void.self) { taskGroup in
            initializationListeners.forEach { listener in
                taskGroup.addTask {
                    await listener()
                }
            }
        }
        initializationState = .complete
        initializationListeners = []
    }

    private func hasExpired(expiry: Int64) -> Bool {
        return expiry <= dateGenerator.now.millisecondsSince1970
    }
    
    private func getIdentityPackage(identity: UID2Identity?, newIdentity: Bool) -> IdentityPackage {

        guard let identity else {
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
     
        if newIdentity {
            return IdentityPackage(valid: true, errorMessage: "Identity established", identity: identity, status: .established)
        }
        
        return IdentityPackage(valid: true, errorMessage: "Identity refreshed", identity: identity, status: .refreshed)
    }
    
    @discardableResult
    private func validateAndSetIdentity(identity: UID2Identity?, status: IdentityStatus?, statusText: String?) async -> UID2Identity? {

        // Process Opt Out
        if status == .optOut {
            os_log("User opt-out detected", log: log, type: .debug)
            self.state = .optout
            let identityPackageOptOut = IdentityPackage(valid: false, errorMessage: "User Opted Out", identity: nil, status: .optOut)
            await keychainManager.deleteIdentityFromKeychain()
            await keychainManager.saveIdentityToKeychain(identityPackageOptOut)
            return nil
        } else if let identity, status == .established {
            self.state = .established(identity)
            // Not needed for loadFromDisk, but is needed for initial setting of Identity
            let identityPackage = IdentityPackage(valid: true, errorMessage: statusText, identity: identity, status: .established)
            os_log("Updating storage (Status: %@)", log: log, status.debugDescription)
            await keychainManager.saveIdentityToKeychain(identityPackage)
            return identity
        }
        
        // Process Remaining IdentityStatus Options
        let validatedIdentityPackage = getIdentityPackage(identity: identity, newIdentity: self.state == nil)

        os_log("Updating identity (Identity: %@, Status: %@)", log: log,
               validatedIdentityPackage.identity != nil ? "true" : "false",
               validatedIdentityPackage.status.debugDescription
        )

        self.state = State(validatedIdentityPackage)

        os_log("Updating storage (Status: %@)", log: log, validatedIdentityPackage.status.debugDescription)
        await keychainManager.saveIdentityToKeychain(validatedIdentityPackage)

        await checkIdentityRefresh()
        await checkIdentityExpiration()
        
        return validatedIdentityPackage.identity
    }

    // MARK: - Refresh and Timer
    
    private func checkIdentityRefresh() async {
        refreshJob?.cancel()
        refreshJob = nil

        if !automaticRefreshEnabled {
            return
        }
        
        if let identity = state?.identity {
            // If the identity is already suitable for a refresh, we can do so immediately. Otherwise, we will work out
            // how long it is until a refresh is required and schedule it accordingly.
            if hasExpired(expiry: identity.refreshFrom) {
                refreshJob = Task {
                    await refreshToken(identity: identity)
                }
            } else {
                refreshJob = Task {
                    let delayInNanoseconds = calculateDelay(futureCompletionTime: identity.refreshFrom)
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
                
        if let identity = state?.identity {

            // If the expiration time of being able to refresh is in the future, we will schedule a job to detect if we
            // pass it. This will allow us to reevaluate our state and update accordingly.
            if !hasExpired(expiry: identity.refreshExpires) {
                checkRefreshExpiresJob = Task {
                    let delayInNanoseconds = calculateDelay(futureCompletionTime: identity.refreshExpires)
                    try await Task.sleep(nanoseconds: delayInNanoseconds)
                    os_log("Detected refresh has expired", log: log, type: .debug)
                    await validateAndSetIdentity(identity: identity, status: nil, statusText: nil)
                }
            }
            
            if !hasExpired(expiry: identity.identityExpires) {
                checkIdentityExpiresJob = Task {
                    let delayInNanoseconds = calculateDelay(futureCompletionTime: identity.identityExpires)
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
    private func calculateDelay(futureCompletionTime: Int64) -> UInt64 {
        let now = dateGenerator.now.millisecondsSince1970
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

internal struct DateGenerator {
    private var generate: () -> Date

    init(_ generate: @escaping () -> Date) {
        self.generate = generate
    }

    var now: Date {
        get {
            generate()
        }
        set {
            generate = { newValue }
        }
    }
}
