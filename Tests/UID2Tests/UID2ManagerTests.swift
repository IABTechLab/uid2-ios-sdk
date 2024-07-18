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
