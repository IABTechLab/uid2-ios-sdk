//
//  UID2ClientTests.swift
//
//
//  Created by Dave Snabel-Caunt on 25/04/2024.
//

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
}
