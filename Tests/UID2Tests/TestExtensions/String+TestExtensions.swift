//
//  String+TestExtensions.swift
//
//
//  Created by Brad Leege on 11/9/22.
//

import Foundation

extension String: LocalizedError {
    
    public var errorDescription: String? { return self }
    
}
