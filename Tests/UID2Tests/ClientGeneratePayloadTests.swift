//
//  ClientGeneratePayloadTests.swift
//
//
//  Created by Dave Snabel-Caunt on 10/04/2024.
//

@testable import UID2
import XCTest

final class ClientGeneratePayloadTests: XCTestCase {
    
    func testEmailPayload() throws {
        let email = try XCTUnwrap(IdentityType.NormalizedEmail(string: "myemail@example.com"))
        try assertPayloadJSON(
            .email(email),
            """
            {
              "email_hash" : "FsGNM28LJQ8OLZB0Us65ZYp07NrovJSGTCMSKnLMJ6U=",
              "optout_check" : 1
            }
            """
        )
    }

    func testEmailHashPayload() throws {
        try assertPayloadJSON(
            .emailHash("im-a-hash"),
            """
            {
              "email_hash" : "im-a-hash",
              "optout_check" : 1
            }
            """
        )
    }

    func testPhonePayload() throws {
        let phone = try XCTUnwrap(IdentityType.NormalizedPhone(normalized: "+12345678901"))
        try assertPayloadJSON(
            .phone(phone),
            """
            {
              "optout_check" : 1,
              "phone_hash" : "EObwtHBUqDNZR33LNSMdtt5cafsYFuGmuY4ZLenlue4="
            }
            """
        )
    }

    func testPhoneHashPayload() throws {
        try assertPayloadJSON(
            .phoneHash("phone-hash"),
            """
            {
              "optout_check" : 1,
              "phone_hash" : "phone-hash"
            }
            """
        )
    }

    func testEmailHashing() throws {
        try [
            // Documentation examples
            ("myemail@example.com", "FsGNM28LJQ8OLZB0Us65ZYp07NrovJSGTCMSKnLMJ6U=", #line),
            ("my.email@example.com", "4itTvG+HEnTzpiqzejyu1yFPwU1nYhWpaiQvz62hyB8=", #line),
            ("janesaoirse@example.com", "1mcOepIAfxtf94Xx/IHlOqbT170GvfXEc83HKGwoS20=", #line),
            ("jane.saoirse@example.com", "sZZDLHuYmiypHIN5mVfFFdpT5sE6vyC3j+qU8RfpC/g=", #line),
            ("janesaoirse+work@example.com", "KKruSBUjDNO069iMUVImVQZm6RrAGZKeOtrD9mwogYA=", #line),
            ("janesaoirse@gmail.com", "ku4mBX7Z3qJTXWyLFB1INzkyR2WZGW4ANSJUiW21iI8=", #line),
        ].forEach { (email: String, expected: String, line: UInt) in
            let normalized = try XCTUnwrap(IdentityType.NormalizedEmail(string: email), line: line)
            XCTAssertEqual(expected, ClientGeneratePayload(.email(normalized)).value, line: line)
        }
    }

    func testPhoneHashing() throws {
        try [
            ("+11234567890", "H6a42YbZuc0BvzaVGBUVi73p9SDAVnyDXf40eD0KQjE=", #line),
            ("+6512345678", "xn2K5iZn+pV1H0nXXILY8ggcGt9dClVnIX13SXVVpZ8=", #line),
            ("+61212345678", "J24LFuwzgT5ElsjMwcqE40S8VtUoWXFCZgkq+PDSD+c=", #line),
        ].forEach { (phone: String, expected: String, line: UInt) in
            let normalized = try XCTUnwrap(IdentityType.NormalizedPhone(normalized: phone), line: line)
            XCTAssertEqual(expected, ClientGeneratePayload(.phone(normalized)).value, line: line)
        }
    }

    private func assertPayloadJSON(_ identityType: IdentityType, _ json: String, file: StaticString = #filePath, line: UInt = #line) throws {
        let payload = ClientGeneratePayload(identityType)
        let encoder = JSONEncoder.apiEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(payload)
        XCTAssertEqual(
            String(data: data, encoding: .utf8),
            json,
            file: file,
            line: line
        )
    }
}
