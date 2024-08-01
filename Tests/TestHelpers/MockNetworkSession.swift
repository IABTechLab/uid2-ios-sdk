//
//  MockNetworkSession.swift
//  
//
//  Created by Brad Leege on 2/1/23.
//

import Foundation
@testable import UID2

public final class MockNetworkSession: NetworkSession {

    private let fileName: String
    private let fileExtension: String
    private let responseCode: Int
    
    public init(_ fileName: String, _ fileExtension: String, _ responseCode: Int = 200) {
        self.fileName = fileName
        self.fileExtension = fileExtension
        self.responseCode = responseCode
    }
    
    public func loadData(for request: URLRequest) throws -> (Data, HTTPURLResponse) {
        let jsonData = try FixtureLoader.data(fixture: fileName, withExtension: fileExtension)
        let response = HTTPURLResponse(url: request.url!, statusCode: responseCode, httpVersion: nil, headerFields: nil)!
        return (jsonData, response)
    }
    
}
