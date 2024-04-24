//
//  UID2Client.swift
//  
//
//  Created by Brad Leege on 1/31/23.
//

import Foundation

internal final class UID2Client {
    
    private let uid2APIURL: String
    private let clientVersion: String
    private let session: NetworkSession
    
    init(uid2APIURL: String, sdkVersion: String, _ session: NetworkSession = URLSession.shared) {
        self.uid2APIURL = uid2APIURL
        #if os(tvOS)
        self.clientVersion = "tvos-\(sdkVersion)"
        #else
        self.clientVersion = "ios-\(sdkVersion)"
        #endif
        self.session = session
    }
    
    func refreshIdentity(refreshToken: String, refreshResponseKey: String) async throws -> RefreshAPIPackage {
            
        let request = Request.refresh(token: refreshToken)
        let (data, statusCode) = try await execute(request)

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

    // MARK: - Request Execution

    internal func urlRequest(
        _ request: Request,
        baseURL: URL
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

    private func execute(_ request: Request) async throws -> (Data, Int) {
        let urlRequest = urlRequest(
            request,
            baseURL: URL(string: uid2APIURL)!
        )
        return try await session.loadData(for: urlRequest)
    }
}
