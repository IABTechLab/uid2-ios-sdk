//
//  UID2Client.swift
//  
//
//  Created by Brad Leege on 1/31/23.
//

import CryptoKit
import Foundation

// https://forums.developer.apple.com/forums/thread/747816
#if swift(>=6.0)
    #warning("Reevaluate whether this @preconcurrency decoration is necessary.")
#endif
@preconcurrency import OSLog

@available(iOS 13, tvOS 13, *)
internal final class UID2Client: Sendable {
    private let clientVersion: String
    private let environment: Environment
    private let session: NetworkSession
    private let log: OSLog
    private var baseURL: URL { environment.endpoint }
    private let cryptoUtil: CryptoUtil

    init(
        sdkVersion: String,
        isLoggingEnabled: Bool = false,
        environment: Environment = .production,
        session: NetworkSession = URLSession.shared,
        cryptoUtil: CryptoUtil = .liveValue
    ) {
        #if os(tvOS)
        self.clientVersion = "tvos-\(sdkVersion)"
        #else
        self.clientVersion = "ios-\(sdkVersion)"
        #endif
        self.log = isLoggingEnabled
            ? .init(subsystem: "com.uid2", category: "UID2Client")
            : .disabled
        self.environment = environment
        self.session = session
        self.cryptoUtil = cryptoUtil
    }

    func refreshIdentity(refreshToken: String, refreshResponseKey: String) async throws -> RefreshAPIPackage {
        os_log("Refreshing identity", log: log, type: .debug)
        let request = Request.refresh(token: refreshToken)
        let (data, response) = try await execute(request)
        let statusCode = response.statusCode
        let decoder = JSONDecoder.apiDecoder()

        // Only Decrypt If HTTP Status is 200 (Success or Opt Out)
        if statusCode != 200 {
            os_log("Client details failure: %d", log: log, type: .error, statusCode)
            do {
                let tokenResponse = try decoder.decode(RefreshTokenResponse.self, from: data)
                throw UID2Error.refreshTokenServer(status: tokenResponse.status, message: tokenResponse.message)
            } catch {
                throw UID2Error.refreshTokenServerDecoding(httpStatus: statusCode, message: error.localizedDescription)
            }
        }
    
        // Decrypt Data Envelop
        // https://github.com/UnifiedID2/uid2docs/blob/main/api/v2/encryption-decryption.md
        guard let key = Data(base64Encoded: refreshResponseKey).map(SymmetricKey.init(data: )),
              let payloadData = DataEnvelope.decrypt(data, key: key) else {
            os_log("Error decrypting response from client details", log: log, type: .error)
            throw UID2Error.decryptPayloadData
        }
    
        let tokenResponse = try decoder.decode(RefreshTokenResponse.self, from: payloadData)
    
        guard let refreshAPIPackage = tokenResponse.toRefreshAPIPackage() else {
            os_log("Error parsing response from client details", log: log, type: .error)
            throw UID2Error.refreshResponseToRefreshAPIPackage
        }
                    
        return refreshAPIPackage
    }

    func generateIdentity(
        _ identity: IdentityType,
        subscriptionID: String,
        serverPublicKey: String,
        appName: String
    ) async throws -> RefreshAPIPackage {
        // Parse server key and generate our keys
        let (symmetricKey, publicKey): (SymmetricKey, P256.KeyAgreement.PublicKey)
        do {
            (symmetricKey, publicKey) = try cryptoUtil.parseKey(serverPublicKey)
        } catch let error as TokenGenerationError {
            if case .configuration(let message) = error {
                os_log("Configuration error: %@", log: log, type: .error, message ?? "<none>")
            }
            throw error
        }
        let payload = ClientGeneratePayload(identity)
        let authenticatedDataPayload = AuthenticatedData(appName: appName)

        // Encrypt Data Envelope
        let encoder = JSONEncoder.apiEncoder()
        let payloadData = try encoder.encode(payload)

        let authenticatedData = try encoder.encode(authenticatedDataPayload)
        let sealedBox = try cryptoUtil.encrypt(
            payloadData,
            symmetricKey,
            authenticatedData
        )

        let request = try Request.clientGenerate(
            payload: sealedBox.ciphertext + sealedBox.tag,
            initializationVector: Data(sealedBox.nonce),
            publicKey: publicKey,
            subscriptionID: subscriptionID,
            timestamp: authenticatedDataPayload.timestamp,
            appName: authenticatedDataPayload.appName
        )
        let (data, response) = try await execute(request)
        let decoder = JSONDecoder.apiDecoder()
        guard response.statusCode == 200 else {
            let statusCode = response.statusCode
            let responseText = String(data: data, encoding: .utf8) ?? "<none>"
            os_log("Request failure (%d) %@", log: log, type: .error, statusCode, responseText)
            if environment != .production {
                os_log("Failed request is using non-production API endpoint %@, is this intentional?", log: log, type: .error, baseURL.description)
            }
            throw TokenGenerationError.requestFailure(
                httpStatusCode: statusCode,
                response: responseText
            )
        }
        guard let decryptedData = DataEnvelope.decrypt(data, key: symmetricKey) else {
            os_log("Decryption failure", log: log, type: .error)
            throw TokenGenerationError.decryptionFailure
        }

        guard
            let tokenResponse = try? decoder.decode(RefreshTokenResponse.self, from: decryptedData),
            let refreshAPIPackage = tokenResponse.toRefreshAPIPackage() else {
            os_log("Invalid response", log: log, type: .error)
            throw TokenGenerationError.invalidResponse
        }

        return refreshAPIPackage
    }

    // MARK: - Request Execution

    internal func urlRequest(
        _ request: Request
    ) -> URLRequest {
        var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)!
        urlComponents.path = request.path
        urlComponents.queryItems = request.queryItems.isEmpty ? nil : request.queryItems

        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.httpMethod = request.method.rawValue
        if request.method == .post {
            urlRequest.httpBody = request.body
        }

        request.headers.forEach { field, value in
            urlRequest.addValue(value, forHTTPHeaderField: field)
        }
        urlRequest.addValue(clientVersion, forHTTPHeaderField: "X-UID2-Client-Version")
        return urlRequest
    }

    private func execute(_ request: Request) async throws -> (Data, HTTPURLResponse) {
        let urlRequest = urlRequest(
            request
        )
        return try await session.loadData(for: urlRequest)
    }
}

struct AuthenticatedData {
    var timestamp: Int
    var appName: String
}

extension AuthenticatedData {
    init(date: Date = .init(), appName: String) {
        self.init(
            timestamp: Int(date.timeIntervalSince1970) * 1000,
            appName: appName
        )
    }
}

extension AuthenticatedData: Encodable {
    func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(timestamp)
        try container.encode(appName)
    }
}
