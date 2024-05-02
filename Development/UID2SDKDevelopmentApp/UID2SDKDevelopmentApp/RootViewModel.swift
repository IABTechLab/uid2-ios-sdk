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
    
    @Published private(set) var uid2Identity: UID2Identity? {
        didSet {
            error = nil
        }
    }
    @Published private(set) var identityStatus: IdentityStatus?
    @Published private(set) var error: Error?
    
    private let apiClient = AppUID2Client()
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        UID2Settings.shared.isLoggingEnabled = true
        
        Task {
            await UID2Manager.shared.$identity
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { [weak self] uid2Identity in
                    self?.uid2Identity = uid2Identity
                }).store(in: &cancellables)
         
            await UID2Manager.shared.$identityStatus
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { [weak self] identityStatus in
                    self?.identityStatus = identityStatus
                }).store(in: &cancellables)
        }
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
            return String(token)
        }
        return NSLocalizedString("common.nil", comment: "")
    }
    
    var refreshFrom: String {
        if let token = uid2Identity?.refreshFrom {
            return String(token)
        }
        return NSLocalizedString("common.nil", comment: "")
    }
    
    var refreshExpires: String {
        if let token = uid2Identity?.refreshExpires {
            return String(token)
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
    
    func handleEmailEntry(_ email: String, clientSide: Bool) {
        Task<Void, Never> {
            self.error = nil
            if clientSide {
                struct InvalidEmailError: Error, LocalizedError {
                    var errorDescription: String = "Invalid email address"
                }
                guard let normalizedEmail = IdentityType.NormalizedEmail(string: email) else {
                    error = InvalidEmailError()
                    return
                }
                clientSideGenerate(identity: .email(normalizedEmail))
            } else {
                generateIdentity(email, requestType: .email)
            }
        }
    }
 
    func handlePhoneEntry(_ phone: String, clientSide: Bool) {
        self.error = nil
        if clientSide {
            struct InvalidPhoneError: Error, LocalizedError {
                var errorDescription: String = "Phone number is not normalized"
            }
            guard let normalizedPhone = IdentityType.NormalizedPhone(normalized: phone) else {
                error = InvalidPhoneError()
                return
            }
            clientSideGenerate(identity: .phone(normalizedPhone))
        } else {
            generateIdentity(phone, requestType: .phone)
        }
    }

    func clientSideGenerate(identity: IdentityType) {
        let subscriptionID = "toPh8vgJgt"
        // swiftlint:disable:next line_length
        let serverPublicKeyString = "UID2-X-I-MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEKAbPfOz7u25g1fL6riU7p2eeqhjmpALPeYoyjvZmZ1xM2NM8UeOmDZmCIBnKyRZ97pz5bMCjrs38WM22O7LJuw=="
        
        Task<Void, Never> {
            do {
                try await UID2Manager.shared.generateIdentity(
                    identity,
                    subscriptionID: subscriptionID,
                    serverPublicKey: serverPublicKeyString,
                    appName: Bundle.main.bundleIdentifier!
                )
            } catch {
                self.error = error
            }
        }
    }

    func generateIdentity(_ identity: String, requestType: AppUID2Client.RequestTypes) {
        Task<Void, Never> {
            do {
                guard let identity = try await apiClient.generateIdentity(requestString: identity, requestType: requestType) else {
                    return
                }
                await UID2Manager.shared.setIdentity(identity)
            } catch {
                self.error = error
            }
        }
    }

    func reset() {
        Task {
            await UID2Manager.shared.resetIdentity()
        }
    }
    
    func refresh() {
        Task {
            await UID2Manager.shared.refreshIdentity()
        }
    }
}
