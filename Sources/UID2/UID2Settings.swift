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

    public static let shared = UID2Settings()
}
