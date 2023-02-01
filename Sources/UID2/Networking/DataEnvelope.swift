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

            print("============== Decrypt Response ==============")
            // Confirm that responseData is Base64
            guard let base64String = String(data: responseData, encoding: .utf8),
                  let decodedData = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters) else {
                print("The responseData is NOT base64, so returning responseData as is")
                return responseData
            }
            
            print("base64String of responseData = \(base64String)")
            
            // Decode Base64 Response -- Opposite of B64 Request
            // Then turn that into Data for the byte slicing
            print("Base64 decodedData of responseData = \(decodedData)")
            
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
                print("Unable to decrypt the data: \(error)")
            }

            guard let decryptedData = decryptedData else {
                print("decryptedData was nil")
                return nil
            }

            // Parse Unencrypted Response Data / Byte Slicing
            // https://github.com/UnifiedID2/uid2docs/blob/main/api/v2/encryption-decryption.md#unencrypted-response-data-envelope
            var payload = decryptedData
            if !isRefresh {
                // Byte Slicing
    //            let timestamp = decryptedData.subdata(in: 0..<8)
    //            let nonce = decryptedData.subdata(in: 8..<16)
                payload = decryptedData.subdata(in: 16..<decryptedData.count)
            }
            
            guard let payloadString = String(data: payload, encoding: .utf8) else {
                print("Unable to generate payloadString")
                return nil
            }
            print("payloadString = \(payloadString)")
            return payload
        }
    
}
