//
//  Storage.swift
//

import Foundation

struct Storage: Sendable {
    // Load an identity
    var loadIdentity: @Sendable () async -> (IdentityPackage?)

    // Store an identity
    var saveIdentity: @Sendable (_ identityPackage: IdentityPackage) async -> Void

    // Clear stored identity
    var clearIdentity: @Sendable () async -> Void
}
