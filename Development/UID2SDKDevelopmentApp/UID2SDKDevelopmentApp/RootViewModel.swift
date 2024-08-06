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
    
    /// `UID2Settings` must be configured prior to accessing the `UID2Manager` instance.
    /// Configuring them here makes it less likely that an access occurs before configuration.
    private let manager: UID2Manager = {
        UID2Settings.shared.isLoggingEnabled = true
        // Only the development app should use the integration environment.
        // If you have copied the dev app for testing, you probably want to use the default
        // environment, which is production.
        if Bundle.main.bundleIdentifier == "com.uid2.UID2SDKDevelopmentApp" {
            UID2Settings.shared.environment = .custom(url: URL(string: "https://operator-integ.uidapi.com")!)
        }

        return UID2Manager.shared
    }()

    init() {
        Task {
            for await state in await manager.stateValues() {
                self.uid2Identity = state?.identity
                self.identityStatus = state?.identityStatus
            }
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

    func onAppear() async {
        self.uid2Identity = await manager.state?.identity
        self.identityStatus = await manager.state?.identityStatus
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
                try await manager.generateIdentity(
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
                await manager.setIdentity(identity)
            } catch {
                self.error = error
            }
        }
    }

    func reset() {
        Task {
            await manager.resetIdentity()
        }
    }
    
    func refresh() {
        Task {
            await manager.refreshIdentity()
        }
    }
}
