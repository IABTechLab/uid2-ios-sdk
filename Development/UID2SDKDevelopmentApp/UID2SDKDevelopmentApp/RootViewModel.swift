//
//  RootViewModel.swift
//  UID2SDKDevelopmentApp
//
//  Created by Brad Leege on 1/30/23.
//

import Foundation
import SwiftUI
import UID2

class RootViewModel: ObservableObject {
    
    @Published private(set) var titleText = LocalizedStringKey("common.uid2sdk")
    @Published private(set) var uid2Token: UID2Token?
    @Published private(set) var error: Error?
    
    var advertisingToken: String {
        if let token = uid2Token?.advertisingToken {
            return token
        }
        return NSLocalizedString("common.nil", comment: "")
    }
    
    var refreshToken: String {
        if let token = uid2Token?.refreshToken {
            return token
        }
        return NSLocalizedString("common.nil", comment: "")
    }
    
    var identityExpires: String {
        if let token = uid2Token?.identityExpires {
            return String(token)
        }
        return NSLocalizedString("common.nil", comment: "")
    }
    
    var refreshFrom: String {
        if let token = uid2Token?.refreshFrom {
            return String(token)
        }
        return NSLocalizedString("common.nil", comment: "")
    }
    
    var refreshExpires: String {
        if let token = uid2Token?.refreshExpires {
            return String(token)
        }
        return NSLocalizedString("common.nil", comment: "")
    }
    
    var refreshResponseKey: String {
        if let token = uid2Token?.refreshResponseKey {
            return token
        }
        return NSLocalizedString("common.nil", comment: "")
    }

}
