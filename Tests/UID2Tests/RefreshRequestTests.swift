//
//  RefreshRequestTests.swift
//
//
//  Created by Dave Snabel-Caunt on 24/04/2024.
//

import XCTest
@testable import UID2

final class RefreshRequestTests: XCTestCase {

    func testRequest() async throws {
        let request = Request.refresh(token: "im-a-refresh-token")
        let client = UID2Client(
            sdkVersion: "1.2.3"
        )
        let urlRequest = client.urlRequest(request)

        var expected = URLRequest(url: URL(string: "https://prod.uidapi.com/v2/token/refresh")!)
        expected.httpMethod = "POST"
        expected.httpBody = Data("im-a-refresh-token".utf8)

#if os(tvOS)
        expected.allHTTPHeaderFields = [
            "Content-Type": "application/x-www-form-urlencoded",
            "X-UID2-Client-Version": "tvos-1.2.3"
        ]
#else
        expected.allHTTPHeaderFields = [
            "Content-Type": "application/x-www-form-urlencoded",
            "X-UID2-Client-Version": "ios-1.2.3"
        ]
#endif
        XCTAssertEqual(urlRequest, expected)
        
        // The above equality test doesn't print useful information on failure, so 
        // it's useful to check properties below for diagnostics
        XCTAssertEqual(urlRequest.url, expected.url)
        XCTAssertEqual(urlRequest.httpMethod, expected.httpMethod)
        XCTAssertEqual(urlRequest.httpBody, expected.httpBody)
        XCTAssertEqual(urlRequest.allHTTPHeaderFields, expected.allHTTPHeaderFields)
    }
}
