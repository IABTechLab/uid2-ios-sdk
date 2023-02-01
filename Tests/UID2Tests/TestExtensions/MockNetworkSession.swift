//
//  MockNetworkSession.swift
//  
//
//  Created by Brad Leege on 2/1/23.
//

import Foundation
@testable import UID2

final class MockNetworkSession: NetworkSession {

    private let fileName: String
    private let fileExtension: String
    private let responseCode: Int
    
    init(_ fileName: String, _ fileExtension: String, _ responseCode: Int = 200) {
        self.fileName = fileName
        self.fileExtension = fileExtension
        self.responseCode = responseCode
    }
    
    func loadData(for request: URLRequest) throws -> (Data, Int) {
        let jsonData = try DataLoader.load(fileName: fileName, fileExtension: fileExtension)
        return (jsonData, responseCode)
    }
    
}
