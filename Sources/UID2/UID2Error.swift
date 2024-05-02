//
//  UID2Error.swift
//  
//
//  Created by Brad Leege on 1/31/23.
//

import Foundation

/// UID2 Specifc Errors

enum UID2Error: Error {
    
    /// Unable to decrypt Payload Data
    case decryptPayloadData
    
    /// Server returned a non HTTP 200 response
    case refreshTokenServer(status: RefreshTokenResponse.Status, message: String?)
    
    /// Error parsing data / response from server
    case refreshTokenServerDecoding(httpStatus: Int, message: String)
    
    /// Unable to convert RefreshTokenResponse to RefreshAPIPackage
    case refreshResponseToRefreshAPIPackage
        
    /// Token has expired
    case identityPackageIsExpired
    
    /// User has opted out
    case userHasOptedOut
    
    /// Unable to generate an UID2 Server
    case urlGeneration
    
    /// Invalid configuration
    case configuration(message: String?)
}
