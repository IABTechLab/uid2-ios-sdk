//
//  DataLoader.swift
//  
//
//  Created by Brad Leege on 2/1/23.
//

import Foundation

final class DataLoader {

    static func load(fileName: String, fileExtension: String, _ inDirectory: String = "TestData") throws -> Data {
        guard let bundlePath = Bundle.module.path(forResource: fileName, ofType: fileExtension, inDirectory: inDirectory),
              let stringData = try String(contentsOfFile: bundlePath).data(using: .utf8) else {
            throw "Could not load data from file."
        }
        
        return stringData
    }
    
}
