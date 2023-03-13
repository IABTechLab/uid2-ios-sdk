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
    let status: Status
    let message: String?
    
}

extension RefreshTokenResponse {
    
    struct RefreshTokenResponseBody: Codable {
        public let advertisingToken: String
        public let refreshToken: String
        public let identityExpires: Int64
        public let refreshFrom: Int64
        public let refreshExpires: Int64
        public let refreshResponseKey: String
    }
 
    enum Status: String, Codable {
        case success = "success"
        case optOut = "optout"
        case expiredToken = "expired_token"
        case clientError = "client_error"
        case invalidToken = "invalid_token"
        case unauthorized = "unauthorized"
    }

}

extension RefreshTokenResponse {
    
    public func toUID2Identity() -> UID2Identity? {
        guard let body = body else {
            return nil
        }
        
        return UID2Identity(advertisingToken: body.advertisingToken,
                            refreshToken: body.refreshToken,
                            identityExpires: body.identityExpires,
                            refreshFrom: body.refreshFrom,
                            refreshExpires: body.refreshExpires,
                            refreshResponseKey: body.refreshResponseKey)
    }
    
    public func toRefreshAPIPackage() -> RefreshAPIPackage? {
                                
        switch status {
        case .success:
            return RefreshAPIPackage(identity: toUID2Identity(), status: .refreshed, message: "Identity refreshed")
        case .optOut:
            return RefreshAPIPackage(identity: nil, status: .optOut, message: "User opted out")
        case .expiredToken:
            return RefreshAPIPackage(identity: nil, status: .refreshExpired, message: "Refresh token expired")
        default:
            return nil
        }
        
    }
    
}
