//
//  ClientGenerate.swift
//
//
//  Created by Dave Snabel-Caunt on 11/04/2024.
//

import CryptoKit
import Foundation

extension Request {

    @available(iOS 13, tvOS 13, *)
    static func clientGenerate(
        payload: Data,
        initializationVector: Data,
        publicKey: P256.KeyAgreement.PublicKey,
        subscriptionID: String,
        timestamp: Int,
        appName: String
    ) throws -> Request {
        let requestBody = ClientGenerateRequestBody(
            payload: payload.base64EncodedString(),
            initializationVector: initializationVector.base64EncodedString(),
            publicKey: try publicKey.derRepresentation.base64EncodedString(),
            subscriptionID: subscriptionID,
            timestamp: timestamp,
            appName: appName
        )

        let encoder = JSONEncoder.apiEncoder()
        let body = try encoder.encode(requestBody)

        return .init(
            path: "/v2/token/client-generate",
            method: .post,
            body: body
        )
    }
}

struct ClientGeneratePayload: Encodable {
    var key: CodingKeys
    var value: String

    enum CodingKeys: CodingKey {
        case emailHash
        case phoneHash
        case optoutCheck
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(value, forKey: key)
        try container.encode(1, forKey: .optoutCheck)
    }
}

@available(iOS 13, tvOS 13, *)
extension ClientGeneratePayload {
    init(_ identity: IdentityType) {
        switch identity {
        case .email(let email):
            self.init(key: .emailHash, value: email.value.sha256hash().base64EncodedString())
        case .emailHash(let hash):
            self.init(key: .emailHash, value: hash)
        case .phone(let phone):
            self.init(key: .phoneHash, value: phone.value.sha256hash().base64EncodedString())
        case .phoneHash(let hash):
            self.init(key: .phoneHash, value: hash)
        }
    }
}

struct ClientGenerateRequestBody: Encodable {
    var payload: String
    var initializationVector: String
    var publicKey: String
    var subscriptionID: String
    var timestamp: Int
    var appName: String

    enum CodingKeys: String, CodingKey {
        case payload
        case initializationVector = "iv"
        case publicKey
        case subscriptionID
        case timestamp
        case appName
    }
}

@available(iOS 13, tvOS 13, *)
fileprivate extension String {
    func sha256hash() -> Data {
        let digest = SHA256.hash(data: Data(self.utf8))
        return Data(digest)
    }
}
