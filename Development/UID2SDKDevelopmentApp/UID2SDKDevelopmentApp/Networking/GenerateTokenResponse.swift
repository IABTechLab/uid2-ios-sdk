//
//  GenerateTokenResponse.swift
//  UID2SDKDevelopmentApp
//
//  Created by Brad Leege on 2/6/23.
//

import Foundation

struct GenerateTokenResponse: Codable {

    struct Body: Codable {
        var advertisingToken: String
        var refreshToken: String
        var identityExpires: TimeInterval
        var refreshFrom: TimeInterval
        var refreshExpires: TimeInterval
        var refreshResponseKey: String
    }
    
    // MARK: - Data
    var body: Body?
    var status: String
    var message: String?
}
