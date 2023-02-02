//
//  DataEnvelope.swift
//  
//
//  Created by Brad Leege on 1/31/23.
//

import CryptoKit
import Foundation

internal final class DataEnvelope {
    
    static func decrypt(_ key: String, _ responseData: Data, _ isRefresh: Bool = false) -> Data? {

            // Confirm that responseData is Base64
            guard let base64String = String(data: responseData, encoding: .utf8),
                  let decodedData = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters) else {
                return responseData
            }
                        
            // Decrypt Data
            guard let secretData = Data(base64Encoded: key) else {
                return nil
            }

            let key = SymmetricKey(data: secretData)
            var decryptedData: Data?
            do {
                // Both work
                let sealedBox = try AES.GCM.SealedBox(combined: decodedData)
                decryptedData = try AES.GCM.open(sealedBox, using: key)
            } catch {
                // No Op
            }

            guard let decryptedData = decryptedData else {
                return nil
            }

            // Parse Unencrypted Response Data / Byte Slicing
            // https://github.com/UnifiedID2/uid2docs/blob/main/api/v2/encryption-decryption.md#unencrypted-response-data-envelope
            var payload = decryptedData
            if !isRefresh {
                payload = decryptedData.subdata(in: 16..<decryptedData.count)
            }
            
            return payload
        }
    
}
