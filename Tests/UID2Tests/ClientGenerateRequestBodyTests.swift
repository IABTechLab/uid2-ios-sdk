//
//  ClientGenerateRequestBodyTests.swift
//
//
//  Created by Dave Snabel-Caunt on 10/04/2024.
//

import CryptoKit
@testable import UID2
import XCTest

final class ClientGenerateRequestBodyTests: XCTestCase {

    func testEmailPayload() throws {
        let body = ClientGenerateRequestBody(
            payload: "payload",
            initializationVector: "initializationVector",
            publicKey: "publicKey",
            subscriptionID: "subscriptionID",
            timestamp: 90210,
            appName: "com.my.app"
        )

        try assertPayloadJSON(
            body,
            """
            {
              "app_name" : "com.my.app",
              "iv" : "initializationVector",
              "payload" : "payload",
              "public_key" : "publicKey",
              "subscription_id" : "subscriptionID",
              "timestamp" : 90210
            }
            """
        )
    }

    private func assertPayloadJSON(_ payload: any Encodable, _ json: String, file: StaticString = #filePath, line: UInt = #line) throws {
        let encoder = JSONEncoder.apiEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(payload)
        XCTAssertEqual(
            String(data: data, encoding: .utf8),
            json,
            file: file,
            line: line
        )
    }
}
