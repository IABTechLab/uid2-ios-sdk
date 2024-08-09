//
//  UID2Settings.swift
//
//
//  Created by Dave Snabel-Caunt on 23/04/2024.
//

import Foundation

/// An interface for configuring `UID2Manager` behavior.
/// These settings must be configured before calling `UID2Manager.shared` as they are read when it is initialized.
/// Subsequent changes will be ignored.
public final class UID2Settings: @unchecked Sendable {

    // A simple synchronization queue.
    // We do not expect settings values to be modified frequently, or after SDK initialization.
    private let queue = DispatchQueue(label: "UID2Settings.sync")

    private var _isLoggingEnabled = false

    /// Enable OS logging. The default value is `false`.
    public var isLoggingEnabled: Bool {
        get {
            queue.sync {
                _isLoggingEnabled
            }
        }
        set {
            queue.sync {
                _isLoggingEnabled = newValue
            }
        }
    }

    private var _uid2Environment = UID2.Environment.production
    private var _euidEnvironment = EUID.Environment.production

    /// UID2 API endpoint environment. The default value is `.production`.
    @available(*, deprecated, renamed: "uid2Environment", message: "Use uid2Environment, or see also euid2Environment")
    public var environment: UID2.Environment {
        get {
            uid2Environment
        }
        set {
            uid2Environment = newValue
        }
    }

    /// UID2 API endpoint environment. The default value is `.production`.
    public var uid2Environment: UID2.Environment {
        get {
            queue.sync {
                _uid2Environment
            }
        }
        set {
            queue.sync {
                _uid2Environment = newValue
            }
        }
    }

    /// EUID API endpoint environment. The default value is `.production`.
    public var euidEnvironment: EUID.Environment {
        get {
            queue.sync {
                _euidEnvironment
            }
        }
        set {
            queue.sync {
                _euidEnvironment = newValue
            }
        }
    }

    public static let shared = UID2Settings()
}
