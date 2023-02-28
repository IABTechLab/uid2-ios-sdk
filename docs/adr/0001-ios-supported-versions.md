
# 1. iOS Supported Versions

Date: 2023-02-01

## Status

Accepted

## Context

The iOS SDK needs to be both backwards compatible to enable use in as many apps as possible and forward compatible to make use of more recent paradigms from Apple.

## Decisions

The iOS SDK will support iOS 13+.  This enables it to be used in the 4 most recent versions of iOS while also allowing use of Swift Concurrency.  Swift Concurrency was first released in iOS 15 and was deemed important enough that Apple broke from their traditions and back ported it to iOS 13.

Minimum version support will be reviewed regularly as Apple releases new versions of iOS.