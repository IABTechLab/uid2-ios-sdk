//
//  Codable.swift
//
//
//  Created by Dave Snabel-Caunt on 10/04/2024.
//

import Foundation

extension JSONDecoder {
    static func apiDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}

extension JSONEncoder {
    static func apiEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
}
