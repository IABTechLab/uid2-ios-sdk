//
//  RefreshTokenResponse.swift
//  
//
//  Created by Brad Leege on 1/31/23.
//

import Foundation

/// API Response for https://github.com/IABTechLab/uid2docs/blob/main/api/v2/endpoints/post-token-refresh.md#decrypted-json-response-format

struct RefreshTokenResponse: Codable {
    
    let body: RefreshTokenResponseBody?
    let status: UID2Token.Status
    let message: String?
    
}

extension RefreshTokenResponse {
    
    struct RefreshTokenResponseBody: Codable {
        public let advertisingToken: String
        public let refreshToken: String
        public let identityExpires: TimeInterval
        public let refreshFrom: TimeInterval
        public let refreshExpires: TimeInterval
        public let refreshResponseKey: String
    }
    
}

extension RefreshTokenResponse {
    
    func toUID2Token() -> UID2Token? {
                
        if status != UID2Token.Status.success && status != UID2Token.Status.optOut {
            return nil
        }
                
        return UID2Token(advertisingToken: body?.advertisingToken,
                         refreshToken: body?.refreshToken,
                         identityExpires: body?.identityExpires,
                         refreshFrom: body?.refreshFrom,
                         refreshExpires: body?.refreshExpires,
                         refreshResponseKey: body?.refreshResponseKey,
                         status: status)
    }
    
}
