//
//  UID2ManagerTests.swift
//
//
//  Created by Dave Snabel-Caunt on 16/07/2024.
//

import Combine
import CryptoKit
import Foundation
@testable import UID2
import XCTest

final class UID2ManagerTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    // swiftlint:disable:next line_length
    private let serverPublicKeyString = "UID2-X-I-MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEKAbPfOz7u25g1fL6riU7p2eeqhjmpALPeYoyjvZmZ1xM2NM8UeOmDZmCIBnKyRZ97pz5bMCjrs38WM22O7LJuw=="

    func testInitialState() async throws {
        let manager = UID2Manager(
            uid2Client: UID2Client(
                sdkVersion: "1.0"
            ),
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
            uid2Client: UID2Client(
                sdkVersion: "1.0",
                cryptoUtil: testCrypto.cryptoUtil
            ),
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
            uid2Client: UID2Client(
                sdkVersion: "1.0",
                cryptoUtil: testCrypto.cryptoUtil
            ),
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
            uid2Client: UID2Client(
                sdkVersion: "1.0",
                cryptoUtil: testCrypto.cryptoUtil
            ),
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

    private func stubEncrypted(_ path: String, fixture: String) -> TestCryptoUtil {
        let testCrypto = TestCryptoUtil()
        HTTPStub.shared.stubs = { request in
            XCTAssertEqual(request.url?.path, path)
            let responseData = try! FixtureLoader.data(fixture: fixture)
            let box = try! AES.GCM.seal(responseData, using: testCrypto.symmetricKey!)
            let data = box.combined!.base64EncodedData()
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return .success((data, response))
        }
        return testCrypto
    }
}
