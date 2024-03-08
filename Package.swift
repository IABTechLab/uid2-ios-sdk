// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UID2",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "UID2",
            targets: ["UID2"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "UID2",
            dependencies: [],
            resources: [
                .copy("Properties/sdk_properties.plist"),
                .copy("PrivacyInfo.xcprivacy")
            ]),
        .testTarget(
            name: "UID2Tests",
            dependencies: ["UID2"],
            resources: [
                .copy("TestData")
            ]),
    ]
)
