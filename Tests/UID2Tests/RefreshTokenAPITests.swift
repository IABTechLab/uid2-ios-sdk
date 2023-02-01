//
//  RefreshTokenAPITests.swift
//  
//
//  Created by Brad Leege on 2/1/23.
//

import XCTest
@testable import UID2

final class RefreshTokenAPITests: XCTestCase {

    /// 🟩  `POST /v2/token/refresh` - HTTP 200 - Success
    /// uid2-iOS-sdk@test.com
    func testRefreshTokenSuccess() async throws {
     
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        // Load Generate Token
        let generateData = try DataLoader.load(fileName: "generate-token-200", fileExtension: "json")
        print("generateData = " + String(decoding: generateData, as: UTF8.self))
        let generateTokenResponse = try decoder.decode(RefreshTokenResponse.self, from: generateData)
        guard let generateToken = generateTokenResponse.toUID2Token() else {
            throw "Unable to create generateToken"
        }

        // Load UID2Client Mocked
        let client = UID2Client(uid2APIURL: "", MockNetworkSession("refresh-token-200-success-encrypted", "txt"))

        // Call RefreshToken using refreshToken and refreshResponseKey from Step 1 to decrypt
        let refreshToken = try await client.refreshUID2Token(refreshToken: generateToken.refreshToken, refreshResponseKey: generateToken.refreshResponseKey)

        // Load Local RefreshToken from JSON
        let localRefreshData = try  DataLoader.load(fileName: "refresh-token-200-success-decrypted", fileExtension: "json")
        let localTokenResponse = try decoder.decode(RefreshTokenResponse.self, from: localRefreshData)
        guard let localRefreshToken = localTokenResponse.toUID2Token() else {
            throw "Unable to create localRefreshToken"
        }

        XCTAssertEqual(refreshToken.advertisingToken, localRefreshToken.advertisingToken)
        XCTAssertEqual(refreshToken.refreshToken, localRefreshToken.refreshToken)
        XCTAssertEqual(refreshToken.identityExpires, localRefreshToken.identityExpires)
        XCTAssertEqual(refreshToken.refreshFrom, localRefreshToken.refreshFrom)
        XCTAssertEqual(refreshToken.refreshExpires, localRefreshToken.refreshExpires)
        XCTAssertEqual(refreshToken.refreshResponseKey, localRefreshToken.refreshResponseKey)
        
    }
    
}
