//
//  XCTest+Extensions.swift
//
//
//  Created by Dave Snabel-Caunt on 18/04/2024.
//

import XCTest

/// `XCTAssertThrowsError` doesn't support async expressions.
public func assertThrowsError<T>(
    _ expression: @escaping @autoclosure () async throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line,
    _ errorHandler: (_ error: Error) -> Void = { _ in }
) async {
    // Use `Result.get` to rethrow inside `XCTAssertThrowsError` after the asynchronous `expression` is complete.
    let result = await Task {
        try await expression()
    }.result
    XCTAssertThrowsError(try result.get(), message(), file: file, line: line, errorHandler)
}

