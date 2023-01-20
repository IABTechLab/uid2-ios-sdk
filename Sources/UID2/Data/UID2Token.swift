//
//  UID2Token.swift
//
//  Created by Brad Leege on 9/13/22.
//

import Foundation

struct UID2Token: Codable {
    let advertisingToken: String
    let refreshToken: String
    let identityExpires: TimeInterval
    let refreshFrom: TimeInterval
    let refreshExpires: TimeInterval
    let refreshResponseKey: String
}
