# 5. iOS Get Valid Advertising Token

Date: 2023-03-29

## Status

Accepted

## Context

Apps and SDKs need to be able to get a **valid** Advertising Token for use in advertising bid auctions.

## Decisions

The UID2 SDK will vend **valid** Advertising Token's via `UID2Manager.shared.getAdvertisingToken()`.  In order to only vend **valid** tokens this function will perform a series of checks on the current UID2 Identity in `UID2Manager`.  These checks ensure that only UID2 Identities with status of `established` or `refreshed` after inspection of `refreshFrom` and `identityExpires` are used.

If these checks fail, then a `nil` value is returned and the App is advised to check `identityStatus` for the exact reason so that it may act accordingly.  It's not ideal to have `UID2Manager.shared.getAdvertisingToken()` be able to mutate the state of `identityStatus` as it's a getter function', however it is necessary due to the possibility of the Automatic Refresh functionality being disabled by the app.
