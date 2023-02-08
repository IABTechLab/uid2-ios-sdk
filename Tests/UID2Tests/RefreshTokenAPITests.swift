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
        let generateData = try DataLoader.load(fileName: "generate-token-200-success", fileExtension: "json")
        print("generateData = " + String(decoding: generateData, as: UTF8.self))
        let generateTokenResponse = try decoder.decode(RefreshTokenResponse.self, from: generateData)
        guard let generateToken = generateTokenResponse.toIdentityPackage() else {
            throw "Unable to create generateToken"
        }

        // Load UID2Client Mocked
        let client = UID2Client(uid2APIURL: "", MockNetworkSession("refresh-token-200-success-encrypted", "txt"))

        // Call RefreshToken using refreshToken and refreshResponseKey from Step 1 to decrypt
        let refreshToken = try await client.refreshIdentityPackage(refreshToken: generateToken.refreshToken ?? "",
                                                             refreshResponseKey: generateToken.refreshResponseKey ?? "")

        // Load Local RefreshToken from JSON
        let localRefreshData = try  DataLoader.load(fileName: "refresh-token-200-success-decrypted", fileExtension: "json")
        let localTokenResponse = try decoder.decode(RefreshTokenResponse.self, from: localRefreshData)
        guard let localRefreshToken = localTokenResponse.toIdentityPackage() else {
            throw "Unable to create localRefreshToken"
        }

        XCTAssertEqual(refreshToken.advertisingToken, localRefreshToken.advertisingToken)
        XCTAssertEqual(refreshToken.refreshToken, localRefreshToken.refreshToken)
        XCTAssertEqual(refreshToken.identityExpires, localRefreshToken.identityExpires)
        XCTAssertEqual(refreshToken.refreshFrom, localRefreshToken.refreshFrom)
        XCTAssertEqual(refreshToken.refreshExpires, localRefreshToken.refreshExpires)
        XCTAssertEqual(refreshToken.refreshResponseKey, localRefreshToken.refreshResponseKey)
        XCTAssertEqual(refreshToken.status, localRefreshToken.status)
        
    }

    /// 🟩  `POST /v2/token/refresh` - HTTP 200 - OptOut
    /// optout@email.com
    /// https://github.com/IABTechLab/uid2docs/blob/main/api/v2/endpoints/post-token-refresh.md#testing-notes
    func testRefreshTokenOptOut() async throws {
     
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        // Load Generate Token
        let generateData = try DataLoader.load(fileName: "generate-token-200-optout", fileExtension: "json")
        print("generateData = " + String(decoding: generateData, as: UTF8.self))
        let generateTokenResponse = try decoder.decode(RefreshTokenResponse.self, from: generateData)
        guard let generateToken = generateTokenResponse.toIdentityPackage() else {
            throw "Unable to create generateToken"
        }

        // Load UID2Client Mocked
        let client = UID2Client(uid2APIURL: "", MockNetworkSession("refresh-token-200-optout-encrypted", "txt"))

        // Call RefreshToken using refreshToken and refreshResponseKey from Step 1 to decrypt
        let refreshToken = try await client.refreshIdentityPackage(refreshToken: generateToken.refreshToken ?? "",
                                                                 refreshResponseKey: generateToken.refreshResponseKey ?? "")

        // Load Local RefreshToken from JSON
        let localRefreshData = try  DataLoader.load(fileName: "refresh-token-200-optout-decrypted", fileExtension: "json")
        let localTokenResponse = try decoder.decode(RefreshTokenResponse.self, from: localRefreshData)
        
        XCTAssertNil(refreshToken.advertisingToken)
        XCTAssertNil(refreshToken.refreshToken)
        XCTAssertNil(refreshToken.identityExpires)
        XCTAssertNil(refreshToken.refreshFrom)
        XCTAssertNil(refreshToken.refreshExpires)
        XCTAssertNil(refreshToken.refreshResponseKey)
        XCTAssertEqual(refreshToken.status, localTokenResponse.status)
        
    }

    /// 🟥  `POST /v2/token/refresh` - HTTP 400 - Client Error
    func testRefreshTokenClientError() async {
        
        do {
            // Load UID2Client Mocked
            let client = UID2Client(uid2APIURL: "", MockNetworkSession("refresh-token-400-client-error", "json", 400))
            
            // Call RefreshToken using refreshToken and refreshResponseKey from Step 1 to decrypt
            let _ = try await client.refreshIdentityPackage(refreshToken: "token", refreshResponseKey: "key")
            XCTFail("refreshUID2Token() did not throw an error.")
        } catch {
            if let uid2Error = error as? UID2Error {
                switch uid2Error {
                case .refreshTokenServer(status: let status, message: let message):
                    XCTAssertEqual(status, .clientError)
                    XCTAssertEqual(message, "Client Error")
                default:
                    XCTFail("UID2Error was not of expected type")
                }
            } else {
                XCTFail("Error was not a UID2Error")
            }
        }

    }
    
    /// 🟥  `POST /v2/token/refresh` - HTTP 400 - Invalid Token
    func testRefreshTokenInvalidToken() async {
        
        do {
            // Load UID2Client Mocked
            let client = UID2Client(uid2APIURL: "", MockNetworkSession("refresh-token-400-invalid-token", "json", 400))
            
            // Call RefreshToken using refreshToken and refreshResponseKey from Step 1 to decrypt
            let _ = try await client.refreshIdentityPackage(refreshToken: "token", refreshResponseKey: "key")
            XCTFail("refreshUID2Token() did not throw an error.")
        } catch {
            if let uid2Error = error as? UID2Error {
                switch uid2Error {
                case .refreshTokenServer(status: let status, message: let message):
                    XCTAssertEqual(status, .invalidToken)
                    XCTAssertEqual(message, "Invalid Token")
                default:
                    XCTFail("UID2Error was not of expected type")
                }
            } else {
                XCTFail("Error was not a UID2Error")
            }
        }

    }

    /// 🟥  `POST /v2/token/refresh` - HTTP 401 - Unauthorized
    func testRefreshTokenUnauthorized() async {
        
        do {
            // Load UID2Client Mocked
            let client = UID2Client(uid2APIURL: "", MockNetworkSession("refresh-token-401-unauthorized", "json", 401))
            
            // Call RefreshToken using refreshToken and refreshResponseKey from Step 1 to decrypt
            let _ = try await client.refreshIdentityPackage(refreshToken: "token", refreshResponseKey: "key")
            XCTFail("refreshUID2Token() did not throw an error.")
        } catch {
            if let uid2Error = error as? UID2Error {
                switch uid2Error {
                case .refreshTokenServer(status: let status, message: let message):
                    XCTAssertEqual(status, .unauthorized)
                    XCTAssertNil(message)
                default:
                    XCTFail("UID2Error was not of expected type")
                }
            } else {
                XCTFail("Error was not a UID2Error")
            }
        }

    }

}
