import Foundation
import XCTest
@testable import UID2

final class UID2TokenTests: XCTestCase {
    
    func testUID2TokenLoad() throws {
        
        let data = try DataLoader.load(fileName: "uididentity", fileExtension: "json")
        
        guard let uid2Identity = UID2Identity.fromData(data) else {
            XCTFail("Unable to load UID2Identity data")
            return
        }
                
        XCTAssertEqual(uid2Identity.advertisingToken, "NewAdvertisingTokenIjb6u6KcMAtd0/4ZIAYkXvFrMdlZVqfb9LNf99B+1ysE/lBzYVt64pxYxjobJMGbh5q/HsKY7KC0Xo5Rb/Vo8HC4dYOoWXyuGUaL7Jmbw4bzh+3pgokelUGyTX19DfArTeIg7n+8cxWQ=")
        XCTAssertEqual(uid2Identity.refreshToken, "NewRefreshTokenAAAF2c8H5dF8AAAF2c8H5dF8AAAADX393Vw94afoVLL6A+qjdSUEisEKx6t42fLgN+2dmTgUavagz0Q6Kp7ghM989hKhZDyAGjHyuAAwm+CX1cO7DWEtMeNUA9vkWDjcIc8yeDZ+jmBtEaw07x/cxoul6fpv2PQ==")
        XCTAssertEqual(uid2Identity.identityExpires, 1633643601000)
        XCTAssertEqual(uid2Identity.refreshFrom, 1633643001000)
        XCTAssertEqual(uid2Identity.refreshExpires, 1636322000000)
        XCTAssertEqual(uid2Identity.refreshResponseKey, "yptCUTBoZm1ffosgCrmuwg==")
    }
    
    func testUID2RoundTrip() throws {
        
        let uid2Identity = UID2Identity(advertisingToken: "advertisingToken",
                                  refreshToken: "refreshToken",
                                  identityExpires: 0001,
                                  refreshFrom: 0002,
                                  refreshExpires: 0003,
                                  refreshResponseKey: "refreshResponseKey")
        
        let data = try uid2Identity.toData()
        guard let returnedUid2Identity = UID2Identity.fromData(data) else {
            XCTFail("Unable to convert Data to UID2Identity")
            return
        }
        
        XCTAssertEqual(returnedUid2Identity.advertisingToken, "advertisingToken")
        XCTAssertEqual(returnedUid2Identity.refreshToken, "refreshToken")
        XCTAssertEqual(returnedUid2Identity.identityExpires, 0001)
        XCTAssertEqual(returnedUid2Identity.refreshFrom, 0002)
        XCTAssertEqual(returnedUid2Identity.refreshExpires, 0003)
        XCTAssertEqual(returnedUid2Identity.refreshResponseKey, "refreshResponseKey")
        
    }
        
}
