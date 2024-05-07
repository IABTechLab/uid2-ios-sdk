//
//  CryptoUtil.swift
//
//
//  Created by Dave Snabel-Caunt on 18/04/2024.
//

import CryptoKit
import Foundation
import SwiftASN1
import X509

struct CryptoUtil: Sendable {
    // Parses a server's public key and returns a newly generated public key and symmetric key.
    var parseKey: @Sendable (_ string: String) throws -> (SymmetricKey, P256.KeyAgreement.PublicKey)

    // Encrypts data using a symmetric key and authenticated data
    var encrypt: @Sendable (_ data: Data, _ key: SymmetricKey, _ authenticatedData: Data) throws -> AES.GCM.SealedBox
}

extension CryptoUtil {
    private static let serverPublicKeyPrefixLength = 9

    static var liveValue: Self {
        Self(
            parseKey: { str in
                let serverPublicKey = try publicKey(string: str)
                return try symmetricKey(serverPublicKey: serverPublicKey)
            },
            encrypt: { data, key, authenticatedData in
                return try AES.GCM.seal(data, using: key, authenticating: authenticatedData)
            }
        )
    }

    /// Public key from server string representation given to integrator
    private static func publicKey(string: String) throws -> P256.KeyAgreement.PublicKey {
        // Server public key is provided with a 9 byte prefix. The remainder is base64 encoded.
        let encodedKey = Data(string.utf8.dropFirst(serverPublicKeyPrefixLength))
        guard let decodedSPKI = Data(base64Encoded: encodedKey) else {
            throw TokenGenerationError.configuration(message: "Invalid server public key as base64")
        }

        do {
            let result = try DER.parse(Array(decodedSPKI))
            let publicKey = try Certificate.PublicKey(derEncoded: result)
            let privateKeyData = publicKey.subjectPublicKeyInfoBytes
            return try P256.KeyAgreement.PublicKey(x963Representation: privateKeyData)
        } catch {
            throw TokenGenerationError.configuration(message: "Invalid server public key representation")
        }
    }

    /// Generates client keys, and a symmetric key in agreement with the API server's public key.
    private static func symmetricKey(
        serverPublicKey: P256.KeyAgreement.PublicKey
    ) throws -> (SymmetricKey, P256.KeyAgreement.PublicKey) {
        // Generate our public/private key pair
        let privateKey = P256.KeyAgreement.PrivateKey()
        let secret = try privateKey.sharedSecretFromKeyAgreement(with: serverPublicKey)
        // Use secret as key
        let symmetricKey = secret.withUnsafeBytes(SymmetricKey.init(data:))
        return (symmetricKey, privateKey.publicKey)
    }
}
