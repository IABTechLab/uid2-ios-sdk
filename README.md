# UID2 SDK for iOS

The UID 2 Project is subject to the IAB Tech Lab Intellectual Property Rights (IPR) Policy, and is managed by the IAB Tech Lab Addressability Working Group and [Privacy & Rearc Commit Group](https://iabtechlab.com/working-groups/privacy-rearc-commit-group/). Please review the [governance rules](https://github.com/IABTechLab/uid2-core/blob/master/Software%20Development%20and%20Release%20Procedures.md).


[![License: Apache](https://img.shields.io/badge/License-Apache-green.svg)](https://www.apache.org/licenses/)
[![Swift](https://img.shields.io/badge/Swift-5-orange)](https://img.shields.io/badge/Swift-5-orange)
[![Swift Package Manager](https://img.shields.io/badge/Swift_Package_Manager-compatible-blue)](https://img.shields.io/badge/Swift_Package_Manager-compatible-blue)


This document includes:
* [Repository Structure](#repository-structure)
* [Requirements](#requirements)
* [Install and Usage](#install-and-usage)
* [Development](#development)

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

* Xcode 15.0+

| Platform | Minimum target | Swift Version |
| --- | --- | --- |
| iOS | 13.0+ | 5.0+ |
| tvOS | 13.0+ | 5.0+ |

## Install and Usage

For installation and usage information, see the applicable guide:

- For UID2: [SDK for iOS Reference Guide](https://unifiedid.com/docs/sdks/sdk-ref-ios)
- For EUID: [SDK for iOS Reference Guide](https://euid.eu/docs/sdks/sdk-ref-ios)

## Development

The UID2 SDK is a standalone headless library defined and managed by the Swift Package Manager via `Package.swift`.  As such the `UID2DevelopmentApp` is the primary way for developing the SDK.  Use Xcode to open `Development/UID2SDKDevelopmentApp/UID2SDKDevelopmentApp.xcodeproj` to begin development.

<!-- 
## Release Process

See [RELEASE_PROCESS](https://github.com/IABTechLab/uid2-ios-sdk/blob/main/RELEASE_PROCESS.md).
-->

