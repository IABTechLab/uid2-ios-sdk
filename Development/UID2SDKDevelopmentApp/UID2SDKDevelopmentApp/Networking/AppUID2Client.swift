//
//  AppUID2Client.swift
//  UID2SDKDevelopmentApp
//
//  Created by Brad Leege on 2/6/23.
//

import CryptoKit
import Foundation
import Security
import UID2

internal final class AppUID2Client: Sendable {

    enum RequestTypes: String, CaseIterable {
        case email = "email"
        case emailHash = "email_hash"
        case phone = "phone"
        case phoneHash = "phone_hash"
    }
    
    private let uid2APIURL: String
    private let serverCredentials: UID2ServerCredentials?

    init() {
        
        var apiUrl = "https://operator-integ.uidapi.com"
        if let apiUrlOverride = Bundle.main.object(forInfoDictionaryKey: "UID2ApiUrl") as? String, !apiUrlOverride.isEmpty {
            apiUrl = apiUrlOverride
        }
        self.uid2APIURL = apiUrl
        
        // Load UID2 Server Credentials
        guard let filePath = Bundle(for: type(of: self)).path(forResource: "UID2ServerCredentials", ofType: "json") else {
            print("Error finding UIDV2Credentials file.  Returning early.")
            serverCredentials = nil
            return
        }
        do {
            let dataString = try String(contentsOfFile: filePath)
            let data = Data(dataString.utf8)
            let decoder = JSONDecoder()
            serverCredentials = try decoder.decode(UID2ServerCredentials.self, from: data)
        } catch {
            print("Error loading UID2V2Credentials: \(error)")
            serverCredentials = nil
        }

    }
    
    /// Call the UID2 Server to generate a UID2 Token
    /// - Parameters:
    ///     - requestString: String to be used for generating a UID2 Token
    ///     - requestType: The type of request string date being used
    func generateIdentity(requestString: String, requestType: RequestTypes) async throws -> UID2Identity? {
        let json: [String: String] = [requestType.rawValue: requestString]
        
        let fullUrl = uid2APIURL + "/v2/token/generate"
        
        let url = URL(string: fullUrl)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("text/plain", forHTTPHeaderField: "Content-Type")
        guard let key = serverCredentials?.key, let secret = serverCredentials?.secret else {
            return nil
        }
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")

        // Encrypt Data Envelope
        // https://github.com/UnifiedID2/uid2docs/blob/main/api/v2/encryption-decryption.md
        let encryptedRequest = encryptRequest(secret, json)
        request.httpBody = encryptedRequest
        let data: Data
        do {
            let result = try await URLSession.shared.data(for: request)
            data = result.0
        } catch {
            throw UID2ClientError()
        }

        // Decrypt Data Envelop
        // https://github.com/UnifiedID2/uid2docs/blob/main/api/v2/encryption-decryption.md
        guard let payloadData = decryptResponse(secret, data) else {
            throw UID2ClientError()
        }

        do {
            // Decode from JSON
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            let responseJSON = try decoder.decode(GenerateTokenResponse.self, from: payloadData)

            if responseJSON.status == "success" {

                guard let body = responseJSON.body else {
                    throw UID2ClientError()
                }

                return UID2Identity(
                    advertisingToken: body.advertisingToken,
                    refreshToken: body.refreshToken,
                    identityExpires: body.identityExpires,
                    refreshFrom: body.refreshFrom,
                    refreshExpires: body.refreshExpires,
                    refreshResponseKey: body.refreshResponseKey
                )
            } else {
                throw UID2ClientError()
            }
        } catch {
            throw UID2ClientError()
        }
    }
    
    func encryptRequest(_ b64Secret: String, _ bodyDictionary: [String: String]) -> Data? {

        guard let nonce: Data = generateRandomBytes(8) else {
            return nil
        }
        
        let milliseconds = Int64((Date().timeIntervalSince1970 * 1000.0).rounded())
        let timeSinceByteArray = withUnsafeBytes(of: milliseconds.bigEndian) { Data($0) }

        // Wrap the request JSON in an Unencrypted Request Data Envelope.
        var body = Data()
        body.append(timeSinceByteArray)
        body.append(nonce)

        let encoder = JSONEncoder()
        guard let payload = try? encoder.encode(bodyDictionary) else {
            return nil
        }
        guard let json = String(data: payload, encoding: .ascii) else {
            return nil
        }
        let fullJson = json + "\n"
        guard let fullJsonData = fullJson.data(using: .utf8) else {
            return nil
        }
        body.append(fullJsonData)
        
        // Encrypt the envelope using AES/GCM/NoPadding algorithm and your secret key.
        // Create SharedSecret --> SymetricKey --> Encrypt
        guard let secretData = Data(base64Encoded: b64Secret) else {
            return nil
        }

        let key = SymmetricKey(data: secretData)
        var sealedBox: AES.GCM.SealedBox?
        do {
            // Uses 12 byte initialization vector by default
            sealedBox = try AES.GCM.seal(body, using: key)
        } catch {
            return nil
        }
        
        // Returns nonce, encrypted data, and tag
        guard let combined = sealedBox?.combined else {
            return nil
        }

        var encryptedEnvelope = Data()
        encryptedEnvelope.append(0x01)
        encryptedEnvelope.append(combined)
        
        // Convert to B64
        let b64EnvelopeData = encryptedEnvelope.base64EncodedData()

        return b64EnvelopeData
    }
    
    func decryptResponse(_ b64Secret: String, _ responseData: Data, _ isRefresh: Bool = false) -> Data? {
        
        // Confirm that responseData is Base64
        guard let base64String = String(data: responseData, encoding: .utf8),
              let decodedData = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters) else {
            return responseData
        }
        
        // Parse Reponse Envelope
        // https://github.com/UnifiedID2/uid2docs/blob/main/api/v2/encryption-decryption.md#encrypted-response-envelope

        // Decrypt Data
        guard let secretData = Data(base64Encoded: b64Secret) else {
            return nil
        }

        let key = SymmetricKey(data: secretData)
        var decryptedData: Data?
        do {
            // Both work
            let sealedBox = try AES.GCM.SealedBox(combined: decodedData)
            decryptedData = try AES.GCM.open(sealedBox, using: key)
        } catch {
            return nil
        }

        guard let decryptedData = decryptedData else {
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
        
        guard let _ = String(data: payload, encoding: .utf8) else {
            return nil
        }
        return payload
    }
 
    func generateRandomBytes(_ numberOfBytes: Int) -> Data? {

        var keyData = Data(count: numberOfBytes)
        let result = keyData.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, numberOfBytes, $0.baseAddress!)
        }
        if result == errSecSuccess {
            return keyData
        } else {
            return nil
        }
    }
    
}
