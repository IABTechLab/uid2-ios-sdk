//
//  UID2ClientTests.swift
//
//
//  Created by Dave Snabel-Caunt on 25/04/2024.
//

import CryptoKit
import Foundation
@testable import UID2
import XCTest

final class UID2ClientTests: XCTestCase {
    func testDefaultEnvironment() async throws {
        let client = UID2Client(
            sdkVersion: "1.0"
        )
        let urlRequest = client.urlRequest(.init(path: "/path"))
        XCTAssertEqual(
            urlRequest.url,
            URL(string: "https://prod.uidapi.com/path")!
        )
    }

    func testOverridenEnvironment() async throws {
        let client = UID2Client(
            sdkVersion: "1.0",
            environment: .singapore
        )
        let urlRequest = client.urlRequest(.init(path: "/path"))
        XCTAssertEqual(
            urlRequest.url,
            URL(string: "https://sg.prod.uidapi.com/path")!
        )
    }

    func testCustomEnvironment() async throws {
        let client = UID2Client(
            sdkVersion: "1.0",
            environment: .custom(url: URL(string: "http://localhost:8080/")!)
        )
        let urlRequest = client.urlRequest(.init(path: "/path"))
        XCTAssertEqual(
            urlRequest.url,
            URL(string: "http://localhost:8080/path")!
        )
    }

    func testClientVersionHeader() throws {
        let client = UID2Client(
            sdkVersion: "1.2.3"
        )

        let request = client.urlRequest(Request(path: "/test"))
#if os(tvOS)
        XCTAssertEqual(
            request.allHTTPHeaderFields,
            [
                "X-UID2-Client-Version": "tvos-1.2.3"
            ]
        )
#else
        XCTAssertEqual(
            request.allHTTPHeaderFields,
            [
                "X-UID2-Client-Version": "ios-1.2.3"
            ]
        )
#endif
    }

    // MARK: Client-side token generation tests

    // swiftlint:disable:next line_length
    private let serverPublicKeyString = "UID2-X-I-MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEKAbPfOz7u25g1fL6riU7p2eeqhjmpALPeYoyjvZmZ1xM2NM8UeOmDZmCIBnKyRZ97pz5bMCjrs38WM22O7LJuw=="

    func testClientGenerateServerPublicKeyError() async throws {
        let client = UID2Client(
            sdkVersion: "1.0"
        )

        await assertThrowsError(
            try await client.generateIdentity(
                .emailHash("tMmiiTI7IaAcPpQPFQ65uMVCWH8av9jw4cwf/F5HVRQ="),
                subscriptionID: "test",
                serverPublicKey: "not-an-encoded-public-key",
                appName: "com.example.app"
            )
        ) { error in
            guard let error = error as? TokenGenerationError,
            case let .configuration(message: message) = error else {
                XCTFail("Expected UID2Error.configuration, got \(error)")
                return
            }
            XCTAssertEqual(message, "Invalid server public key as base64")
        }
    }

    func testClientGenerateServerDecodeError() async throws {
        HTTPStub.shared.stubs = { request in
            XCTAssertEqual(request.url?.path, "/v2/token/client-generate")
            let data = Data("not-encrypted-data".utf8)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return .success((data, response))
        }
        let client = UID2Client(
            sdkVersion: "1.0"
        )

        await assertThrowsError(
            try await client.generateIdentity(
                .emailHash("tMmiiTI7IaAcPpQPFQ65uMVCWH8av9jw4cwf/F5HVRQ="),
                subscriptionID: "test",
                serverPublicKey: self.serverPublicKeyString,
                appName: "com.example.app"
            )
        ) { error in
            guard let error = error as? TokenGenerationError,
            case .decryptionFailure = error else {
                XCTFail("Expected TokenGenerationError.decryptionFailure, got \(error)")
                return
            }
        }
    }

    func testClientGenerateServerDecodeErrorBase64() async throws {
        HTTPStub.shared.stubs = { request in
            XCTAssertEqual(request.url?.path, "/v2/token/client-generate")
            let data = Data("not-encrypted-data".utf8).base64EncodedData()
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return .success((data, response))
        }
        let client = UID2Client(
            sdkVersion: "1.0"
        )

        await assertThrowsError(
            try await client.generateIdentity(
                .emailHash("tMmiiTI7IaAcPpQPFQ65uMVCWH8av9jw4cwf/F5HVRQ="),
                subscriptionID: "test",
                serverPublicKey: self.serverPublicKeyString,
                appName: "com.example.app"
            )
        ) { error in
            guard let error = error as? TokenGenerationError,
            case .decryptionFailure = error else {
                XCTFail("Expected TokenGenerationError.decryptionFailure, got \(error)")
                return
            }
        }
    }

