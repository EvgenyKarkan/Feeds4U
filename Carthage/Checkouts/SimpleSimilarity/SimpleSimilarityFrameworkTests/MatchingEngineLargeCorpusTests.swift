//
//  MatchingEngineTests.swift
//  SimpleSimilarityFrameworkTests
//
//  Created by Julius Bahr on 22.10.17.
//  Copyright © 2017 Julius Bahr. All rights reserved.
//

import XCTest
@testable import SimpleSimilarityFramework

class MatchingEngineLargeCorpusTests: XCTestCase {
    
    func testQueryFoundInCorpusNotExhaustive() {
    
        guard let csvPath = Bundle.main.path(forResource: "newspaper", ofType: "csv") else {
            return
        }
        
        var csvImporter = NewspaperCorpusImport()
        do {
            try csvImporter.loadFile(at: csvPath)
        } catch {
            print("Reading the csv file caused an exception.")
        }
        
        let matchingEngine = MatchingEngine()
        
        guard let fileContents = csvImporter.fileContents else {
            return
        }
        
        let asyncExpectation = expectation(description: "asyncWait")
        
        matchingEngine.fillMatchingEngine(with: fileContents) {
            let yellowTailedTuna = TextualData(inputString: "Der Bundeskanzler reiste nach Algerien", origin: nil)
            
            try? matchingEngine.bestResult(for: yellowTailedTuna, exhaustive: false, resultFound: { (result) in
                guard let result = result else {
                    XCTFail("No result found")
                    return
                }
                
                XCTAssertTrue(result.textualResults.first!.inputString.contains("Bundeskanzler"))
                
                XCTAssert(result.quality > 0.2)
                
                asyncExpectation.fulfill()
            })
        }
        
        waitForExpectations(timeout: 120)
    }
    
    func testQueryFoundInCorpusExhaustive() {
        
        guard let csvPath = Bundle.main.path(forResource: "newspaper", ofType: "csv") else {
            return
        }
        
        var csvImporter = NewspaperCorpusImport()
        do {
            try csvImporter.loadFile(at: csvPath)
        } catch {
            print("Reading the csv file caused an exception.")
        }
        
        let matchingEngine = MatchingEngine()
        
        guard let fileContents = csvImporter.fileContents else {
            return
        }
        
        let asyncExpectation = expectation(description: "asyncWait")
        
        matchingEngine.fillMatchingEngine(with: fileContents) {
            let expectedBestMatch = TextualData(inputString: "Das ist die wichtigste Lektion für Amerika aus dem Jahr 2002", origin: nil)
            
            try? matchingEngine.bestResult(for: expectedBestMatch, exhaustive: true, resultFound: { (result) in
                guard let result = result else {
                    XCTFail("No result found")
                    return
                }
                
                XCTAssertTrue(result.textualResults.first!.inputString.contains("wichtigste"))
                XCTAssertTrue(result.textualResults.first!.inputString.contains("Lektion"))
                
                XCTAssert(result.quality > 0.80)
                
                asyncExpectation.fulfill()
            })
        }
        
        waitForExpectations(timeout: 60)
    }
    
    func testQueryNotFoundInCorpus() {
        
        guard let csvPath = Bundle.main.path(forResource: "newspaper", ofType: "csv") else {
            return
        }
        
        var csvImporter = NewspaperCorpusImport()
        do {
            try csvImporter.loadFile(at: csvPath)
        } catch {
            print("Reading the csv file caused an exception.")
        }
        
        let matchingEngine = MatchingEngine()
        
        guard let fileContents = csvImporter.fileContents else {
            return
        }
        
        let asyncExpectation = expectation(description: "asyncWait")
        
        matchingEngine.fillMatchingEngine(with: fileContents) {
            let noMatchQuery = TextualData(inputString: "Tuna makes for great sashimi", origin: nil)
            
            try? matchingEngine.bestResult(for: noMatchQuery, exhaustive: true, resultFound: { (result) in
                XCTAssertNil(result, "Result found where no result was expected")
                asyncExpectation.fulfill()
            })
        }
        
        waitForExpectations(timeout: 60)
    }
    
}
