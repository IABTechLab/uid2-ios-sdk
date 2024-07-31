// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UID2",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13),
        .tvOS(.v13)
    ],
    products: [
        .library(
            name: "UID2",
            targets: ["UID2"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-asn1.git", .upToNextMajor(from: "1.0.0")),
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
        .testTarget(
            name: "UID2Tests",
            dependencies: ["UID2", "TestHelpers"]
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
