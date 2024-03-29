//
//  UID2Client.swift
//  
//
//  Created by Brad Leege on 1/31/23.
//

import Foundation

@available(iOS 13.0, *)
internal final class UID2Client {
    
    private let uid2APIURL: String
    private let clientVersion: String
    private let session: NetworkSession
    
    init(uid2APIURL: String, sdkVersion: String, _ session: NetworkSession = URLSession.shared) {
        self.uid2APIURL = uid2APIURL
        self.clientVersion = "ios-\(sdkVersion)"
        self.session = session
    }
    
    func refreshIdentity(refreshToken: String, refreshResponseKey: String) async throws -> RefreshAPIPackage {
            
            var components = URLComponents(string: uid2APIURL)
            components?.path = "/v2/token/refresh"
            
            guard let urlPath = components?.url?.absoluteString,
                  let url = URL(string: urlPath) else {
                throw UID2Error.urlGeneration
            }
                        
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue(clientVersion, forHTTPHeaderField: "X-UID2-Client-Version")
            request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpBody = refreshToken.data(using: .utf8)
            
            let dataResponse = try await session.loadData(for: request)
            let data = dataResponse.0
            let statusCode = dataResponse.1
        
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
        
            // Only Decrypt If HTTP Status is 200 (Success or Opt Out)
            if statusCode != 200 {
                do {
                    let tokenResponse = try decoder.decode(RefreshTokenResponse.self, from: data)
                    throw UID2Error.refreshTokenServer(status: tokenResponse.status, message: tokenResponse.message)
                } catch {
                    throw UID2Error.refreshTokenServerDecoding(httpStatus: statusCode, message: error.localizedDescription)
                }
            }
        
            // Decrypt Data Envelop
            // https://github.com/UnifiedID2/uid2docs/blob/main/api/v2/encryption-decryption.md
            guard let payloadData = DataEnvelope.decrypt(refreshResponseKey, data, true) else {
                throw UID2Error.decryptPayloadData
            }
        
            let tokenResponse = try decoder.decode(RefreshTokenResponse.self, from: payloadData)
        
            guard let refreshAPIPackage = tokenResponse.toRefreshAPIPackage() else {
                throw UID2Error.refreshResponseToRefreshAPIPackage
            }
                        
            return refreshAPIPackage
        }
    
}
