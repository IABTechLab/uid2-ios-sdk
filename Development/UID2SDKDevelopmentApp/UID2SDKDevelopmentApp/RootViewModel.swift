//
//  RootViewModel.swift
//  UID2SDKDevelopmentApp
//
//  Created by Brad Leege on 1/30/23.
//

import Combine
import Foundation
import SwiftUI
import UID2

@MainActor
class RootViewModel: ObservableObject {
    
    @Published private(set) var titleText = LocalizedStringKey("common.uid2sdk")
    @Published private(set) var uid2Identity: UID2Identity?
    @Published private(set) var error: Error?
    @Published private(set) var userOptedOut = ""
    @Published private(set) var identityPackageExpired = ""
    @Published private(set) var refreshTokenExpired = ""
    @Published private(set) var refreshSucceeded = ""
    
    private let apiClient = AppUID2Client()
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        UID2Manager.shared.$identity
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] uid2Identity in
                self?.uid2Identity = uid2Identity
            }).store(in: &cancellables)
        
    }
    
    var advertisingToken: String {
        if let token = uid2Identity?.advertisingToken {
            return token
        }
        return NSLocalizedString("common.nil", comment: "")
    }
    
    var refreshToken: String {
        if let token = uid2Identity?.refreshToken {
            return token
        }
        return NSLocalizedString("common.nil", comment: "")
    }
    
    var identityExpires: String {
        if let token = uid2Identity?.identityExpires {
            return String(format: "%.0f", token)
        }
        return NSLocalizedString("common.nil", comment: "")
    }
    
    var refreshFrom: String {
        if let token = uid2Identity?.refreshFrom {
            return String(format: "%.0f", token)
        }
        return NSLocalizedString("common.nil", comment: "")
    }
    
    var refreshExpires: String {
        if let token = uid2Identity?.refreshExpires {
            return String(format: "%.0f", token)
        }
        return NSLocalizedString("common.nil", comment: "")
    }
    
    var refreshResponseKey: String {
        if let token = uid2Identity?.refreshResponseKey {
            return token
        }
        return NSLocalizedString("common.nil", comment: "")
    }

    // MARK: - UX Handling Functions
    
    func handleEmailEntry(_ emailAddress: String) {
        apiClient.generateIdentity(requestString: emailAddress, requestType: .email) { [weak self] result in
            switch result {
            case .success(let identityPackage):
                guard let identityPackage = identityPackage else {
                    return
                }
                UID2Manager.shared.setIdentity(identityPackage)
                DispatchQueue.main.async {
                    self?.error = nil
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.error = error
                }
            }
        }
    }
 
    func handleResetButton() {
        UID2Manager.shared.resetIdentity()
        self.error = nil
    }
    
    func handleRefreshButton() {
        UID2Manager.shared.refreshIdentity()
    }
}
