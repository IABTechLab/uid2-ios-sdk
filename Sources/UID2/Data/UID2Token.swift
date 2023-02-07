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
    public let status: Status
    
    public init(advertisingToken: String? = nil, refreshToken: String? = nil, identityExpires: TimeInterval? = nil, refreshFrom: TimeInterval? = nil, refreshExpires: TimeInterval? = nil, refreshResponseKey: String? = nil, status: Status) {
        self.advertisingToken = advertisingToken
        self.refreshToken = refreshToken
        self.identityExpires = identityExpires
        self.refreshFrom = refreshFrom
        self.refreshExpires = refreshExpires
        self.refreshResponseKey = refreshResponseKey
        self.status = status
    }
    
}

extension UID2Token {
    
    public enum Status: String, Codable {
        case success = "success"
        case optOut = "optout"
        case clientError = "client_error"
        case invalidToken = "invalid_token"
        case unauthorized = "unauthorized"
    }
    
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
