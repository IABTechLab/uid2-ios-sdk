# 6. iOS Identity Status Persistence

Date: 2023-03-29

## Status

Accepted

## Context

Apps need to be able to get immediate access to valid UID2 Identities and / or Opt Out status across instantiations of their app.  This enables them to know if they can use the known UID2 Identity's Advertising Token to power Advervisting Bid Auctions, whether they need to refresh the UID2 Identity first, or if the user has Opted Out.

## Decisions

To support this functionality the UID2 SDK needs to maintain the status of UID2 Identity and it's Status via [On Device Storage](https://github.com/IABTechLab/uid2-ios-sdk/blob/main/docs/adr/0003-ios-on-device-storage.md).  The only UID2 Identies that will be loaded from device are ones with the status of `established` or `refreshed`.  This does not guarantee that these tokens are valid, as that is something that is determined when the App [gets the Advertising Token](https://github.com/IABTechLab/uid2-ios-sdk/blob/main/docs/adr/0005-ios-get-advertising-token.md).  If the status of `optOut` is found then no UID2 Identity will be loaded and the `identityStatus` will be set to `optOut`.

