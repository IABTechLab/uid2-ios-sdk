//
//  PublicKey+Extensions.swift
//
//
//  Created by Dave Snabel-Caunt on 19/04/2024.
//

import CryptoKit
import Foundation
import SwiftASN1
import X509

extension P256.KeyAgreement.PublicKey {
    // CryptoKit's implementation is only available in iOS 14
    var derRepresentation: Data {
        get throws {
            // Signing and KeyAgreement keys are just keys – `but swift-certificates` only supports
            // encoding a `P256.Signing.PublicKey`. Convert the key type, and encode.
            let signingKey = try P256.Signing.PublicKey(rawRepresentation: self.rawRepresentation)
            let publicKey = Certificate.PublicKey(signingKey)
            var serializer = DER.Serializer()
            try serializer.serialize(publicKey)
            return Data(serializer.serializedBytes)
        }
    }
}
