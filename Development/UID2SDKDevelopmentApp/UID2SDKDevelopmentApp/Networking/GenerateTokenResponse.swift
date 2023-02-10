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
        var identityExpires: Int64
        var refreshFrom: Int64
        var refreshExpires: Int64
        var refreshResponseKey: String
    }
    
    // MARK: - Data
    var body: Body?
    var status: String
    var message: String?
}
