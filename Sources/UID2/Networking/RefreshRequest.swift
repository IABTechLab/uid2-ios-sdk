//
//  RefreshRequest.swift
//
//
//  Created by Dave Snabel-Caunt on 24/04/2024.
//

import Foundation

extension Request {
    static func refresh(
        token: String
    ) -> Request {
        .init(
            path: "/v2/token/refresh",
            method: .post,
            body: Data(token.utf8),
            headers: [
                "Content-Type": "application/x-www-form-urlencoded"
            ]
        )
    }
}
