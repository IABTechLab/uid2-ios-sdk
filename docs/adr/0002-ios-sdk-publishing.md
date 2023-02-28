# 2. iOS SDK Publishing

Date: 2023-02-01

## Status

Accepted

## Context

Developers need to be able to easily integrate the UID2 iOS SDK into their apps.  They also need the ability to upgrade to new versions in a predictable manner over time.

## Decisions

Versions of the UID2 iOS SDK will be published on the [OpenPass iOS SDK GitHub repository](https://github.com/IABTechLab/uid2-ios-sdk) using [GitHub's Release Management tools](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository).  These releases will enable developers to use [Swift Package Manager](https://www.swift.org/package-manager/) and [Cocoapods](https://cocoapods.org) to integrate the OpenPass iOS SDK in their apps.

Releases will be adhere to [SemVer](https://semver.org) for versioning.
