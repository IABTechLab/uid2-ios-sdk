//
//  EUIDManager.swift
//

import Foundation

public final class EUIDManager {
    public static let shared: UID2Manager = {
        UID2Manager(
            environment: Environment(UID2Settings.shared.euidEnvironment),
            account: .euid
        )
    }()
}
