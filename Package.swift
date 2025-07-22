// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UID2",
    defaultLocalization: "en",
    // NB: The UID2 framework code only runs on iOS 13 & tvOS 13, however this allows
    // integration in apps supporting iOS 12.
    platforms: [
        .iOS(.v12),
        .tvOS(.v12)
    ],
    products: [
        .library(
            name: "UID2",
            targets: ["UID2"]),
        .library(
            name: "UID2Prebid",
            targets: ["UID2Prebid"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-asn1.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/prebid/prebid-mobile-ios.git", .upToNextMajor(from: "3.1.0")),
    ],
    targets: [
        .target(
            name: "UID2",
            dependencies: [ .product(name: "SwiftASN1", package: "swift-asn1") ],
            resources: [
                .copy("PrivacyInfo.xcprivacy")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .target(
            name: "UID2Prebid",
            dependencies: [
                "UID2",
                .product(name: "PrebidMobile", package: "prebid-mobile-ios")
            ],
            resources: [
                .copy("PrivacyInfo.xcprivacy")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "UID2Tests",
            dependencies: ["UID2", "TestHelpers"]
        ),
        .testTarget(
            name: "UID2PrebidTests",
            dependencies: ["UID2Prebid"]
        ),
        .target(
            name: "TestHelpers",
            dependencies: ["UID2"],
            path: "Tests/TestHelpers",
            resources: [
                .copy("TestData")
            ]
        )
    ]
)
