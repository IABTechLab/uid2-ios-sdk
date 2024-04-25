//
//  Environment.swift
//
//
//  Created by Dave Snabel-Caunt on 24/04/2024.
//

import Foundation

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
        Self.init(endpoint: url)
    }
}
