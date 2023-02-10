//
//  RefreshAPIPackage.swift
//  
//
//  Created by Brad Leege on 2/9/23.
//

import Foundation

struct RefreshAPIPackage: Codable {

    let identity: UID2Identity?
    let status: IdentityStatus
    let message: String?
    
}
