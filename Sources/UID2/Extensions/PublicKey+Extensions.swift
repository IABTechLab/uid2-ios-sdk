//
//  PublicKey+Extensions.swift
//
//
//  Created by Dave Snabel-Caunt on 19/04/2024.
//

import CryptoKit
import Foundation
import SwiftASN1

@available(iOS 13, tvOS 13, *)
extension P256.KeyAgreement.PublicKey {
    // CryptoKit's implementation is only available in iOS 14
    var derRepresentation: Data {
        get throws {
            let spki = SubjectPublicKeyInfo(
                algorithmIdentifier: .p256PublicKey,
                key: ASN1BitString(bytes: ArraySlice(self.x963Representation))
            )
            var serializer = DER.Serializer()
            try serializer.serialize(spki)
            return Data(serializer.serializedBytes)
        }
    }
}
