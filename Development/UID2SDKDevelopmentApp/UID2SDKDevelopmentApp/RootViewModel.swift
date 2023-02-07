//
//  RootViewModel.swift
//  UID2SDKDevelopmentApp
//
//  Created by Brad Leege on 1/30/23.
//

import Foundation
import SwiftUI
import UID2

@MainActor
class RootViewModel: ObservableObject {
    
    @Published private(set) var titleText = LocalizedStringKey("common.uid2sdk")
    @Published private(set) var uid2Token: UID2Token?
    @Published private(set) var error: Error?
    
    private let apiClient = AppUID2Client()
    
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

    func handleEmailEntry(_ emailAddress: String) {
        apiClient.generateUID2Token(requestString: emailAddress, requestType: .email) { [weak self] result in
            switch result {
            case .success(let uid2Token):
                guard let uid2Token = uid2Token else {
                    return
                }
                UID2Manager.shared.setUID2Token(uid2Token)
                self?.uid2Token = uid2Token
            case .failure(let error):
                self?.error = error
            }
        }
    }
    
}
