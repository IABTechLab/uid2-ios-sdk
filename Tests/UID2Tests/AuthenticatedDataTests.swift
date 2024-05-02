//
//  AuthenticatedDataTests.swift
//
//
//  Created by Dave Snabel-Caunt on 10/04/2024.
//

@testable import UID2
import XCTest

final class AuthenticatedDataTests: XCTestCase {

    func testEncoding() throws {
        let authenticatedData = AuthenticatedData(timestamp: 12345, appName: "com.uid2.test")
        let jsonData = try JSONEncoder.apiEncoder().encode(authenticatedData)
        XCTAssertEqual(
            String(data: jsonData, encoding: .utf8),
            """
            [12345,"com.uid2.test"]
            """
        )
    }
}
