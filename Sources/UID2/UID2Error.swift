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
}

public enum TokenGenerationError: Error {

    /// The API request failed
    case requestFailure(httpStatusCode: Int, response: String?)

    /// Unable to decrypt response data
    case decryptionFailure

    /// Invalid configuration
    case configuration(message: String?)

    /// The request succeeded, but the response is missing required fields or has an invalid status
    case invalidResponse
}
