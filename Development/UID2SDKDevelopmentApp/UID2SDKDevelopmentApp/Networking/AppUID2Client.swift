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

@available(iOS 13.0, *)
internal final class AppUID2Client {
    
    enum RequestTypes: String, CaseIterable {
        case email = "email"
        case emailHash = "email_hash"
        case phone = "phone"
        case phoneHash = "phone_hash"
    }
    
    private let uid2APIURL: String
    private var serverCredentials: UID2ServerCredentials?
    
    init() {
        
        var apiUrl = "https://operator-integ.uidapi.com"
        if let apiUrlOverride = Bundle.main.object(forInfoDictionaryKey: "UID2ApiUrl") as? String, !apiUrlOverride.isEmpty {
            apiUrl = apiUrlOverride
        }
        self.uid2APIURL = apiUrl
        
        // Load UID2 Server Credentials
        guard let filePath = Bundle(for: type(of: self)).path(forResource: "UID2ServerCredentials", ofType: "json") else {
            print("Error finding UIDV2Credentials file.  Returning early.")
            return
        }
        do {
            let dataString = try String(contentsOfFile: filePath)
            let data = Data(dataString.utf8)
            let decoder = JSONDecoder()
            serverCredentials = try decoder.decode(UID2ServerCredentials.self, from: data)
        } catch {
            print("Error loading UID2V2Credentials: \(error)")
        }

    }
    
    /// Call the UID2 Server to generate a UID2 Token
    /// - Parameters:
    ///     - requestString: String to be used for generating a UID2 Token
    ///     - requestType: The type of request string date being used
    func generateUID2Token(requestString: String, requestType: RequestTypes, completion:@escaping (Result<UID2Token?, Error>) -> Void) {
        
        print("generateUID2Token() with requestString = \(requestString) and requestType = \(requestType.rawValue)")
                
        let json: [String: String] = [requestType.rawValue: requestString]
        
        let fullUrl = uid2APIURL + "/v2/token/generate"
        print("fullURL = \(fullUrl)")
        
        let url = URL(string: fullUrl)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("text/plain", forHTTPHeaderField: "Content-Type")
        guard let key = serverCredentials?.key, let secret = serverCredentials?.secret else {
            print("Server Credentials was not found so request will fail and be handled by error handling system.")
            return
        }
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")

        // Encrypt Data Envelope
        // https://github.com/UnifiedID2/uid2docs/blob/main/api/v2/encryption-decryption.md
        let encryptedRequest = encryptRequest(secret, json)
        request.httpBody = encryptedRequest

        let task = URLSession.shared.dataTask(with: request, completionHandler: { [weak self] data, response, error in
            
            if let error = error {
                print("Error generating UID2 Token = \(error)")
                completion(.failure(UID2ClientError()))
                return
            }
            
            guard let data = data else {
                print("No data returned.")
                completion(.failure(UID2ClientError()))
                return
            }
            
            // Decrypt Data Envelop
            // https://github.com/UnifiedID2/uid2docs/blob/main/api/v2/encryption-decryption.md
            guard let payloadData = self?.decryptResponse(secret, data) else {
                print("Unable to to get a decrypted response")
                completion(.failure(UID2ClientError()))
                return
            }
            
            do {
                // Decode from JSON
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                let responseJSON = try decoder.decode(GenerateTokenResponse.self, from: payloadData)
                print("JSON returned from Generate UID2 Token = \(responseJSON)")
                
                if responseJSON.status == "success" {
                    
                    let uid2Token = UID2Token(advertisingToken: responseJSON.body?.advertisingToken,
                                        refreshToken: responseJSON.body?.refreshToken,
                                        identityExpires: responseJSON.body?.identityExpires,
                                        refreshFrom: responseJSON.body?.refreshFrom,
                                        refreshExpires: responseJSON.body?.refreshExpires,
                                        refreshResponseKey: responseJSON.body?.refreshResponseKey,
                                        status: .success)
                    completion(.success(uid2Token))
                } else {
                    completion(.failure(UID2ClientError()))
                }
            } catch {
                print("Error deserializing server response: \(error)")
                completion(.failure(error))
            }

        })
        
        task.resume()
    }
    
