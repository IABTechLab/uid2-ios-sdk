//
//  RefreshTokenAPITests.swift
//  
//
//  Created by Brad Leege on 2/1/23.
//

import TestHelpers
import XCTest
@testable import UID2

final class RefreshTokenAPITests: XCTestCase {

    /// 🟩  `POST /v2/token/refresh` - HTTP 200 - Success
    /// uid2-iOS-sdk@test.com
    func testRefreshTokenSuccess() async throws {
        // Load Generate Token
        let generateTokenResponse = try FixtureLoader.decode(RefreshTokenResponse.self, fixture: "generate-token-200-success")
        guard let generateToken = generateTokenResponse.toUID2Identity() else {
            throw "Unable to create generateToken"
        }

        // Load UID2Client Mocked
        let client = UID2Client.test(
            session: MockNetworkSession("refresh-token-200-success-encrypted", "txt")
        )

        // Call RefreshToken using refreshToken and refreshResponseKey from Step 1 to decrypt
        let refreshToken = try await client.refreshIdentity(refreshToken: generateToken.refreshToken,
                                                             refreshResponseKey: generateToken.refreshResponseKey)

        // Load Local RefreshToken from JSON
        let localTokenResponse = try FixtureLoader.decode(RefreshTokenResponse.self, fixture: "refresh-token-200-success-decrypted")
        guard let localRefreshToken = localTokenResponse.toUID2Identity() else {
            throw "Unable to create localRefreshToken"
        }
        XCTAssertEqual(refreshToken.identity, localRefreshToken)
    }

    /// 🟩  `POST /v2/token/refresh` - HTTP 200 - OptOut
    /// optout@email.com
    /// https://github.com/IABTechLab/uid2docs/blob/main/api/v2/endpoints/post-token-refresh.md#testing-notes
    func testRefreshTokenOptOut() async throws {
     
        // Load Generate Token
        let generateTokenResponse = try FixtureLoader.decode(RefreshTokenResponse.self, fixture: "generate-token-200-optout")
        guard let generateToken = generateTokenResponse.toUID2Identity() else {
            throw "Unable to create generateToken"
        }

        // Load UID2Client Mocked
        let client = UID2Client.test(
            session: MockNetworkSession("refresh-token-200-optout-encrypted", "txt")
        )

        // Call RefreshToken using refreshToken and refreshResponseKey from Step 1 to decrypt
        let refreshToken = try await client.refreshIdentity(refreshToken: generateToken.refreshToken,
                                                                 refreshResponseKey: generateToken.refreshResponseKey)

        // Load Local RefreshToken from JSON
        let localTokenResponse = try FixtureLoader.decode(RefreshTokenResponse.self, fixture: "refresh-token-200-optout-decrypted")
        let localResponsePackage = localTokenResponse.toRefreshAPIPackage()
        
        XCTAssertEqual(refreshToken.status, localResponsePackage?.status)
        XCTAssertNil(refreshToken.identity)
    }

    /// 🟥  `POST /v2/token/refresh` - HTTP 400 - Client Error
    func testRefreshTokenClientError() async {
        
        do {
            // Load UID2Client Mocked
            let client = UID2Client.test(
                session: MockNetworkSession("refresh-token-400-client-error", "json", 400)
            )

            // Call RefreshToken using refreshToken and refreshResponseKey from Step 1 to decrypt
            let _ = try await client.refreshIdentity(refreshToken: "token", refreshResponseKey: "key")
            XCTFail("refreshUID2Token() did not throw an error.")
        } catch {
            if let uid2Error = error as? UID2Error {
                switch uid2Error {
                case .refreshTokenServerDecoding(httpStatus: let status, message: let message):
                    XCTAssertEqual(status, 400)
                    XCTAssertNotNil(message, "Error message was nil")
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
            let client = UID2Client.test(
                session: MockNetworkSession("refresh-token-400-invalid-token", "json", 400)
            )
            
            // Call RefreshToken using refreshToken and refreshResponseKey from Step 1 to decrypt
            let _ = try await client.refreshIdentity(refreshToken: "token", refreshResponseKey: "key")
            XCTFail("refreshUID2Token() did not throw an error.")
        } catch {
            if let uid2Error = error as? UID2Error {
                switch uid2Error {
                case .refreshTokenServerDecoding(httpStatus: let status, message: let message):
                    XCTAssertEqual(status, 400)
                    XCTAssertNotNil(message, "Error message was nil")
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
            let client = UID2Client.test(
                session: MockNetworkSession("refresh-token-401-unauthorized", "json", 401)
            )
            
            // Call RefreshToken using refreshToken and refreshResponseKey from Step 1 to decrypt
            let _ = try await client.refreshIdentity(refreshToken: "token", refreshResponseKey: "key")
            XCTFail("refreshUID2Token() did not throw an error.")
        } catch {
            if let uid2Error = error as? UID2Error {
                switch uid2Error {
                case .refreshTokenServerDecoding(httpStatus: let status, message: let message):
                    XCTAssertEqual(status, 401)
                    XCTAssertNotNil(message, "Error message was nil")
                default:
                    XCTFail("UID2Error was not of expected type")
                }
            } else {
                XCTFail("Error was not a UID2Error")
            }
        }

    }

}
