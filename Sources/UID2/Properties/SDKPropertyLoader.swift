//
//  SDKPropertyLoader.swift
//  
//
//  Created by Brad Leege on 3/15/23.
//

import Foundation

class SDKPropertyLoader {
    
    static func load() -> SDKProperties {

        guard let plistURL = Bundle.module.url(forResource: "sdk_properties", withExtension: "plist") else {
            return SDKProperties(UID2Version: "")
        }

        let decoder = PropertyListDecoder()

        guard let data = try? Data.init(contentsOf: plistURL),
              let preferences = try? decoder.decode(SDKProperties.self, from: data) else {
            return SDKProperties(UID2Version: "")
        }

        return preferences

    }
    
}