    func testClientGenerateServerClientError() async throws {
        HTTPStub.shared.stubs = { request in
            XCTAssertEqual(request.url?.path, "/v2/token/client-generate")

            let data = try! FixtureLoader.data(fixture: "refresh-token-400-client-error")

            let response = HTTPURLResponse(url: request.url!, statusCode: 400, httpVersion: nil, headerFields: nil)!
            return .success((data, response))
        }
        let client = UID2Client(
            sdkVersion: "1.0"
        )

        await assertThrowsError(
            try await client.generateIdentity(
                .emailHash("tMmiiTI7IaAcPpQPFQ65uMVCWH8av9jw4cwf/F5HVRQ="),
                subscriptionID: "test",
                serverPublicKey: self.serverPublicKeyString,
                appName: "com.example.app"
            )
        ) { error in
            guard let error = error as? TokenGenerationError,
            case .requestFailure = error else {
                XCTFail("Expected TokenGenerationError.requestFailure, got \(error)")
                return
            }
        }
    }

    func testClientGenerateServerOptout() async throws {
        let testCrypto = TestCryptoUtil()
        HTTPStub.shared.stubs = { request in
            XCTAssertEqual(request.url?.path, "/v2/token/client-generate")
            let responseData = try! FixtureLoader.data(fixture: "refresh-token-200-optout-decrypted")
            let box = try! AES.GCM.seal(responseData, using: testCrypto.symmetricKey!)
            let data = box.combined!.base64EncodedData()
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return .success((data, response))
        }

        let client = UID2Client(
            sdkVersion: "1.0",
            cryptoUtil: testCrypto.cryptoUtil
        )

        let result = try await client.generateIdentity(
            .emailHash("tMmiiTI7IaAcPpQPFQ65uMVCWH8av9jw4cwf/F5HVRQ="),
            subscriptionID: "test",
            serverPublicKey: serverPublicKeyString,
            appName: "com.example.app"
        )
        XCTAssertNil(result.identity)
        XCTAssertEqual(result.status, .optOut)
    }

    func testClientGenerateSuccess() async throws {
        let testCrypto = TestCryptoUtil()
        HTTPStub.shared.stubs = { request in
            XCTAssertEqual(request.url?.path, "/v2/token/client-generate")
            let responseData = try! FixtureLoader.data(fixture: "refresh-token-200-success-decrypted")
            let box = try! AES.GCM.seal(responseData, using: testCrypto.symmetricKey!)
            let data = box.combined!.base64EncodedData()
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return .success((data, response))
        }

        let client = UID2Client(
            sdkVersion: "1.0",
            cryptoUtil: testCrypto.cryptoUtil
        )

        let result = try await client.generateIdentity(
            .emailHash("tMmiiTI7IaAcPpQPFQ65uMVCWH8av9jw4cwf/F5HVRQ="),
            subscriptionID: "test",
            serverPublicKey: serverPublicKeyString,
            appName: "com.example.app"
        )
        XCTAssertNotNil(result.identity)
    }
}

// Simple Atomic implementation for test usage
private final class Atomic<Value: Sendable>: @unchecked Sendable {

    private let lock = NSRecursiveLock()

    private var _value: Value

    var value: Value {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _value
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _value = newValue
        }
    }

    init(_ value: Value) {
        _value = value
    }
}

/// A test convenience which exposes the Symmetric Key it generates for the client.
/// This key can then be used to encrypt stub responses for the client.
private final class TestCryptoUtil {
    private let atomicSymmetricKey: Atomic<SymmetricKey?>

    /// `SymmetricKey` generated by the client, or `nil` if the key has not yet been generated.
    var symmetricKey: SymmetricKey? {
        atomicSymmetricKey.value
    }
    let cryptoUtil: CryptoUtil

    init() {
        let symmetricKey = Atomic<SymmetricKey?>(nil)
        self.atomicSymmetricKey = symmetricKey

        let crypto = CryptoUtil.liveValue
        self.cryptoUtil = CryptoUtil(
            // Use the live implementations, but grab the symmetricKey
            // so we can use it to encrypt a stub response
            parseKey: { string in
                let result = try crypto.parseKey(string)
                symmetricKey.value = result.0
                return result
            }, encrypt: { data, key, authenticatedData in
                try crypto.encrypt(data, key, authenticatedData)
            }
        )
    }
}
