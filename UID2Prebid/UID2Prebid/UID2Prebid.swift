import Combine
import Foundation
@preconcurrency import PrebidMobile
import UID2

protocol UserIDUpdater: Sendable {
    func updateUserIDs(_ userIDs: [ExternalUserId]) async
}

struct PrebidUserIDUpdater: UserIDUpdater {
    /// Passes the observed IDs to Prebid
    func updateUserIDs(_ userIDs: [ExternalUserId]) {
        Prebid.shared.externalUserIdArray = userIDs
    }
}

public actor UID2Prebid: Sendable {
    let thirdPartyUserIDs: @Sendable () async -> [ExternalUserId]
    let userIDUpdater: UserIDUpdater
    private let source = "uidapi.com"
    private var task: Task<Void, Never>?
    
    let stateStream: () async -> AsyncStream<UID2Manager.State?>
    let initialToken: () async -> String?

    /// Initializes an observer of a `UID2Manager` which updates the Prebid SDK's `externalUserIdArray`
    /// whenever the UID advertising token changes.
    /// If you need to provide Prebid with other `ExternalUserId` values you can do so by passing a closure
    /// or function to `thirdPartyUserIDs` with the additional IDs.
    public init(
        manager: UID2Manager = .shared,
        thirdPartyUserIDs: @Sendable @escaping () async -> [ExternalUserId] = { [] }
    ) {
        self.init(
            manager: manager,
            thirdPartyUserIDs: thirdPartyUserIDs,
            userIDUpdater: PrebidUserIDUpdater(),
            initialToken: { await manager.getAdvertisingToken() },
            stateStream: { await manager.stateValues() }
        )
    }

    init(
        manager: UID2Manager,
        thirdPartyUserIDs: @Sendable @escaping () async -> [ExternalUserId] = { [] },
        userIDUpdater: UserIDUpdater,
        initialToken: @Sendable @escaping () async -> String?,
        stateStream: @Sendable @escaping () async -> AsyncStream<UID2Manager.State?>
    ) {
        self.thirdPartyUserIDs = thirdPartyUserIDs
        self.userIDUpdater = userIDUpdater
        self.initialToken = initialToken
        self.stateStream = stateStream
        Task {
            await manager.addInitializationListener { [weak self] in
                guard let self else { return }
                await self.updateExternalUserID(initialToken())
                await self.observeIdentityChanges()
            }
        }
    }

    func observeIdentityChanges() {
        self.task = Task {
            let identities = await stateStream()
            for await advertisingToken in identities.map({ $0?.identity?.advertisingToken }) {
                await updateExternalUserID(advertisingToken)
            }
        }
    }

    func updateExternalUserID(_ advertisingToken: String?) async {
        var userIDs = await self.thirdPartyUserIDs()
        if let advertisingToken {
            let advertisingTokenUser = ExternalUserId(source: source, identifier: advertisingToken)
            userIDs.append(advertisingTokenUser)
        }
        await userIDUpdater.updateUserIDs(userIDs)
    }

    deinit {
        task?.cancel()
    }
}
