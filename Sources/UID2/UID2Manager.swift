//
//  OpenPassManager.swift
//  
//
//  Created by Brad Leege on 1/20/23.
//

import Foundation

@available(iOS 13.0, *)
final class UID2Manager {
    
    public static let shared = UID2Manager()
    
    public var uid2Token: UID2Token?
    
    private init() {}
    
}
