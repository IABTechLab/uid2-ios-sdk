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
