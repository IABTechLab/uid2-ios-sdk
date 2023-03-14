//
//  UID2GoogleIMASecureSignalsAdapter.swift
//
//
//  Created by Brad Leege on 3/13/23.
//

import Foundation
#if canImport(GoogleInteractiveMediaAds)
import GoogleInteractiveMediaAds
#endif

public class UID2GoogleIMASecureSignalsAdapter: NSObject {
    
    override required public init() {
        super.init()
    }
    
}

#if canImport(GoogleInteractiveMediaAds)
extension UID2GoogleIMASecureSignalsAdapter: IMASecureSignalsAdapter {
    
    public static func adapterVersion() -> IMAVersion {
        let version = IMAVersion()
        version.majorVersion = 1
        version.minorVersion = 0
        version.patchVersion = 0
        return version
    }
    
    public static func adSDKVersion() -> IMAVersion {
        let version = IMAVersion()
        version.majorVersion = 3
        version.minorVersion = 18
        version.patchVersion = 4
        return version
    }
    
    public func collectSignals(completion: @escaping IMASignalCompletionHandler) {
        
        DispatchQueue.main.async {
            guard let advertisingToken = UID2Manager.shared.getAdvertisingToken() else {
                completion(nil, nil)
                return
            }

            completion(advertisingToken, nil)
        }
    }
    
}
#endif
