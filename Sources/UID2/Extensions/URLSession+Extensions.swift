//
//  URLSession+Extensions.swift
//  
//
//  Created by Brad Leege on 1/31/23.
//

import Foundation

extension URLSession: NetworkSession {

    func loadData(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await data(for: request)
        // `URLResponse` is always `HTTPURLResponse` for HTTP requests
        // https://developer.apple.com/documentation/foundation/urlresponse
        // swiftlint:disable:next force_cast
        return (data, response as! HTTPURLResponse)
    }
    
}
