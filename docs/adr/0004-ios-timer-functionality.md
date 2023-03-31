# 4. iOS Timer Functionality

Date: 2023-02-02

## Status

Accepted

## Context

Automatic refreshing of Identity data, `UID2Identity`, by the SDK relies on timely checks of the existing data for its `refreshFrom` and `refreshExpires` in order to know when it needs to refresh to ensure a valid token is available to the app.  These timely checks need to be done using minimal on-deveice energy as to not noticeably impact battery life.

## Decisions

The refresh timer functionality has been broken into two options:

1. Automatic
2. Manual (aka App managed)

Automatic mode is the default setting for the SDK.  In order to [minimize energy usage](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/EnergyGuide-iOS/MinimizeTimerUse.html) the SDK uses [Swift Concurrency](https://developer.apple.com/documentation/swift/concurrency).

Manual mode enables the app to completely manage the refresh lifecycle by disabling the automatic timer mechanism.  This is configured via `UID2Manager.shared.automaticRefreshEnabled`.
