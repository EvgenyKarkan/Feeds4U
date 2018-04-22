//
//  TextualDataImport.swift
//  SimpleSimilarityFramework
//
//  Created by Julius Bahr on 20.08.17.
//  Copyright © 2017 Julius Bahr. All rights reserved.
//

import Foundation


/// Error object thrown when reading a file fails
public struct FileReadError: Error {}

/// Data structure for a single textual input
public struct TextualData: Hashable {
    /// The input string
    let inputString: String

    /// The origin where this string is found. I.e. a book or a webpage or software
    let origin: String?
    
    public var hashValue: Int {
        if let origin = origin {
            return origin.appending(inputString).hashValue
        } else {
            return inputString.hashValue
        }
    }
    
    public static func ==(lhs: TextualData, rhs: TextualData) -> Bool {
        var lhsText = lhs.inputString
        var rhsText = rhs.inputString
        
        if let lhsOrigin = lhs.origin {
            lhsText = lhsText.appending(lhsOrigin)
        }
        
        if let rhsOrigin = rhs.origin {
            rhsText = rhsOrigin.appending(rhsOrigin)
        }
        
        return lhsText == rhsText
    }
}


/// Base protocol used by objects that load data for the textual similarity search
public protocol TextualDataImport {

    /// Load's the content of the given file
    ///
    /// - Parameter fileName: this file is being read
    /// - Throws: a FileReadError error when loading the file fails
    mutating func loadFile(at fileName: String) throws

    /// The contents of the file that has been loaded
    /// - Precondition: a file must have been loaded before
    var fileContents: [TextualData]? {get}
}

public struct CSVImport: TextualDataImport {
    public init() {
        
    }

    fileprivate var csvFileContents: [TextualData]?

    public var fileContents: [TextualData]? {
        get {
            return csvFileContents
        }
    }

    public mutating func loadFile(at fileName: String) throws {
        if FileManager.default.fileExists(atPath: fileName) {

            let fileContents = try? String(contentsOfFile: fileName)
            var parsedFileContents:[TextualData] = []

            if let fileContents = fileContents {
                let lines = fileContents.split(separator: "\n")
                lines.forEach({ (line) in
                    let columns = line.split(separator: ";")
                    if columns.count > 1 {
                        parsedFileContents.append(TextualData(inputString: String(columns[0]), origin: String(columns[1])))
                    }
                })
            }

            guard !parsedFileContents.isEmpty else {
                throw FileReadError()
            }

            csvFileContents = parsedFileContents
            
        } else {
            throw FileReadError()
        }
    }

}

public struct NewspaperCorpusImport: TextualDataImport {
    public init() {
        
    }
    
    fileprivate var newspaperContents: [TextualData]?
    
    public var fileContents: [TextualData]? {
        get {
            return newspaperContents
        }
    }
    
    public mutating func loadFile(at fileName: String) throws {
        if FileManager.default.fileExists(atPath: fileName) {
            
            let fileContents = try? String(contentsOfFile: fileName)
            var parsedFileContents:[TextualData] = []
            
            if let fileContents = fileContents {
                let lines = fileContents.split(separator: "\n")
                lines.forEach({ (line) in
                    let columns = line.split(separator: "|")
                    if columns.count > 1 {
                        let columnsCount = columns.count
                        
                        if columnsCount > 4  {
                            parsedFileContents.append(TextualData(inputString: String(columns[4]), origin: String(columns[3])))
                        }
                        if columnsCount > 5 {
                            parsedFileContents.append(TextualData(inputString: String(columns[5]), origin: String(columns[3])))
                        }
                        if columnsCount > 6 {
                            parsedFileContents.append(TextualData(inputString: String(columns[6]), origin: String(columns[3])))
                        }
                    }
                })
            }
            
            guard !parsedFileContents.isEmpty else {
                throw FileReadError()
            }
            
            newspaperContents = parsedFileContents
            
        } else {
            throw FileReadError()
        }
    }
    
}
