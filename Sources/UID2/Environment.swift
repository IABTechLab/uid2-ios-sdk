//
//  Environment.swift
//
//
//  Created by Dave Snabel-Caunt on 24/04/2024.
//

import Foundation

/// Internal Environment representation
struct Environment: Hashable, Sendable {

    /// API base URL
    let endpoint: URL
    let isProduction: Bool
}

extension Environment {
    init(_ environment: UID2.Environment) {
        endpoint = environment.endpoint
        isProduction = (environment == .production)
    }

    init(_ environment: EUID.Environment) {
        endpoint = environment.endpoint
        isProduction = (environment == .production)
    }
}

// Namespaces
public enum EUID {}
public enum UID2 {}

extension UID2 {
    /// For more information, see https://unifiedid.com/docs/getting-started/gs-environments
    public struct Environment: Hashable, Sendable {

        /// API base URL
        var endpoint: URL

        /// Equivalent to `ohio`
        public static let production = ohio

        /// AWS US East (Ohio)
        public static let ohio = Self(endpoint: URL(string: "https://prod.uidapi.com")!)
        /// AWS US West (Oregon)
        public static let oregon = Self(endpoint: URL(string: "https://usw.prod.uidapi.com")!)
        /// AWS Asia Pacific (Singapore)
        public static let singapore = Self(endpoint: URL(string: "https://sg.prod.uidapi.com")!)
        /// AWS Asia Pacific (Sydney)
        public static let sydney = Self(endpoint: URL(string: "https://au.prod.uidapi.com")!)
        /// AWS Asia Pacific (Tokyo)
        public static let tokyo = Self(endpoint: URL(string: "https://jp.prod.uidapi.com")!)

        /// A custom endpoint
        public static func custom(url: URL) -> Self {
            Self(endpoint: url)
        }
    }
}

extension EUID {
    /// See https://euid.eu/docs/getting-started/gs-environments
    public struct Environment: Hashable, Sendable {

        /// API base URL
        var endpoint: URL

        /// Equivalent to `london`
        public static let production = london

        /// AWS EU West 2 (London)
        public static let london = Self(endpoint: URL(string: "https://prod.euid.eu/v2")!)

        /// A custom endpoint
        public static func custom(url: URL) -> Self {
            Self(endpoint: url)
        }
    }
}
