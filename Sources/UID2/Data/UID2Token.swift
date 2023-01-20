//
//  UID2Token.swift
//
//  Created by Brad Leege on 9/13/22.
//

import Foundation

struct UID2Token: Codable {
    let advertisingToken: String
    let refreshToken: String
    let identityExpires: TimeInterval
    let refreshFrom: TimeInterval
    let refreshExpires: TimeInterval
    let refreshResponseKey: String
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
