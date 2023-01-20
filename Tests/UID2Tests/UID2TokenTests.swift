import Foundation
import XCTest
@testable import UID2

final class UID2TokenTests: XCTestCase {
    

    func testUID2TokenLoad() throws {
        
        let data = try loadData(for: "uidtoken", fileExtension: "json")
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let uid2Token = try decoder.decode(UID2Token.self, from: data)

        XCTAssertEqual(uid2Token.advertisingToken, "NewAdvertisingTokenIjb6u6KcMAtd0/4ZIAYkXvFrMdlZVqfb9LNf99B+1ysE/lBzYVt64pxYxjobJMGbh5q/HsKY7KC0Xo5Rb/Vo8HC4dYOoWXyuGUaL7Jmbw4bzh+3pgokelUGyTX19DfArTeIg7n+8cxWQ=")
        XCTAssertEqual(uid2Token.refreshToken, "NewRefreshTokenAAAF2c8H5dF8AAAF2c8H5dF8AAAADX393Vw94afoVLL6A+qjdSUEisEKx6t42fLgN+2dmTgUavagz0Q6Kp7ghM989hKhZDyAGjHyuAAwm+CX1cO7DWEtMeNUA9vkWDjcIc8yeDZ+jmBtEaw07x/cxoul6fpv2PQ==")
        XCTAssertEqual(uid2Token.identityExpires, 1633643601000)
        XCTAssertEqual(uid2Token.refreshFrom, 1633643001000)
        XCTAssertEqual(uid2Token.refreshExpires, 1636322000000)
        XCTAssertEqual(uid2Token.refreshResponseKey, "yptCUTBoZm1ffosgCrmuwg==")
    }
    
    private func loadData(for fileName: String, fileExtension: String)throws -> Data {
        
        guard let bundlePath = Bundle.module.path(forResource: fileName, ofType: fileExtension, inDirectory: "TestData"),
                  let jsonData = try String(contentsOfFile: bundlePath).data(using: .utf8) else {
                throw "Could not load JSON from file."
        }

        return jsonData
    }
    
}
