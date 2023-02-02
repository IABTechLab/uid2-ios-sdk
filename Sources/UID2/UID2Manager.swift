//
//  OpenPassManager.swift
//  
//
//  Created by Brad Leege on 1/20/23.
//

import Foundation

@available(iOS 13.0, *)
@MainActor
public final class UID2Manager {
    
    /// Singleton access point for UID2Manager
    public static let shared = UID2Manager()
    
    /// Current UID2 Token Data
    public private(set) var uid2Token: UID2Token?
    
    /// UID2Client for Network API  requests
    private let uid2Client: UID2Client
            
    /// Default UID2 Server URL
    /// Override default by setting `UID2ApiUrl` in app's Info.plist
    /// https://github.com/IABTechLab/uid2docs/tree/main/api/v2#environments
    private let defaultUid2ApiUrl = "https://prod.uidapi.com"
    
    private init() {
        
        var apiUrl = defaultUid2ApiUrl
        if let apiUrlOverride = Bundle.main.object(forInfoDictionaryKey: "UID2ApiUrl") as? String, !apiUrlOverride.isEmpty {
            apiUrl = apiUrlOverride
        }
        
        uid2Client = UID2Client(uid2APIURL: apiUrl)
    }
    
}
