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
    @Published private(set) var uid2Token: IdentityPackage?
    @Published private(set) var error: Error?
    
    private let apiClient = AppUID2Client()
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        UID2Manager.shared.$identityPackage
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] uid2Token in
                self?.uid2Token = uid2Token
            }).store(in: &cancellables)
    }
    
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
            return String(format: "%.0f", token)
        }
        return NSLocalizedString("common.nil", comment: "")
    }
    
    var refreshFrom: String {
        if let token = uid2Token?.refreshFrom {
            return String(format: "%.0f", token)
        }
        return NSLocalizedString("common.nil", comment: "")
    }
    
    var refreshExpires: String {
        if let token = uid2Token?.refreshExpires {
            return String(format: "%.0f", token)
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
        apiClient.generateIdentityPackage(requestString: emailAddress, requestType: .email) { [weak self] result in
            switch result {
            case .success(let identityPackage):
                guard let identityPackage = identityPackage else {
                    return
                }
                UID2Manager.shared.setIdentityPackage(identityPackage)
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.error = error
                }
            }
        }
    }
    
}
