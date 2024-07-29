//
//  UID2Manager.State.swift
//

import Foundation

extension UID2Manager {
    public enum State: Hashable, Sendable, Codable {
        case optout
        case established(UID2Identity)
        case refreshed(UID2Identity)
        case expired(UID2Identity) // identity expired but can be refreshed
        case refreshExpired // identity and refresh expired
        case invalid
    }
}

extension UID2Manager.State {
    /// A 'case path' returning the current `IdentityStatus`.
    public var identityStatus: IdentityStatus {
        switch self {
        case .optout:
            return .optOut
        case .established:
            return .established
        case .refreshed:
            return .refreshed
        case .expired:
            return .expired
        case .refreshExpired:
            return .refreshExpired
        case .invalid:
            return .invalid
        }
    }

    /// A 'case path' returning the current `UID2Identity`.
    public var identity: UID2Identity? {
        switch self {
        case .optout,
             .refreshExpired,
             .invalid:
            return nil
        case .established(let identity),
             .refreshed(let identity),
             .expired(let identity):
            return identity
        }
    }
}

extension UID2Manager.State {
    init?(_ package: IdentityPackage) {
        switch package.status {
        case .established:
            if let identity = package.identity {
                self = .established(identity)
            } else {
                return nil
            }
        case .refreshed:
            if let identity = package.identity {
                self = .refreshed(identity)
            } else {
                return nil
            }
        case .expired:
            if let identity = package.identity {
                self = .expired(identity)
            } else {
                return nil
            }
        case .noIdentity:
            return nil
        case .invalid:
            self = .invalid
        case .refreshExpired:
            self = .refreshExpired
        case .optOut:
            self = .optout
        }
    }
}
