//
//  Client.swift
//

import Foundation
@testable import UID2

extension Environment {
    static func test() -> Environment {
        .init(
            endpoint: URL(string: "https://prod.uidapi.com")!,
            isProduction: true,
            isEuid: false,
        )
    }
}

extension UID2Client {
    static func test(
        sdkVersion: String = "TEST",
        environment: Environment = .test(),
        session: any NetworkSession = URLSession.shared,
        cryptoUtil: CryptoUtil = .liveValue
    ) -> UID2Client {
        .init(
            sdkVersion: sdkVersion,
            environment: environment,
            session: session,
            cryptoUtil: cryptoUtil
        )
    }
}
