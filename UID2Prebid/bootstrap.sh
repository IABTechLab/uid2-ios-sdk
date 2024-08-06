#!/bin/sh
set -euxo pipefail

# Clone prebid-mobile-ios as a submodule, build it for device and simulator, and produce an XCFramework
# This won't be necessary when prebid-mobile-ios supports Swift Package Manager
rm -rf Dependencies
mkdir Dependencies
git submodule update --init

xcodebuild archive \
	only_active_arch=NO \
	defines_module=YES \
	SKIP_INSTALL=NO \
	-workspace Carthage/Checkouts/prebid-mobile-ios/PrebidMobile.xcworkspace \
	-scheme "PrebidMobile" \
	-configuration Release \
	-arch arm64 \
	-sdk "iphoneos" \
	-archivePath "Dependencies/PrebidMobile.xcarchive"

xcodebuild archive \
	only_active_arch=NO \
	defines_module=YES \
	SKIP_INSTALL=NO \
	-workspace Carthage/Checkouts/prebid-mobile-ios/PrebidMobile.xcworkspace \
	-scheme "PrebidMobile" \
	-configuration Release \
	-sdk "iphonesimulator" \
	-archivePath "Dependencies/PrebidMobile-simulator.xcarchive"

xcodebuild -create-xcframework \
	    -framework "Dependencies/PrebidMobile.xcarchive/Products/Library/Frameworks/PrebidMobile.framework" \
	    -framework "Dependencies/PrebidMobile-simulator.xcarchive/Products/Library/Frameworks/PrebidMobile.framework" \
	    -output "Dependencies/XCPrebidMobile.xcframework"

rm -r Dependencies/PrebidMobile.xcarchive
rm -r Dependencies/PrebidMobile-simulator.xcarchive
