//
//  SDKProperties.swift
//  
//
//  Created by Brad Leege on 3/15/23.
//

import Foundation

struct SDKProperties: Codable {
    
    let uid2Version: String?
    
    enum CodingKeys: String, CodingKey {
        case uid2Version = "UID2Version"
    }
    
}
