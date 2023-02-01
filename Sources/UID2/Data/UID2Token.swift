//
//  UID2Token.swift
//
//  Created by Brad Leege on 9/13/22.
//

import Foundation

public struct UID2Token: Codable {
    public var advertisingToken: String?
    public var refreshToken: String?
    public var identityExpires: TimeInterval?
    public var refreshFrom: TimeInterval?
    public var refreshExpires: TimeInterval?
    public var refreshResponseKey: String?
    public let status: String?
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
