## Release Process

Releases are performed via 2 Pull Requests (PR) that implements the release checklist and [GitHub Releases](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository).  This promotes consistency and visibility in the process.

### Version Numbers

Version Numbering follows [Semantic Versioning](https://semver.org) standards.  The format is `vMAJOR.MINOR.PATCH`.. ex `v0.1.0`

<img width="753" alt="semver-summary" src="https://user-images.githubusercontent.com/989928/230925438-ac6ac422-6358-4e96-9536-e3f8fc935317.png">

### Release Checklist

1. Create a Release PR
    * Update / Confirm `UID2Version` in `UID2SDKProperties.swift` is set to 
      * https://github.com/IABTechLab/uid2-ios-sdk/blob/b725a503093d9984740b3b7e3f4325588bf7fbcd/Sources/UID2/Properties/UID2SDKProperties.swift#L13
    * Add and / or Edit any ADRs that support this release
2. Merge Release PR
3. Use GitHub Releases to Publish the release
    * https://github.com/IABTechLab/uid2-ios-sdk/releases/new
    * Create tag on `main` for the commit created by merge of the Release PR
    * Document any Release Notes
4. Create a Next Release PR
    * Set `UID2Version` in `UID2SDKProperties.swift` to the expected next (likely minor) release version of the SDK.
5. Merge Next Release PR **BEFORE ANY CODE FOR NEXT RELEASE IS MERGED**
