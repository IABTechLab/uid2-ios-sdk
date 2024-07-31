//
//  FixtureLoader.swift
//
//
//  Created by Dave Snabel-Caunt on 18/04/2024.
//

import Foundation
@testable import UID2

public final class FixtureLoader {
    enum Error: Swift.Error {
        case missingFixture(String)
    }

    /// Read `Data` from a Fixture.
    public static func data(
        fixture: String,
        withExtension fileExtension: String = "json",
        subdirectory: String = "TestData"
    ) throws -> Data {
        guard let fixtureURL = Bundle.module.url(
            forResource: fixture,
            withExtension: fileExtension,
            subdirectory: subdirectory
        ) else {
            throw Error.missingFixture("\(subdirectory)/\(fixture).\(fileExtension)")
        }
        return try Data(contentsOf: fixtureURL)
    }

    /// Decode a `Decodable` from a Fixture.
    /// Expects the fixture to use snake_case key encoding.
    public static func decode<T>(
        _ type: T.Type,
        fixture: String,
        withExtension fileExtension: String = "json",
        subdirectory: String = "TestData"
    ) throws -> T where T : Decodable {
        let data = try data(fixture: fixture, withExtension: fileExtension, subdirectory: subdirectory)
        let decoder = JSONDecoder.apiDecoder()
        return try decoder.decode(type, from: data)
    }
}

