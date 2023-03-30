//
//  UID2Identity.swift
//  
//
//  Created by Brad Leege on 2/9/23.
//

import Foundation

public struct UID2Identity: Codable {
    
    public let advertisingToken: String
    public let refreshToken: String
    public let identityExpires: Int64
    public let refreshFrom: Int64
    public let refreshExpires: Int64
    public let refreshResponseKey: String

    public init(advertisingToken: String, refreshToken: String, identityExpires: Int64, refreshFrom: Int64, refreshExpires: Int64, refreshResponseKey: String) {
        self.advertisingToken = advertisingToken
        self.refreshToken = refreshToken
        self.identityExpires = identityExpires
        self.refreshFrom = refreshFrom
        self.refreshExpires = refreshExpires
        self.refreshResponseKey = refreshResponseKey
    }
    
}

extension UID2Identity {
    
    static func fromData(_ data: Data) -> UID2Identity? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try? decoder.decode(UID2Identity.self, from: data)
    }

    func toData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return try encoder.encode(self)
    }

}
