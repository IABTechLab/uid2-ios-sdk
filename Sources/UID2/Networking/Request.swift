//
//  Request.swift
//
//
//  Created by Dave Snabel-Caunt on 09/04/2024.
//

import Foundation

enum Method: String {
    case get = "GET"
    case post = "POST"
}

struct Request {
    var method: Method
    var path: String
    var queryItems: [URLQueryItem]
    var body: Data?
    var headers: [String: String]

    init(
        path: String,
        method: Method = .get,
        queryItems: [URLQueryItem] = [],
        body: Data? = nil,
        headers: [String: String] = [:]
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.body = body
        self.headers = headers
    }
}
