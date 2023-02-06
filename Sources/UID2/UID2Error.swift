//
//  UID2Error.swift
//  
//
//  Created by Brad Leege on 1/31/23.
//

import Foundation

/// UID2 Specifc Errors

@available(iOS 13.0, *)
enum UID2Error: Error {
    
    /// Unable to decrypt Payload Data
    case decryptPayloadData
    
    /// URLSession call did not return an HTTPURLResponse
    case httpURLResponse
    
    /// Server retunred a non HTTP 200 response
    case refreshTokenServer(status: UID2Token.Status, message: String?)
    
    /// Unable to convert RefreshTokenResponse to UID2Token
    case refreshResponseToToken
        
    /// Token has expired
    case tokenIsExpired
    
    /// User has opted out
    case userHasOptedOut
    
    /// Unable to generate an UID2 Server
    case urlGeneration
    
}
