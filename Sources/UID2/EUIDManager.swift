//
//  EUIDManager.swift
//

import Foundation

@available(iOS 13, tvOS 13, *)
public final class EUIDManager {

    /// Singleton access point for EUID Manager
    /// Returns a manager configured for use with EUID.
    public static let shared: UID2Manager = {
        UID2Manager(
            environment: Environment(UID2Settings.shared.euidEnvironment),
            account: .euid
        )
    }()
}
