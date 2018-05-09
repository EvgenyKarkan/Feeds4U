//
//  MatchingEngine.swift
//  SimpleSimilarityFramework
//
//  Created by Julius Bahr on 17.09.17.
//  Copyright © 2017 Julius Bahr. All rights reserved.
//

import Foundation

/// Error object thrown when the matching engine has not been filled with textual data
public struct MatchingEngineNotFilledError: Error {}

/// Error object thrown when a parameter value is not within valid bounds
public struct InvalidArgumentValueError: Error {}

/// The result for a given query
public struct Result {
    public let textualResults: [TextualData]
    public let quality: Float
}

/// A processed entry in the corpus
/// It contains the source string and the preprocessed representaion
open class CorpusEntry: Hashable {
    let textualData: TextualData
    var bagOfWords: Set<String>
    
    init(textualData: TextualData, bagOfWords: Set<String>) {
        self.textualData = textualData
        self.bagOfWords = bagOfWords
    }
    
    public var hashValue: Int {
        return textualData.hashValue
    }
    
    public static func ==(lhs: CorpusEntry, rhs: CorpusEntry) -> Bool {
        return lhs.textualData == rhs.textualData
    }
}

open class MatchingEngine {

    public private(set) var isFilled = false

    /// All words in the corpus with their occurence
    fileprivate var allWords: NSCountedSet = NSCountedSet()
    fileprivate var corpus: Set<CorpusEntry> = Set()
    fileprivate var stopwords: Set<String> = Set()
    fileprivate var stringsForBagsOfWords = StringsForBagsOfWords()

    public init() {
        
    }

    /// - Returns: a normalized represenation of the text corpus
    /// - Throws: a MatchingEngineNotFilledError when normalizedRepresentation() is called before fillMatchingEngine()
    /// - Precondition: you must first call fillMatchingEngine()
//    open func normalizedRepresentation() throws -> [CorpusEntry]  {
//        return []
//    }

    
    /// Fill the matching engine with textual data
    ///
    /// - Parameters:
    ///   - corpus: the text corpus that is the backing store of the matching engine
    ///   - onlyRemoveFrequentStopwords: set to true when you only want to remove frequent words but not infrequent ones, default value is false
    ///   - completion: completion block called when the matching engine is filled
    open func fillMatchingEngine(with corpus:[TextualData], onlyRemoveFrequentStopwords: Bool = false, completion: @escaping () -> Void) {
        isFilled = false
        
        DispatchQueue.global().async {
            var processedCorpus: Set<CorpusEntry> = Set()
            var allPreprocessedEntries: Array<CorpusEntry> = Array()

            let stemmer = NSLinguisticTagger(tagSchemes: [.lemma], options: 0)

            // stem words
            corpus.forEach({ [weak self] (textualData) in
                if let strongSelf = self {
                    let bagOfWords = MatchingEngineAlgortihm.preprocess(string: textualData.inputString, stemmer: stemmer)
                    
                    let newEntry = CorpusEntry(textualData: textualData, bagOfWords: bagOfWords)
                    
                    allPreprocessedEntries.append(newEntry)
                    processedCorpus.insert(newEntry)
                    
                    for word in bagOfWords {
                        strongSelf.allWords.add(word)
                    }
                }
            })
            
            // determine frequent and infrequent words
            self.stopwords = MatchingEngineAlgortihm.determineFrequentAndInfrequentWords(in: self.allWords, onlyFrequent: onlyRemoveFrequentStopwords)
            
            // create dispatch group so removal of stopwords can happen on 2 seperate queues
            let localStopwords = self.stopwords
            let dispatchGroup = DispatchGroup()
            
            // remove infrequent and frequent words
            dispatchGroup.enter()
            DispatchQueue.global().async {
                processedCorpus.forEach({ (corpusEntry) in
                    corpusEntry.bagOfWords = MatchingEngineAlgortihm.remove(stopwords: localStopwords, from: corpusEntry.bagOfWords)
                })
                
                dispatchGroup.leave()
            }
            
            // create a mapping of a bag of words to the strings that generate the same bag of words
            dispatchGroup.enter()
            DispatchQueue.global().async {
                allPreprocessedEntries.forEach({ [weak self] (corpusEntry) in
                    // unfortunately we need to remove the stopwords again here
                    corpusEntry.bagOfWords = MatchingEngineAlgortihm.remove(stopwords: localStopwords, from: corpusEntry.bagOfWords)
                    
                    self?.stringsForBagsOfWords.add(corpusEntry: corpusEntry)
                })
                
                dispatchGroup.leave()
            }

            // wait till the 2 dispatch queues finished executing
            dispatchGroup.wait()
            
            self.isFilled = true
            self.corpus = processedCorpus

            completion()
        }
    }

