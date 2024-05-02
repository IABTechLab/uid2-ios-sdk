//
//  IdentityType.swift
//  
//
//  Created by Dave Snabel-Caunt on 16/04/2024.
//

import Foundation

public enum IdentityType: Hashable, Sendable {
    case email(NormalizedEmail)
    case emailHash(String)
    case phone(NormalizedPhone)
    case phoneHash(String)
}

extension IdentityType {
    var value: String {
        switch self {
        case .email(let email):
            return email.value
        case .phone(let phone):
            return phone.value
        case .emailHash(let value),
            .phoneHash(let value):
            return value
        }
    }
}

extension IdentityType {

    /// https://unifiedid.com/docs/getting-started/gs-normalization-encoding#email-address-normalization
    public struct NormalizedEmail: Hashable, Sendable, CustomStringConvertible {

        public let value: String

        /// Creates a Normalized Email from a raw email string.
        public init?(string: String) {
            guard let normalized = Self.normalize(email: string) else {
                return nil
            }
            self.value = normalized
        }

        public var description: String {
            value
        }

        // Ported from the Android SDK to maintain the same behavior
        // https://github.com/IABTechLab/uid2-android-sdk
        // swiftlint:disable:next cyclomatic_complexity
        private static func normalize(email: String) -> String? {
            enum ParsingState {
                case starting
                case subDomain
            }

            var preSubDomain = ""
            var preSubDomainSpecialized = ""
            var subDomain = ""
            var subDomainWhiteSpace = ""

            var state = ParsingState.starting
            var inExtension = false

            let email = email.lowercased(with: .current)

            charLoop: for char in email {
                switch state {
                case .starting:
                    guard char != " " else {
                        continue charLoop
                    }
                    if char == "@" {
                        state = .subDomain
                    } else if char == "." {
                        preSubDomain.append(char)
                    } else if char == "+" {
                        preSubDomain.append(char)
                        inExtension = true
                    } else {
                        preSubDomain.append(char)
                        if !inExtension {
                            preSubDomainSpecialized.append(char)
                        }
                    }
                case .subDomain:
                    guard char != "@" else {
                        return nil
                    }

                    guard char != " " else {
                        subDomainWhiteSpace.append(char)
                        continue
                    }

                    if !subDomainWhiteSpace.isEmpty {
                        subDomain.append(subDomainWhiteSpace)
                        subDomainWhiteSpace = ""
                    }

                    subDomain.append(char)
                }
            }

            // Verify that we've parsed the subdomain correctly.
            guard !subDomain.isEmpty else {
                return nil
            }

            // Verify that we've parsed the address part correctly.
            let addressPartToUse: String
            if "gmail.com" == subDomain {
                addressPartToUse = preSubDomainSpecialized
            } else {
                addressPartToUse = preSubDomain
            }

            guard !addressPartToUse.isEmpty else {
                return nil
            }

            // Build the normalized version of the email address.
            return "\(addressPartToUse)@\(subDomain)"
        }
    }
}

extension IdentityType {

    /// https://unifiedid.com/docs/getting-started/gs-normalization-encoding#email-address-normalization
    public struct NormalizedPhone: Hashable, Sendable, CustomStringConvertible {

        public let value: String

        /// Creates a Normalized Phone value from a normalized phone string.
        /// Returns `nil` if `normalized` is not already normalized according to ITU E.164.
        public init?(normalized: String) {
            guard Self.isNormalized(phone: normalized) else {
                return nil
            }
            self.value = normalized
        }

        public var description: String {
            value
        }

        /// Returns true if the string is normalized according to ITU E.164 Standard (https://en.wikipedia.org/wiki/E.164).
        private static func isNormalized(phone: String) -> Bool {
            guard phone.first == "+" else {
                return false
            }

            let count = phone.count
            guard count >= 11 && count <= 16 else {
                return false
            }
            let firstIndex = phone.index(phone.startIndex, offsetBy: 1)
            let number = phone[firstIndex...]
            return number.allSatisfy { char in
                char >= "0" && char <= "9"
            }
        }
    }
}
