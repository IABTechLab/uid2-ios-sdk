//
//  UID2ManagerTests.swift
//
//
//  Created by Dave Snabel-Caunt on 16/07/2024.
//

import Combine
import CryptoKit
import Foundation
import TestHelpers
@testable import UID2
import XCTest

final class UID2ManagerTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    // swiftlint:disable:next line_length
    private let serverPublicKeyString = "UID2-X-I-MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEKAbPfOz7u25g1fL6riU7p2eeqhjmpALPeYoyjvZmZ1xM2NM8UeOmDZmCIBnKyRZ97pz5bMCjrs38WM22O7LJuw=="

    override func setUp() async throws {
        struct UnexpectedRequest: Error {
            let request: URLRequest
        }
        HTTPStub.shared.stubs = { request in
            .failure(UnexpectedRequest(request: request))
        }
    }
    
    func testNonEUIDEnvironment() async {
        let manager = UID2Manager(
            uid2Client: UID2Client.test(),
            storage: .null,
            sdkVersion: (1, 0, 0),
            log: .disabled
        )
        
        let isEuidEnvironment = await manager.isEuidEnvironment
        XCTAssertFalse(isEuidEnvironment)
    }

    func testEUIDEnvironment() async {
        let manager = UID2Manager(
            uid2Client: UID2Client.test(
                environment: .init(
                    endpoint: URL(string: "https://prod.euid.eu/v2")!,
                    isProduction: true,
                    isEuid: true
                )
            ),
            storage: .null,
            sdkVersion: (1, 0, 0),
            log: .disabled
        )
        
        let isEuidEnvironment = await manager.isEuidEnvironment
        XCTAssertTrue(isEuidEnvironment)
    }

    func testInitialState() async throws {
        let manager = UID2Manager(
            uid2Client: UID2Client.test(),
            storage: .null,
            sdkVersion: (1, 0, 0),
            log: .disabled
        )
        let state = await manager.state
        XCTAssertEqual(state, .none)

        let identity = await manager.identity
        let identityStatus = await manager.identityStatus
        XCTAssertNil(identity)
        XCTAssertEqual(identityStatus, .noIdentity)
    }

    func testClientGenerateServerOptout() async throws {
        let testCrypto = stubEncrypted("/v2/token/client-generate", fixture: "refresh-token-200-optout-decrypted")
        let manager = UID2Manager(
            uid2Client: UID2Client.test(
                cryptoUtil: testCrypto.cryptoUtil
            ),
            storage: .null,
            sdkVersion: (1, 0, 0),
            log: .disabled
        )

        let expectation = XCTestExpectation(description: "identityStatus == .optout")
        await manager.$identityStatus.sink { identityStatus in
            if identityStatus == .optOut {
                expectation.fulfill()
            }
        }.store(in: &cancellables)

        try await manager.generateIdentity(
            .emailHash("tMmiiTI7IaAcPpQPFQ65uMVCWH8av9jw4cwf/F5HVRQ="),
            subscriptionID: "test",
            serverPublicKey: serverPublicKeyString,
            appName: "com.example.app"
        )
        await fulfillment(of: [expectation], timeout: 1)

        let state = await manager.state
        XCTAssertEqual(state, .optout)

        let identity = await manager.identity
        let identityStatus = await manager.identityStatus
        XCTAssertNil(identity)
        XCTAssertEqual(identityStatus, .optOut)
    }

    func testClientGenerateRefreshExpired() async throws {
        let testCrypto = stubEncrypted("/v2/token/client-generate", fixture: "refresh-token-200-success-decrypted")

        let manager = UID2Manager(
            uid2Client: UID2Client.test(
                cryptoUtil: testCrypto.cryptoUtil
            ),
            storage: .null,
            sdkVersion: (1, 0, 0),
            log: .disabled
        )

        let expectation = XCTestExpectation(description: "identityStatus == .refreshExpired")
        await manager.$identityStatus.sink { identityStatus in
            if identityStatus == .refreshExpired {
                expectation.fulfill()
            }
        }.store(in: &cancellables)

        try await manager.generateIdentity(
            .emailHash("tMmiiTI7IaAcPpQPFQ65uMVCWH8av9jw4cwf/F5HVRQ="),
            subscriptionID: "test",
            serverPublicKey: serverPublicKeyString,
            appName: "com.example.app"
        )
        await fulfillment(of: [expectation], timeout: 1)

        let state = await manager.state
        XCTAssertEqual(state, .refreshExpired)

        let identity = await manager.identity
        let identityStatus = await manager.identityStatus
        XCTAssertNil(identity)
        XCTAssertEqual(identityStatus, .refreshExpired)
    }

    func testClientGenerateSuccess() async throws {
        let testCrypto = stubEncrypted("/v2/token/client-generate", fixture: "refresh-token-200-success-decrypted")

        let manager = UID2Manager(
            uid2Client: UID2Client.test(
                cryptoUtil: testCrypto.cryptoUtil
            ),
            storage: .null,
            sdkVersion: (1, 0, 0),
            log: .disabled,
            dateGenerator: .init({ Date(timeIntervalSince1970: 5) })
        )

        let expectation = XCTestExpectation(description: "identityStatus == .established")
        await manager.$identityStatus.sink { identityStatus in
            if identityStatus == .established {
                expectation.fulfill()
            }
        }.store(in: &cancellables)

        try await manager.generateIdentity(
            .emailHash("tMmiiTI7IaAcPpQPFQ65uMVCWH8av9jw4cwf/F5HVRQ="),
            subscriptionID: "test",
            serverPublicKey: serverPublicKeyString,
            appName: "com.example.app"
        )
        await fulfillment(of: [expectation], timeout: 1)

        let state = await manager.state
        XCTAssertEqual(
            state,
            .established(
                .init(
                    advertisingToken: "AgAAAnojG9KCix9paKGDw4cyFWj6TC6JcXxkwaJHWbq9e9sBL6ENzlabgtas04zjHxkFCCKAPppamsWt+PISfsmz7o3jrjRZuUmYo9htdDgZLNQSXLxwabHJKvXm4RVJN5gGtVUOUyYzx9ybLMSf2wrdLGZqTBxZIEmO8y/k2jL9ZYq74A==",
                    refreshToken: "AAAAAntKHPHFFDsLKy3LngnBg/A4d25Sw1P+evWqRdnVlFKLi5OgQLJq2lAfRtHD2YTaCx7G9VaQkg3dx5gusxUs8rSD0bOR6/aZS70v0mft/qfol4aNxdzCE9BOVTC8EP/Z/vlIcS8DnHMkOgIEk6KD0M782+JpHrjLwXXmt+tMnKDybnZK6X5zjuFYl9OT6aogIEUEUQIMqenP9y4ctu/b3UALvyx6se0zlGKb1wzu1ilnxbND5I42n3MYn2Nqs4eVtuDBRdDT6L8+ElVTHVfVzS02mG+OYWiyVZyAbQP1iyBWmybkP8PcJsTUmDZE2WPzgvtV5+6/deZ/s+taMJo8FMJbP3oVkq5985MYHdXaSTiaT8sBc0JwHgqW9vaUgLsb",
                    identityExpires: 1675272748539,
                    refreshFrom: 1675272148539,
                    refreshExpires: 1677863848539,
                    refreshResponseKey: "ZsLNtb55Kr9vGEDj2nTiYN4rqL6ofXcnvXKyI0oVdyM="
                )
            )
        )

        let identity = await manager.identity
        let identityStatus = await manager.identityStatus
        XCTAssertNotNil(identity)
        XCTAssertEqual(identityStatus, .established)
    }

    // MARK: Identity Restoration

    func testNoneIdentityRestorationFromStorage() async throws {
        let manager = UID2Manager(
            uid2Client: UID2Client.test(),
            storage: .null,
            sdkVersion: (1, 0, 0),
            log: .disabled
        )
        let expectation = XCTestExpectation()
        await manager.addInitializationListener {
            let state = await manager.state
            XCTAssertEqual(state, .none)
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1)
    }

    func testOptoutIdentityRestorationFromStorage() async throws {
        let manager = UID2Manager(
            uid2Client: UID2Client.test(),
            storage: .init(
                loadIdentity: {
                    IdentityPackage(valid: true, errorMessage: nil, identity: nil, status: .optOut)
                },
                saveIdentity: { _ in },
                clearIdentity: { }
            ),
            sdkVersion: (1, 0, 0),
            log: .disabled
        )
        let expectation = XCTestExpectation()
        await manager.addInitializationListener {
            let state = await manager.state
            XCTAssertEqual(state, .optout)
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1)
    }

    func testEstablishedIdentityRestorationFromStorage() async throws {
        let establishedIdentity = UID2Identity.established()
        let manager = UID2Manager(
            uid2Client: UID2Client.test(),
            storage: .init(
                loadIdentity: {
                    IdentityPackage(valid: true, errorMessage: nil, identity: establishedIdentity, status: .established)
                },
                saveIdentity: { _ in },
                clearIdentity: { }
            ),
            sdkVersion: (1, 0, 0),
            log: .disabled
        )
        let expectation = XCTestExpectation()
        await manager.addInitializationListener {
            let state = await manager.state
            XCTAssertEqual(state, .established(establishedIdentity))
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1)
    }

    // MARK: State Observation

    @MainActor
    func testStateValuesObservation() async throws {
        let manager = UID2Manager(
            uid2Client: UID2Client.test(),
            storage: .null,
            sdkVersion: (1, 0, 0),
            log: .disabled
        )

        // test after initialization to observe after initial state configuration
        let expectation = XCTestExpectation()
        await manager.addInitializationListener {
            // Initialize the streams now so that observers are attached
            let stateValues = await manager.stateValues().prefix(3)

            // Observe streams asynchronously
            async let allStates = stateValues.reduce(into: []) { $0.append($1) }

            let establishedIdentity = UID2Identity(
                advertisingToken: "a",
                refreshToken: "r",
                identityExpires: Date().millisecondsSince1970 + 100000,
                refreshFrom: Date().millisecondsSince1970 + 100000,
                refreshExpires: Date().millisecondsSince1970 + 100000,
                refreshResponseKey: ""
            )

            // Emit state changes
            await manager.resetIdentity()
            await manager.setIdentity(establishedIdentity)
            await manager.resetIdentity()

            let states = await allStates
            XCTAssertEqual(states, [
                nil,
                .established(establishedIdentity),
                nil,
            ])
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1)
    }

    @MainActor
    func testStateValuesMultipleObservers() async throws {
        let manager = UID2Manager(
            uid2Client: UID2Client.test(),
            storage: .null,
            sdkVersion: (1, 0, 0),
            log: .disabled
        )

        // test after initialization to observe after initial state configuration
        let expectation = XCTestExpectation()
        await manager.addInitializationListener {
            // Initialize the streams now so that observers are attached
            let stateValuesA = await manager.stateValues().prefix(4)
            let stateValuesB = await manager.stateValues().prefix(4)

            // Observe streams asynchronously
            async let allStatesA = stateValuesA.reduce(into: []) { $0.append($1) }
            async let allStatesB = stateValuesB.reduce(into: []) { $0.append($1) }

            let establishedIdentity = UID2Identity.established()
            let expiredIdentity = UID2Identity.expired()

            // Emit state changes
            await manager.resetIdentity()
            await manager.setIdentity(establishedIdentity)
            await manager.resetIdentity()
            await manager.setIdentity(expiredIdentity)

            let statesA = await allStatesA
            let statesB = await allStatesB
            XCTAssertEqual(statesA, statesB)
            XCTAssertEqual(
                statesA,
                [
                    nil,
                    .established(establishedIdentity),
                    nil,
                    .refreshExpired
                ]
            )
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1)
    }

    // MARK: Internal

    private func stubEncrypted(
        _ path: String,
        fixture: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> TestCryptoUtil {
        let testCrypto = TestCryptoUtil()
        HTTPStub.shared.stubs = { request in
            XCTAssertEqual(request.url?.path, path, file: file, line: line)
            let responseData = try! FixtureLoader.data(fixture: fixture)
            let box = try! AES.GCM.seal(responseData, using: testCrypto.symmetricKey!)
            let data = box.combined!.base64EncodedData()
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return .success((data, response))
        }
        return testCrypto
    }
}

private extension UID2Identity {
    static func established() -> UID2Identity {
        .init(
            advertisingToken: "a",
            refreshToken: "r",
            identityExpires: Date().millisecondsSince1970 + 100000,
            refreshFrom: Date().millisecondsSince1970 + 100000,
            refreshExpires: Date().millisecondsSince1970 + 100000,
            refreshResponseKey: ""
        )
    }
    static func expired() -> UID2Identity {
        .init(
            advertisingToken: "e",
            refreshToken: "r",
            identityExpires: Date().millisecondsSince1970 - 100000,
            refreshFrom: Date().millisecondsSince1970 - 100000,
            refreshExpires: Date().millisecondsSince1970 - 100000,
            refreshResponseKey: ""
        )
    }
}
extension Storage {
    static var null: Self {
        Storage(
            loadIdentity: { nil },
            saveIdentity: { _ in },
            clearIdentity: {}
        )
    }
}
