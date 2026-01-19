//
//  UID2PrebidTests.swift
//
//
//  Created by Dave Snabel-Caunt on 21/07/2024.
//

import Foundation
import PrebidMobile
import TestHelpers
@testable import UID2
@testable import UID2Prebid
import XCTest

@MainActor
final class TestUserIDUpdater: Sendable, UserIDUpdater {
    var observer: (([ExternalUserId]) -> Void)?

    func updateUserIDs(_ userIDs: [ExternalUserId]) {
        observer?(userIDs)
    }
}

final class UID2PrebidTests: XCTestCase {

    var prebid: UID2Prebid!

    @MainActor
    func testObservation() async throws {
        let manager = UID2Manager(
            uid2Client: UID2Client(
                sdkVersion: "1.0",
                environment: Environment(UID2.Environment.production)
            ),
            storage: .null,
            sdkVersion: (1, 0, 0),
            log: .disabled
        )
        let updater = TestUserIDUpdater()

        let (stream, continuation) = AsyncStream<UID2Manager.State?>.makeStream()

        prebid = UID2Prebid(
            manager: manager,
            userIDUpdater: updater,
            initialToken: {
                "cat"
            },
            stateStream: {
                stream
            }
        )
        await observation(
            of: [
                ExternalUserId(source: "uidapi.com", uids: [.init(id: "cat", aType: 3)])
            ],
            by: updater
        )

        continuation.yield(.optout)
        await observation(
            of: [],
            by: updater
        )

        continuation.yield(
            .established(.established(advertisingToken: "turtle"))
        )
        await observation(
            of: [
                ExternalUserId(source: "uidapi.com", uids: [.init(id: "turtle", aType: 3)])
            ],
            by: updater
        )
    }

    @MainActor
    func testObservationWithThirdPartyUserIDs() async throws {
        let manager = UID2Manager(
            uid2Client: UID2Client(
                sdkVersion: "1.0",
                environment: Environment(UID2.Environment.production)
            ),
            storage: .null,
            sdkVersion: (1, 0, 0),
            log: .disabled
        )
        let updater = TestUserIDUpdater()

        let (stream, continuation) = AsyncStream<UID2Manager.State?>.makeStream()

        prebid = UID2Prebid(
            manager: manager,
            thirdPartyUserIDs: {
                [
                    ExternalUserId(source: "example.com", uids: [.init(id: "dog", aType: 3)])
                ]
            },
            userIDUpdater: updater,
            initialToken: {
                "cat"
            },
            stateStream: {
                stream
            }
        )
        await observation(
            of: [
                ExternalUserId(source: "example.com", uids: [.init(id: "dog", aType: 3)]),
                ExternalUserId(source: "uidapi.com", uids: [.init(id: "cat", aType: 3)]),
            ],
            by: updater
        )

        continuation.yield(.invalid)
        await observation(
            of: [
                ExternalUserId(source: "example.com", uids: [.init(id: "dog", aType: 3)]),
            ],
            by: updater
        )
    }

    @MainActor
    func testObservationOfEUIDSource() async throws {
        let manager = UID2Manager(
            uid2Client: UID2Client(
                sdkVersion: "1.0",
                environment: Environment(EUID.Environment.production)
            ),
            storage: .null,
            sdkVersion: (1, 0, 0),
            log: .disabled
        )
        let updater = TestUserIDUpdater()

        let (stream, continuation) = AsyncStream<UID2Manager.State?>.makeStream()

        prebid = UID2Prebid(
            manager: manager,
            userIDUpdater: updater,
            initialToken: {
                "cat"
            },
            stateStream: {
                stream
            }
        )
        await observation(
            of: [
                ExternalUserId(source: "euid.eu", uids: [.init(id: "cat", aType: 3)])
            ],
            by: updater
        )

        continuation.yield(.optout)
        await observation(
            of: [],
            by: updater
        )

        continuation.yield(
            .established(.established(advertisingToken: "turtle"))
        )
        await observation(
            of: [
                ExternalUserId(source: "euid.eu", uids: [.init(id: "turtle", aType: 3)])
            ],
            by: updater
        )
    }

    @MainActor
    func observation(of expectedUserIds: [ExternalUserId], by updater: TestUserIDUpdater) async {
        let expectation = XCTestExpectation(description: "Expected Test Updater to observe specific value")
        updater.observer = { userIds in
            if Self.isEqual(expectedUserIds, userIds) {
                expectation.fulfill()
            }
        }
        await fulfillment(of: [expectation], timeout: 1)
    }
}

extension UID2PrebidTests {
    static func isEqual(
        _ lhs: [ExternalUserId],
        _ rhs: [ExternalUserId]
    ) -> Bool {
        let lhs = lhs.map(ExternalUserIdEquatable.init)
        let rhs = rhs.map(ExternalUserIdEquatable.init)

        return lhs == rhs
    }
    struct ExternalUserIdEquatable: Equatable {
        var source: String
        var uids: [UserUniqueIDEquatable] = []

        init(_ userId: ExternalUserId) {
            self.source = userId.source
            self.uids = userId.uids.map(UserUniqueIDEquatable.init)
        }
    }
    struct UserUniqueIDEquatable: Equatable {
        var id: String
        var aType: Int
        init(_ userId: UserUniqueID) {
            self.id = userId.id
            self.aType = userId.aType.intValue
        }
    }
}

private extension UID2Identity {
    static func established(advertisingToken: String) -> UID2Identity {
        .init(
            advertisingToken: advertisingToken,
            refreshToken: "r",
            identityExpires: Date().millisecondsSince1970 + 100000,
            refreshFrom: Date().millisecondsSince1970 + 100000,
            refreshExpires: Date().millisecondsSince1970 + 100000,
            refreshResponseKey: ""
        )
    }
}

private extension Storage {
    static var null: Self {
        Storage(
            loadIdentity: { nil },
            saveIdentity: { _ in },
            clearIdentity: {}
        )
    }
}