    /// Get the best result for the given query
    ///
    /// - Parameters:
    ///   - query: the query object for which the best match in the matching engine is retrieved
    ///   - exhaustive: the whole textual corpus is scanned, if is false only the first best match is returned
    ///   - resultFound: closure that is called once the best result is found
    /// - Throws: a MatchingEngineNotFilledError when bestResult() is called before fillMatchingEngine()
    /// - Precondition: you must first call fillMatchingEngine()
    open func bestResult(for query: TextualData, exhaustive: Bool, resultFound:(Result?) -> Void) throws {
        guard isFilled == true else {
            throw MatchingEngineNotFilledError()
        }
        
        var queryBagOfWords = MatchingEngineAlgortihm.preprocess(string: query.inputString)
        queryBagOfWords = queryBagOfWords.subtracting(stopwords)
        
        var percentageOfBestResult: Float = 0.0
        var bestMatchInCorpus: CorpusEntry?
        
        for corpusEntry in corpus {
            let intersection = corpusEntry.bagOfWords.intersection(queryBagOfWords)
            
            let percentage: Float = Float(intersection.count) / Float(queryBagOfWords.count)
            
            if percentage > 0.5 && !exhaustive {
                guard let originatingStrings = stringsForBagsOfWords.strings(for: corpusEntry.bagOfWords), !originatingStrings.isEmpty else {
                    assert(false, "Unexpected state: If we find a match in the matching engine we also need to find original strings for a bag of words of a corpus entry")
                    
                    resultFound(nil)
                    return
                }
                
                let textualResults = originatingStrings.map({ (corpusEntry) -> TextualData in
                    return corpusEntry.textualData
                })
                
                resultFound(Result(textualResults: textualResults, quality: percentage))
                return
            }
            
            if percentageOfBestResult < percentage {
                percentageOfBestResult = percentage
                bestMatchInCorpus = corpusEntry
            }
        }
        
        if let bestMatchInCorpus = bestMatchInCorpus {
            guard let originatingStrings = stringsForBagsOfWords.strings(for: bestMatchInCorpus.bagOfWords), !originatingStrings.isEmpty else {
                assert(false, "Unexpected state: If we find a match in the matching engine we also need to find original strings for a bag of words of a corpus entry")
                
                resultFound(nil)
                return
            }
            
            let textualResults = originatingStrings.map({ (corpusEntry) -> TextualData in
                return corpusEntry.textualData
            })
            
            resultFound(Result(textualResults: textualResults, quality: percentageOfBestResult))
        } else {
            resultFound(nil)
        }
    }
    
    /// Get's the best results for a given query
    ///
    /// - Parameters:
    ///   - betterThan: the threshold for the quality of results. Valid results are within in 0.0 and 1.0
    ///   - query: the query object for which the best match in the matching engine is retrieved
    ///   - resultsFound: closure called when the matches with a quality higher than betterThan are found
    /// - Throws: a MatchingEngineNotFilledError when bestResult() is called before fillMatchingEngine(), a InvalidArgumentValueError when betterThan has an illegal value
    /// - Precondition: you must first call fillMatchingEngine()
    open func result(betterThan: Float, for query: TextualData, resultsFound:([Result]?) -> Void) throws {
        guard isFilled == true else {
            throw MatchingEngineNotFilledError()
        }
        
        var queryBagOfWords = MatchingEngineAlgortihm.preprocess(string: query.inputString)
        queryBagOfWords = queryBagOfWords.subtracting(stopwords)
        
        var matchesInCorpus: [Result] = []
        
        for corpusEntry in corpus {
            let intersection = corpusEntry.bagOfWords.intersection(queryBagOfWords)
            
            let percentage: Float = Float(intersection.count) / Float(queryBagOfWords.count)
            
            if percentage >= betterThan {
                guard let originatingStrings = stringsForBagsOfWords.strings(for: corpusEntry.bagOfWords), !originatingStrings.isEmpty else {
                    assert(false, "Unexpected state: If we find a match in the matching engine we also need to find original strings for a bag of words of a corpus entry")
                    
                    resultsFound(nil)
                    return
                }
                
                let textualResults = originatingStrings.map({ (corpusEntry) -> TextualData in
                    return corpusEntry.textualData
                })
                
                matchesInCorpus.append(Result(textualResults: textualResults, quality: percentage))
            }
        }
        
        if matchesInCorpus.isEmpty {
            resultsFound(nil)
        } else {
            matchesInCorpus.sort { (first, second) -> Bool in
                if first.quality >= second.quality {
                    return true
                } else {
                    return false
                }
            }
            resultsFound(matchesInCorpus)
        }
    }

}
