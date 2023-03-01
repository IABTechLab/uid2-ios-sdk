# 2. iOS On Device Storage

Date: 2023-02-02

## Status

Accepted

## Context

The UID2 SDK needs to persist and retreive data locally on device in order to manage UID2 data.

## Decisions

The UID2 SDK will make use of iOS [Keychain](https://developer.apple.com/documentation/security/certificate_key_and_trust_services/keys/storing_keys_in_the_keychain) for on device persistence.  Keychain was chosen as it:


* Is a built in to the OS system that stores data in an encrypted form.
* Enables sharing of UID2 data across apps from a single publisher via [Keychain Sharing](https://developer.apple.com/documentation/security/keychain_services/keychain_items/sharing_access_to_keychain_items_among_a_collection_of_apps) if so desired by the publisher.
* Meets expectations of external developers of where non preference data should be stored.

iOS [UserDefaults](https://developer.apple.com/documentation/foundation/userdefaults) was also considered but was not chosen as:

* Data is stored in human readable and accessible .plist file
* It's designed to store app preferences, not app data
