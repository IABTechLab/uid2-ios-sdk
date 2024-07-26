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
struct IdentityPackage: Hashable, Sendable {
    
    let valid: Bool
    let errorMessage: String?
    let identity: UID2Identity?
    let status: IdentityStatus
}

extension IdentityPackage: Codable {
    
    enum CodingKeys: String, CodingKey {
        case valid, errorMessage, identity, status
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Automatic
        self.errorMessage = try container.decode(String?.self, forKey: .errorMessage)
        self.identity = try container.decode(UID2Identity?.self, forKey: .identity)
        
        // Manual Translation From Foundational Types
        let validRaw = try container.decode(Int.self, forKey: .valid)
        let validReal: Bool = validRaw == 1
        self.valid = validReal
        
        let statusRaw = try container.decode(Int.self, forKey: .status)
        if let realStatus = IdentityStatus(rawValue: statusRaw) {
            self.status = realStatus
        } else {
            self.status = .invalid
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Automatic
        try container.encode(errorMessage, forKey: .errorMessage)
        try container.encode(identity, forKey: .identity)
        
        // Manual Translation To Foundational Types
        let validRaw: Int = valid == true ? 1 : 0
        try container.encode(validRaw, forKey: .valid)
        
        let statusRaw = status.rawValue
        try container.encode(statusRaw, forKey: .status)
    }
    
}

extension IdentityPackage {
    
    static func fromData(_ data: Data) -> IdentityPackage? {
        let decoder = JSONDecoder.apiDecoder()
        return try? decoder.decode(IdentityPackage.self, from: data)
    }

    func toData() throws -> Data {
        let encoder = JSONEncoder.apiEncoder()
        return try encoder.encode(self)
    }

}
