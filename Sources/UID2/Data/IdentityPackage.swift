//
//  IdentityPackage.swift
//
//  Created by Brad Leege on 9/13/22.
//

import Foundation

// Implementation of internal data, what JS SDK Refers to as `IdentityStatus`
// https://github.com/IABTechLab/uid2-web-integrations/blob/5a8295c47697cdb1fe36997bc2eb2e39ae143f8b/src/uid2Sdk.ts#L174-L186
// NOTE: JS SDK makes 2 references to `IdentityStatus`, the second being an enum with actual states defined
// https://github.com/IABTechLab/uid2-web-integrations/blob/5a8295c47697cdb1fe36997bc2eb2e39ae143f8b/src/Uid2InitCallbacks.ts#L12-L20
public struct IdentityPackage: Codable {

    public let valid: Bool
    public let errorMessage: String?
    public let identity: UID2Identity?
    public let status: IdentityStatus
    
}

/*
extension IdentityPackage {
    
    public enum Status: String, Codable {
        case success = "success"
        case optOut = "optout"
        case clientError = "client_error"
        case invalidToken = "invalid_token"
        case unauthorized = "unauthorized"
    }
    
}

extension IdentityPackage {
    
    func toData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return try encoder.encode(self)
    }
    
    static func fromData(_ data: Data) -> IdentityPackage? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try? decoder.decode(IdentityPackage.self, from: data)
    }

}

extension IdentityPackage {
    
    public func isIdentityPackageExpired() -> Bool {
        guard let identityExpires = identityExpires else {
            return false
        }
        
        let now = Date().timeIntervalSince1970
        return now > identityExpires
    }
    
    public func isRefreshTokenExpired() -> Bool {
        
        guard let refreshTokenExpires = refreshExpires else {
            return false
        }

        let now = Date().timeIntervalSince1970
        return now >= refreshTokenExpires
    }
    
}
*/
