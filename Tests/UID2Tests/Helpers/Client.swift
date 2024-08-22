//
//  Client.swift
//

import Foundation
@testable import UID2

extension UID2Client {
    static func test(
        sdkVersion: String = "TEST",
        session: any NetworkSession = URLSession.shared,
        cryptoUtil: CryptoUtil = .liveValue
    ) -> UID2Client {
        .init(
            sdkVersion: sdkVersion,
            environment: .init(
                endpoint: URL(string: "https://prod.uidapi.com")!,
                isProduction: true
            ),
            session: session,
            cryptoUtil: cryptoUtil
        )
    }
}
