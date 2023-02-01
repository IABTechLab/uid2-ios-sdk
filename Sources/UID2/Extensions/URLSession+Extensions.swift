//
//  URLSession+Extensions.swift
//  
//
//  Created by Brad Leege on 1/31/23.
//

import Foundation

extension URLSession: NetworkSession {

    func loadData(for request: URLRequest) async throws -> (Data , Int)  {
        let (data, response) = try await data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw UID2Error.httpURLResponse
        }

        return (data, httpResponse.statusCode)
    }
    
}
