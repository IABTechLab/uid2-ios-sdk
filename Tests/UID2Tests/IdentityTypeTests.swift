//
//  IdentityTypeTests.swift
//
//
//  Created by Dave Snabel-Caunt on 10/04/2024.
//

import UID2
import XCTest

final class IdentityTypeTests: XCTestCase {

    func testEmailNormalization() {
        [
            // Identity
            ("myemail@example.com", "myemail@example.com", #line),

            // Documentation examples
            ("MyEmail@example.com", "myemail@example.com", #line),
            ("MYEMAIL@example.com", "myemail@example.com", #line),

            ("My.Email@example.com", "my.email@example.com", #line),

            ("JANESAOIRSE@example.com", "janesaoirse@example.com", #line),
            ("JaneSaoirse@example.com", "janesaoirse@example.com", #line),

            ("jane.saoirse@example.com", "jane.saoirse@example.com", #line),
            ("Jane.Saoirse@example.com", "jane.saoirse@example.com", #line),

            ("JaneSaoirse+Work@example.com", "janesaoirse+work@example.com", #line),

            ("JANE.SAOIRSE@gmail.com", "janesaoirse@gmail.com", #line),
            ("Jane.Saoirse@gmail.com", "janesaoirse@gmail.com", #line),
            ("JaneSaoirse+Work@gmail.com", "janesaoirse@gmail.com", #line),

            // Edge cases
            ("JaneSaoirse+@gmail.com", "janesaoirse@gmail.com", #line),
            ("JaneSaoirse++@gmail.com", "janesaoirse@gmail.com", #line),
            ("JaneSaoirse+Work+more.work@gmail.com", "janesaoirse@gmail.com", #line),
            ("Jane.Saoirse+Work@gmail.com", "janesaoirse@gmail.com", #line),

            // Java tests
            ("TEst.TEST@Test.com ", "test.test@test.com", #line),
            ("test.test@test.com", "test.test@test.com", #line),
            ("test.test@gmail.com", "testtest@gmail.com", #line),
            ("test+test@test.com", "test+test@test.com", #line),
            ("+test@test.com", "+test@test.com", #line),
            ("test+test@gmail.com", "test@gmail.com", #line),
            ("testtest@test.com", "testtest@test.com", #line),
            (" testtest@test.com", "testtest@test.com", #line),
            ("testtest@test.com ", "testtest@test.com", #line),
            (" testtest@test.com ", "testtest@test.com", #line),
            ("  testtest@test.com  ", "testtest@test.com", #line),
            (" test.test@gmail.com", "testtest@gmail.com", #line),
            ("test.test@gmail.com ", "testtest@gmail.com", #line),
            (" test.test@gmail.com ", "testtest@gmail.com", #line),
            ("  test.test@gmail.com  ", "testtest@gmail.com", #line),
            ("TEstTEst@gmail.com  ", "testtest@gmail.com", #line),
            ("TEstTEst@GMail.Com  ", "testtest@gmail.com", #line),
            (" TEstTEst@GMail.Com  ", "testtest@gmail.com", #line),
            ("TEstTEst@GMail.Com", "testtest@gmail.com", #line),
            ("TEst.TEst@GMail.Com", "testtest@gmail.com", #line),
            ("TEst.TEst+123@GMail.Com", "testtest@gmail.com", #line),
            ("TEst.TEST@Test.com ", "test.test@test.com", #line),
            ("TEst.TEST@Test.com ", "test.test@test.com", #line),
        ].forEach { (email: String, expected: String, line: UInt) in
            XCTAssertEqual(expected, IdentityType.NormalizedEmail(string: email)?.value, line: line)
        }

        [
            ("", #line),
            (" @", #line),
            ("@", #line),
            ("a@", #line),
            ("@b", #line),
            ("@b.com", #line),
            ("+", #line),
            (" ", #line),
            ("+@gmail.com", #line),
            (".+@gmail.com", #line),
            ("a@ba@z.com", #line),
        ].forEach { (email: String, line: UInt) in
            XCTAssertNil(IdentityType.NormalizedEmail(string: email), line: line)
        }
    }

    func testPhoneNormalization() {
        [
            ("", #line),
            ("asdaksjdakfj", #line),
            ("DH5qQFhi5ALrdqcPiib8cy0Hwykx6frpqxWCkR0uijs", #line),
            ("QFhi5ALrdqcPiib8cy0Hwykx6frpqxWCkR0uijs", #line),
            ("06a418f467a14e1631a317b107548a1039d26f12ea45301ab14e7684b36ede58", #line),
            ("0C7E6A405862E402EB76A70F8A26FC732D07C32931E9FAE9AB1582911D2E8A3B", #line),
            ("+", #line),
            ("12345678", #line),
            ("123456789", #line),
            ("1234567890", #line),
            ("+12345678", #line),
            ("+123456789", #line),
            ("+ 12345678", #line),
            ("+ 123456789", #line),
            ("+ 1234 5678", #line),
            ("+ 1234 56789", #line),
            ("+1234567890123456", #line),
            ("+1234567890A", #line),
            ("+1234567890 ", #line),
            ("+1234567890+", #line),
            ("+12345+67890", #line),
            ("555-555-5555", #line),
            ("(555) 555-5555", #line),
        ].forEach { (phone: String, line: UInt) in
            XCTAssertNil(IdentityType.NormalizedPhone(normalized: phone), line: line)
        }

        [
            ("+1234567890", #line),
            ("+12345678901", #line),
            ("+123456789012", #line),
            ("+1234567890123", #line),
            ("+12345678901234", #line),
            ("+123456789012345", #line),
        ].forEach { (phone: String, line: UInt) in
            XCTAssertNotNil(IdentityType.NormalizedPhone(normalized: phone), line: line)
        }
    }
}
