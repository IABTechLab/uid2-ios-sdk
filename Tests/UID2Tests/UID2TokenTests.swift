import Foundation
import XCTest
@testable import UID2

final class UID2TokenTests: XCTestCase {
    
  func testUID2TokenLoad() throws {
        
        let data = try DataLoader.load(fileName: "uidtoken", fileExtension: "json")
        guard let uid2Token = UID2Token.fromData(data) else {
            XCTFail("Unable to convert Data to UID2Token")
            return
        }

        XCTAssertEqual(uid2Token.advertisingToken, "NewAdvertisingTokenIjb6u6KcMAtd0/4ZIAYkXvFrMdlZVqfb9LNf99B+1ysE/lBzYVt64pxYxjobJMGbh5q/HsKY7KC0Xo5Rb/Vo8HC4dYOoWXyuGUaL7Jmbw4bzh+3pgokelUGyTX19DfArTeIg7n+8cxWQ=")
        XCTAssertEqual(uid2Token.refreshToken, "NewRefreshTokenAAAF2c8H5dF8AAAF2c8H5dF8AAAADX393Vw94afoVLL6A+qjdSUEisEKx6t42fLgN+2dmTgUavagz0Q6Kp7ghM989hKhZDyAGjHyuAAwm+CX1cO7DWEtMeNUA9vkWDjcIc8yeDZ+jmBtEaw07x/cxoul6fpv2PQ==")
        XCTAssertEqual(uid2Token.identityExpires, 1633643601000)
        XCTAssertEqual(uid2Token.refreshFrom, 1633643001000)
        XCTAssertEqual(uid2Token.refreshExpires, 1636322000000)
        XCTAssertEqual(uid2Token.refreshResponseKey, "yptCUTBoZm1ffosgCrmuwg==")
    }
    
    func testUID2RoundTrip() throws {
        
        let uid2Token = UID2Token(advertisingToken: "advertisingToken",
                                  refreshToken: "refreshToken",
                                  identityExpires: 0001,
                                  refreshFrom: 0002,
                                  refreshExpires: 0003,
                                  refreshResponseKey: "refreshResponseKey",
                                  status: "success")
        let data = try uid2Token.toData()
        guard let returnedUID2Token = UID2Token.fromData(data) else {
            XCTFail("Unable to convert Data to UID2Token")
            return
        }
        
        XCTAssertEqual(returnedUID2Token.advertisingToken, "advertisingToken")
        XCTAssertEqual(returnedUID2Token.refreshToken, "refreshToken")
        XCTAssertEqual(returnedUID2Token.identityExpires, 0001)
        XCTAssertEqual(returnedUID2Token.refreshFrom, 0002)
        XCTAssertEqual(returnedUID2Token.refreshExpires, 0003)
        XCTAssertEqual(returnedUID2Token.refreshResponseKey, "refreshResponseKey")
        
    }
        
}