    func encryptRequest(_ b64Secret: String, _ bodyDictionary: [String: String]) -> Data? {

        print("============== Encrypt Request ==============")

        guard let nonce: Data = generateRandomBytes(8) else {
            print("Unable to generate nonce")
            return nil
        }
        print("nonce = \(nonce) ; string = \(String(data: nonce, encoding: .utf8))")
        
        let milliseconds = Int64((Date().timeIntervalSince1970 * 1000.0).rounded())
        let timeSinceByteArray = withUnsafeBytes(of: milliseconds.bigEndian) { Data($0) }
        print("milliseconds = \(milliseconds)")
        print("timeSinceByteArray = \(timeSinceByteArray)")

        // Wrap the request JSON in an Unencrypted Request Data Envelope.
        var body = Data()
        print("body - 1: \(body)")
        body.append(timeSinceByteArray)
        print("body - 2: \(body)")
        body.append(nonce)
        print("body - 3: \(body)")

        let encoder = JSONEncoder()
        guard let payload = try? encoder.encode(bodyDictionary) else {
            print("Unable to encode payload data")
            return nil
        }
        guard let json = String(data: payload, encoding: .ascii) else {
            return nil
        }
        let fullJson = json + "\n"
        guard let fullJsonData = fullJson.data(using: .utf8) else {
            return nil
        }
        print("json ascii: \(String(describing: fullJson))")
        body.append(fullJsonData)
        print("body - 4: \(body)")
        
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
            print("Error encrypting: \(error)")
            return nil
        }
        
        // Returns nonce, encrypted data, and tag
        guard let combined = sealedBox?.combined else {
            print("No combined data")
            return nil
        }

        var encryptedEnvelope = Data()
        encryptedEnvelope.append(0x01)
        encryptedEnvelope.append(combined)
        
        // Convert to B64
        let b64Envelope = encryptedEnvelope.base64EncodedString()
        print("b64Envelope = \(b64Envelope)")
        let b64EnvelopeData = encryptedEnvelope.base64EncodedData()
        print("b64EnvelopeData = \(b64EnvelopeData)")

        return b64EnvelopeData
    }
 
    
    func decryptResponse(_ b64Secret: String, _ responseData: Data, _ isRefresh: Bool = false) -> Data? {

        print("============== Decrypt Response ==============")
        print("responseData as String = " + String(decoding: responseData, as: UTF8.self))
        
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

        // Parse Reponse Envelope
        // https://github.com/UnifiedID2/uid2docs/blob/main/api/v2/encryption-decryption.md#encrypted-response-envelope

/*
        // Explicit parsing is not needed as decodedData provides nonce, ciphertext, and tag by default
 
        let iv = decodedData.subdata(in: 0..<12)
        print("iv = \(iv); string = \(String(data: iv, encoding: .utf8))")
        let ciphertext = decodedData.subdata(in: 12..<decodedData.count - 16)
        print("ciphertext = \(ciphertext)")
        let tag = decodedData.subdata(in: decodedData.count - 16..<decodedData.count)
        print("tag = \(tag)")

        let sealedBox = try AES.GCM.SealedBox(nonce: AES.GCM.Nonce(data: iv), ciphertext: ciphertext, tag: tag)
 */
        
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
 
    func generateRandomBytes(_ numberOfBytes: Int) -> Data? {

        var keyData = Data(count: numberOfBytes)
        let result = keyData.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, numberOfBytes, $0.baseAddress!)
        }
        if result == errSecSuccess {
            return keyData
        } else {
            print("Problem generating random bytes")
            return nil
        }
    }
    
}

struct UID2ClientError: Error { }

struct UID2Data {
    var advertisingToken: String?
    var refreshToken: String?
    var identityExpires: TimeInterval?
    var refreshFrom: TimeInterval?
    var refreshExpires: TimeInterval?
    var refreshResponseKey: String?
}
