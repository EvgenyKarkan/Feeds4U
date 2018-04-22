//
//  MatchingEngineTests.swift
//  SimpleSimilarityFrameworkTests
//
//  Created by Julius Bahr on 22.10.17.
//  Copyright © 2017 Julius Bahr. All rights reserved.
//

import XCTest
@testable import SimpleSimilarityFramework

class MatchingEngineTests: XCTestCase {

    func testMatchingEngineDidFill() {
        guard let csvPath = Bundle.main.path(forResource: "sample", ofType: "csv") else {
            return
        }

        var csvImporter = CSVImport()
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
            XCTAssertTrue(matchingEngine.isFilled, "After loading the matching engine it needs to be filled")
            asyncExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 3)
    }

    func testDetermineFrequentAndInfrequentWordsRegularCase() {

        let bagOfWords = NSCountedSet()

        for step in [3, 5, 10, 20, 30, 40, 50, 60, 70, 80, 90, 110, 120] {
            for _ in 0..<step {
                bagOfWords.add(String(step))
            }
        }

        let commonWords = MatchingEngineAlgortihm.determineFrequentAndInfrequentWords(in: bagOfWords)
        XCTAssert(!commonWords.contains("30"))
        XCTAssert(!commonWords.contains("60"))
        XCTAssert(commonWords.contains("3"))
        XCTAssert(commonWords.contains("120"))
        XCTAssert(!commonWords.contains("was never added"))
    }

    func disabledTestDetermineFrequentAndInfrequentWordsEvenlyDistributed() {

        let bagOfWords = NSCountedSet()

        for step in [10, 10, 10, 10] {
            let randomNumberForStep = Int(arc4random())

            for _ in 0..<step {
                bagOfWords.add(String(randomNumberForStep))
            }
        }

        let commonWords = MatchingEngineAlgortihm.determineFrequentAndInfrequentWords(in: bagOfWords)
        XCTAssert(commonWords.isEmpty)
    }
    
    func testQueryFoundInCorpusNotExhaustive() {
    
        guard let csvPath = Bundle.main.path(forResource: "sample", ofType: "csv") else {
            return
        }
        
        var csvImporter = CSVImport()
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
            let yellowTailedTuna = TextualData(inputString: "yellow tuna", origin: nil)
            
            try? matchingEngine.bestResult(for: yellowTailedTuna, exhaustive: false, resultFound: { (result) in
                guard let result = result else {
                    XCTFail("No result found")
                    return
                }
                
                XCTAssertTrue(result.textualResults.first!.inputString.contains("yellow"))
                
                XCTAssert(result.quality > 0.2)
                
                asyncExpectation.fulfill()
            })
        }
        
        waitForExpectations(timeout: 3)
    }
    
    func testQueryFoundInCorpusExhaustive() {
        
        guard let csvPath = Bundle.main.path(forResource: "sample", ofType: "csv") else {
            return
        }
        
        var csvImporter = CSVImport()
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
            let yellowTailedTuna = TextualData(inputString: "Yellow tailed tuna makes for great sashimi", origin: nil)
            
            try? matchingEngine.bestResult(for: yellowTailedTuna, exhaustive: true, resultFound: { (result) in
                guard let result = result else {
                    XCTFail("No result found")
                    return
                }
                
                XCTAssertTrue(result.textualResults.first!.inputString.contains("Yellow"))
                XCTAssertTrue(result.textualResults.first!.inputString.contains("tail"))
                XCTAssertTrue(result.textualResults.first!.inputString.contains("sashimi"))
                
                XCTAssert(result.quality > 0.80)
                
                asyncExpectation.fulfill()
            })
        }
        
        waitForExpectations(timeout: 3)
    }
    
    func testQueryNotFoundInCorpus() {
        
        guard let csvPath = Bundle.main.path(forResource: "sample", ofType: "csv") else {
            return
        }
        
        var csvImporter = CSVImport()
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
            let noMatchQuery = TextualData(inputString: "Zwei Zwerge stehen an der Kueche", origin: nil)
            
            try? matchingEngine.bestResult(for: noMatchQuery, exhaustive: true, resultFound: { (result) in
                XCTAssertNil(result, "Result found where no result was expected")
                asyncExpectation.fulfill()
            })
        }
        
        waitForExpectations(timeout: 3)
    }
    
    func testListOfResultsForQuery() {
        
        guard let csvPath = Bundle.main.path(forResource: "sample", ofType: "csv") else {
            return
        }
        
        var csvImporter = CSVImport()
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
            let queryWithResultList = TextualData(inputString: "Is tuna a good fish for cooking?", origin: nil)
            
            try? matchingEngine.result(betterThan: 0.1, for: queryWithResultList, resultsFound: { (results) in
                XCTAssertNotNil(results)
                
                guard let inputString = results?.first?.textualResults.first?.inputString else {
                    XCTFail("No result found")
                    return
                }
                
                XCTAssertTrue(inputString == queryWithResultList.inputString)
                
                // Let's check if we have 2 test results
                guard let firstResult = results?.first, let secondResult = results?[1] else {
                    asyncExpectation.fulfill()

                    return
                }
                
                XCTAssertTrue(firstResult.quality >= secondResult.quality)
                
                asyncExpectation.fulfill()
            })
        }
        
        waitForExpectations(timeout: 3)
    }
    
    func testPreprocessStringSentence() {
        
        let preprocessedBagOfWods = MatchingEngineAlgortihm.preprocess(string: "The quick brown fox did jump over the fences.")
        
        XCTAssertFalse(preprocessedBagOfWods.isEmpty)
        XCTAssertTrue(preprocessedBagOfWods.contains("do"))
        XCTAssertTrue(preprocessedBagOfWods.contains("quick"))
    }
    
    func testPreprocessStringConjugations() {
        
        let preprocessedBagOfWods1 = MatchingEngineAlgortihm.preprocess(string: "I was going to the bakery.")
        let preprocessedBagOfWods2 = MatchingEngineAlgortihm.preprocess(string: "They are going to the bakery.")
        let preprocessedBagOfWods3 = MatchingEngineAlgortihm.preprocess(string: "We will be going to the bakery.")
        
        for bagOfWords in [preprocessedBagOfWods1, preprocessedBagOfWods2, preprocessedBagOfWods3] {
            XCTAssertFalse(bagOfWords.isEmpty)
            XCTAssertTrue(bagOfWords.contains("be"))
            XCTAssertTrue(bagOfWords.contains("go"))
            XCTAssertTrue(bagOfWords.contains("bakery"))
        }
    }
    
    func testPreprocessStringPlurals() {
        
        let preprocessedBagOfWods1 = MatchingEngineAlgortihm.preprocess(string: "Joshua, let's go see the trains.")
        let preprocessedBagOfWods2 = MatchingEngineAlgortihm.preprocess(string: "Let's do some train spotting.")
        let preprocessedBagOfWods3 = MatchingEngineAlgortihm.preprocess(string: "From which station are trains leaving for Dover?")
        
        for bagOfWords in [preprocessedBagOfWods1, preprocessedBagOfWods2, preprocessedBagOfWods3] {
            XCTAssertFalse(bagOfWords.isEmpty)
            XCTAssertTrue(bagOfWords.contains("train"))
        }
    }
    
}
