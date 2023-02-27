# UID2 iOS SDK

A framework for integrating [UID2](https://github.com/IABTechLab/uid2docs) into iOS applications.


[![License: Apache](https://img.shields.io/badge/License-Apache-green.svg)](https://www.apache.org/licenses/)
[![Swift](https://img.shields.io/badge/Swift-5-orange)](https://img.shields.io/badge/Swift-5-orange)
[![Swift Package Manager](https://img.shields.io/badge/Swift_Package_Manager-compatible-blue)](https://img.shields.io/badge/Swift_Package_Manager-compatible-blue)

## Repository Structure

```
.
├── Development
│   ├── UID2SDKDevelopmentApp
│   └── UID2SDKDevelopmentApp.xcodeproj
├── Package.swift
├── LICENSE.md
├── README.md
├── Sources
│   └── UID2
└── Tests
    └── UID2Tests
```

## Requirements

* Xcode 14.0+

| Platform | Minimum target | Swift Version |
| --- | --- | --- |
| iOS | 13.0+ | 5.0+ |

## Development

The UID2 SDK is a standalone headless library defined and managed by the Swift Package Manager via `Package.swift`.  As such the `UID2DevelopmentApp` is the primary way for developing the SDK.  Use Xcode to open `Development/UID2SDKDevelopmentApp/UID2SDKDevelopmentApp.xcodeproj` to begin development.

## License

UID2 is released under the MIT license. [See LICENSE](https://github.com/IABTechLab/uid2-ios-sdk/blob/main/LICENSE.md) for details.
