//
//  IdentityStatus.swift
//  
//
//  Created by Brad Leege on 2/9/23.
//

import Foundation

// Implementation of Web SDK's `IdentityStatus`
// https://github.com/IABTechLab/uid2-web-integrations/blob/5a8295c47697cdb1fe36997bc2eb2e39ae143f8b/src/Uid2InitCallbacks.ts#L12-L20
// NOTE: Web SDK makes 2 references to `IdentityStatus`.  See iOS SDK `IdentityPackage` for more details.
public enum IdentityStatus: Int, CaseIterable, Sendable, Codable {
    
    case established = 0
    case refreshed = 1
    case expired = 100
    case noIdentity = -1
    case invalid = -2
    case refreshExpired = -3
    case optOut = -4
        
}

extension IdentityStatus: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .established:
            return "Established"
        case .refreshed:
            return "Refreshed"
        case .expired:
            return "Expired"
        case .noIdentity:
            return "No Identity"
        case .invalid:
            return "Invalid"
        case .refreshExpired:
            return "Refresh Expired"
        case .optOut:
            return "Opt Out"
        }
    }
    
}
