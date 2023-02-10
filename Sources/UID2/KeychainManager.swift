//
//  KeychainManager.swift
//

import Foundation
import Security

/// Securely manages data in the Keychain
@available(iOS 13.0, *)
internal final class KeychainManager {
    
    /// Singleton access point for KeychainManager
    public static let shared = KeychainManager()

    private let attrAccount = "uid2"
    
    private let attrService = "auth-state"
    
    private init() { }
    
    public func getIdentityFromKeychain() -> UID2Identity? {
        let query = [
            String(kSecClass): kSecClassGenericPassword,
            String(kSecAttrAccount): attrAccount,
            String(kSecAttrService): attrService,
            String(kSecReturnData): true
        ] as CFDictionary
            
        var result: AnyObject?
        SecItemCopyMatching(query, &result)
            
        if let data = result as? Data {
            return UID2Identity.fromData(data)
        }
        
        return nil
    }
    
    @discardableResult
    public func saveIdentityToKeychain(_ identity: UID2Identity) -> Bool {
        
        do {
            let data = try identity.toData()

            if let _ = getIdentityFromKeychain() {
                
                let query = [
                    String(kSecClass): kSecClassGenericPassword,
                    String(kSecAttrService): attrService,
                    String(kSecAttrAccount): attrAccount
                ] as CFDictionary
                
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
        } catch {
            // Fall through to return false
        }

        return false
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
