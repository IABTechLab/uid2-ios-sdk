//
//  UID2SDKProperties.swift
//  
//
//  Created by Brad Leege on 3/22/23.
//

import Foundation

public class UID2SDKProperties {
    
    public static func getUID2SDKVersion() -> (Int, Int, Int) {
        
        let invalidVersion = (0, 0, 0)
        
        let properties = SDKPropertyLoader.load()
        guard let version = properties.uid2Version else {
            return invalidVersion
        }

        let versionComponents = version.components(separatedBy: ".")
        
        if versionComponents.count == 3 {
            guard let major = Int(versionComponents[0]),
                  let minor = Int(versionComponents[1]),
                  let patch = Int(versionComponents[2]) else {
                return invalidVersion
            }
            return (major, minor, patch)
        }
        
        return invalidVersion
    }
    
}
