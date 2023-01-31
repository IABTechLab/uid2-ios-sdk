//
//  UID2Token.swift
//
//  Created by Brad Leege on 9/13/22.
//

import Foundation

public struct UID2Token: Codable {
    public let advertisingToken: String
    public let refreshToken: String
    public let identityExpires: TimeInterval
    public let refreshFrom: TimeInterval
    public let refreshExpires: TimeInterval
    public let refreshResponseKey: String
}

extension UID2Token {
    
    func toData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return try encoder.encode(self)
    }
    
    static func fromData(_ data: Data) -> UID2Token? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try? decoder.decode(UID2Token.self, from: data)
    }

}
