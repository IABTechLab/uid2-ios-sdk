//
//  Date+Extensions.swift
//  
//
//  Created by Brad Leege on 2/9/23.
//

import Foundation

extension Date {
    
    var millisecondsSince1970: Int64 {
        Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
    
}
