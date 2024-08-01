//
//  IdentityPackageTests.swift
//  
//
//  Created by Brad Leege on 3/29/23.
//

import TestHelpers
import XCTest
@testable import UID2

final class IdentityPackageTests: XCTestCase {


    private let decoder = JSONDecoder.apiDecoder()

    private let encoder = JSONEncoder.apiEncoder()

    func testRoundTripEncodingDecoding() throws {
        let uid2Identity = try FixtureLoader.decode(UID2Identity.self, fixture: "uididentity")

        let identityPackage = IdentityPackage(valid: true, errorMessage: nil, identity: uid2Identity, status: .established)

        let identityPackageData = try encoder.encode(identityPackage)
        XCTAssertNotNil(identityPackageData)
        XCTAssertTrue(identityPackageData.count > 0)
        
        let identityPackageReconstituted = try decoder.decode(IdentityPackage.self, from: identityPackageData)
        XCTAssertNotNil(identityPackageReconstituted)
        XCTAssertEqual(identityPackageReconstituted.status, .established)
        XCTAssertEqual(identityPackageReconstituted.valid, true)
        XCTAssertEqual(identityPackageReconstituted.errorMessage, nil)

        guard let uid2IdentityReconstituted = identityPackageReconstituted.identity else {
            XCTFail("UID2Identity was not reconstituted")
            return
        }
        XCTAssertEqual(uid2IdentityReconstituted.advertisingToken, "NewAdvertisingTokenIjb6u6KcMAtd0/4ZIAYkXvFrMdlZVqfb9LNf99B+1ysE/lBzYVt64pxYxjobJMGbh5q/HsKY7KC0Xo5Rb/Vo8HC4dYOoWXyuGUaL7Jmbw4bzh+3pgokelUGyTX19DfArTeIg7n+8cxWQ=")
        XCTAssertEqual(uid2IdentityReconstituted.refreshToken, "NewRefreshTokenAAAF2c8H5dF8AAAF2c8H5dF8AAAADX393Vw94afoVLL6A+qjdSUEisEKx6t42fLgN+2dmTgUavagz0Q6Kp7ghM989hKhZDyAGjHyuAAwm+CX1cO7DWEtMeNUA9vkWDjcIc8yeDZ+jmBtEaw07x/cxoul6fpv2PQ==")
        XCTAssertEqual(uid2IdentityReconstituted.identityExpires, 1633643601000)
        XCTAssertEqual(uid2IdentityReconstituted.refreshFrom, 1633643001000)
        XCTAssertEqual(uid2IdentityReconstituted.refreshExpires, 1636322000000)
        XCTAssertEqual(uid2IdentityReconstituted.refreshResponseKey, "yptCUTBoZm1ffosgCrmuwg==")
        
    }
    
}
