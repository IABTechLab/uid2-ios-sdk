//
//  KeychainManager.swift
//

import Foundation
import Security

/// Securely manages data in the Keychain
internal actor KeychainManager {

    private let attrAccount = "uid2"
    
    private let attrService = "auth-state"
    
    public func getIdentityFromKeychain() -> IdentityPackage? {
        let query = [
            String(kSecClass): kSecClassGenericPassword,
            String(kSecAttrAccount): attrAccount,
            String(kSecAttrService): attrService,
            String(kSecReturnData): true
        ] as [String: Any] as CFDictionary
            
        var result: AnyObject?
        SecItemCopyMatching(query, &result)
            
        if let data = result as? Data {
            return IdentityPackage.fromData(data)
        }
        
        return nil
    }
    
    @discardableResult
    public func saveIdentityToKeychain(_ identityPackage: IdentityPackage) -> Bool {
        
        guard let data = try? identityPackage.toData() else {
            return false
        }

        if let _ = getIdentityFromKeychain() {
            let query = [
                String(kSecClass): kSecClassGenericPassword,
                String(kSecAttrService): attrService,
                String(kSecAttrAccount): attrAccount
            ] as [String: Any] as CFDictionary

            let attributesToUpdate = [String(kSecValueData): data] as CFDictionary

            let result = SecItemUpdate(query, attributesToUpdate)
            return result == errSecSuccess
        } else {
            let keychainItem: [String: Any] = [
                String(kSecClass): kSecClassGenericPassword,
                String(kSecAttrAccount): attrAccount,
                String(kSecAttrService): attrService,
                String(kSecUseDataProtectionKeychain): true,
                String(kSecValueData): data
            ]

            let result = SecItemAdd(keychainItem as CFDictionary, nil)
            return result == errSecSuccess
        }
    }
    
    @discardableResult
    public func deleteIdentityFromKeychain() -> Bool {
        
        let query: [String: Any] = [String(kSecClass): kSecClassGenericPassword,
                                    String(kSecAttrAccount): attrAccount,
                                    String(kSecAttrService): attrService]

        let status: OSStatus = SecItemDelete(query as CFDictionary)
        
        return status == errSecSuccess
    }
    
}
