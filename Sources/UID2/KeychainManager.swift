//
//  KeychainManager.swift
//

import Foundation
import Security

/// Securely manages data in the Keychain
actor KeychainManager {

    private let attrAccount = "uid2"

    private static let attrService = "auth-state"

    func getIdentityFromKeychain() -> IdentityPackage? {
        let query = query(with: [
            String(kSecReturnData): true
        ])

        var result: AnyObject?
        SecItemCopyMatching(query, &result)

        if let data = result as? Data {
            return IdentityPackage.fromData(data)
        }
        
        return nil
    }
    
    @discardableResult
    func saveIdentityToKeychain(_ identityPackage: IdentityPackage) -> Bool {
        
        guard let data = try? identityPackage.toData() else {
            return false
        }

        if let _ = getIdentityFromKeychain() {
            let query = query()

            let attributesToUpdate = [String(kSecValueData): data] as CFDictionary

            let result = SecItemUpdate(query, attributesToUpdate)
            return result == errSecSuccess
        } else {
            let query = query(with: [
                String(kSecUseDataProtectionKeychain): true,
                String(kSecValueData): data
            ])

            let result = SecItemAdd(query, nil)
            return result == errSecSuccess
        }
    }
    
    @discardableResult
    func deleteIdentityFromKeychain() -> Bool {
        let status: OSStatus = SecItemDelete(query())

        return status == errSecSuccess
    }
    
    private func query() -> CFDictionary {
        query(with: [:])
    }

    private func query(with queryElements: [String: Any]) -> CFDictionary {
        let commonElements = [
            String(kSecClass): kSecClassGenericPassword,
            String(kSecAttrAccount): attrAccount,
            String(kSecAttrService): Self.attrService
        ] as [String: Any]

        // Merge, preferring values from `commonElements`
        return commonElements.merging(queryElements) { common, _ in common } as CFDictionary
    }
}
