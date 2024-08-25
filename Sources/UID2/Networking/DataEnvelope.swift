//
//  DataEnvelope.swift
//  
//
//  Created by Brad Leege on 1/31/23.
//

import CryptoKit
import Foundation

@available(iOS 13, tvOS 13, *)
internal enum DataEnvelope {

    /// Decrypts raw response envelope data, which is expected to be a base64 encoded string.
    /// - Parameters:
    ///   - data: Encrypted data, in base64
    ///   - key: A SymmetricKey used for decryption
    ///   - includesNonce: Whether the encrypted data is prefixed by a 16 byte nonce
    /// - Returns: Decrypted data
    static func decrypt(_ data: Data, key: SymmetricKey, includesNonce: Bool = false) -> Data? {
        // Confirm that responseData is Base64
        guard let decodedData = Data(base64EncodedData: data, options: .ignoreUnknownCharacters) else {
            return nil
        }

        let decryptedData: Data
        do {
            // Both work
            let sealedBox = try AES.GCM.SealedBox(combined: decodedData)
            decryptedData = try AES.GCM.open(sealedBox, using: key)
        } catch {
            return nil
        }

        // Parse Unencrypted Response Data / Byte Slicing
        // https://unifiedid.com/docs/getting-started/gs-encryption-decryption#unencrypted-response-data-envelope
        if includesNonce {
            return decryptedData[16...]
        } else {
            return decryptedData
        }
    }
}

extension Data {
    /// A convenience initializer for converting from a Data representation of a base64 encoded string to its decoded Data.
    init?(base64EncodedData: Data, options: Data.Base64DecodingOptions = []) {
        // https://github.com/realm/SwiftLint/issues/5263#issuecomment-2115182747
        // swiftlint:disable:next non_optional_string_data_conversion
        guard let base64String = String(data: base64EncodedData, encoding: .utf8) else {
            return nil
        }
        self.init(base64Encoded: base64String, options: options)
    }
}
