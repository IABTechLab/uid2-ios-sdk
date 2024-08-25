//
//  NetworkSession.swift
//  
//
//  Created by Brad Leege on 1/31/23.
//

import Foundation

/// Common interface for networking and unit testing
@available(iOS 13, tvOS 13, *)
protocol NetworkSession: Sendable {
    
    func loadData(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
    
}
