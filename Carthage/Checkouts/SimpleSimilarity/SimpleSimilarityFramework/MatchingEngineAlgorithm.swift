//
//  MatchingEngineAlgorithm.swift
//  SimpleSimilarityFramework
//
//  Created by Julius Bahr on 20.04.18.
//  Copyright © 2018 Julius Bahr. All rights reserved.
//

import Foundation

internal struct MatchingEngineAlgortihm {
    
    internal static func determineFrequentAndInfrequentWords(in set:NSCountedSet, onlyFrequent: Bool) -> Set<String> {
        var maxCount = 0
        var minCount = Int.max
        var medianCount = 0
        
        var stringsToRemove: Set<String> = []
        
        var stringCounts: [Int] = []
        
        set.objectEnumerator().allObjects.forEach { (string) in
            let stringCount = set.count(for: string)
            if stringCount > maxCount {
                maxCount = stringCount
            }
            if stringCount < minCount {
                minCount = stringCount
            }
            stringCounts.append(stringCount)
        }
        
        let sortedStringCounts = stringCounts.sorted()
        
        let stringCount = Double(sortedStringCounts.count)
        
        let midIndex = Int(floor(stringCount/2.0))
        medianCount = sortedStringCounts[midIndex]
        
        // the top 5% of words are considered frequent
        let cutOffTop = Int(floor(Double(maxCount) * 0.9))
        // the bottom XX% of words are considered infrequent
        let cutOffBottom = Int(floor(Double(minCount) * 2.0))
        
        set.objectEnumerator().allObjects.forEach { (string) in
            guard string is String else {
                return
            }
            
            let stringCount = set.count(for: string)
            if stringCount > cutOffTop {
                stringsToRemove.insert(string as! String)
            }
            if !onlyFrequent && (stringCount < cutOffBottom) {
                stringsToRemove.insert(string as! String)
            }
        }
        
        return stringsToRemove
    }
    
    internal static func preprocess(string: String, stemmer: NSLinguisticTagger = NSLinguisticTagger(tagSchemes: [.lemma], options: 0)) -> Set<String> {
        var bagOfWords: Set<String> = Set()
        var tokenRanges: NSArray?
        
        stemmer.string = string
        // TODO: would probably be better to enumerate over the string
        let stemmedWords = stemmer.tags(in: NSRange(location: 0, length: string.utf16.count), unit: .word, scheme: .lemma, options: [.omitWhitespace, .omitOther, .omitPunctuation], tokenRanges: &tokenRanges)
        
        var i = 0
        
        while i < stemmedWords.count {
            let tag = stemmedWords[i]
            
            let preprocessedWord = tag.rawValue.lowercased()
            if !preprocessedWord.isEmpty {
                bagOfWords.insert(preprocessedWord)
            } else {
                // if the string cannot be lemmatized add the original value, this only works for latin scripts
                let words = string.components(separatedBy: " ")
                if i < words.count {
                    bagOfWords.insert(words[i].lowercased())
                }
            }
            
            i += 1
        }
        
        return bagOfWords
    }
    
    /// Removes the stopwords from the given bag of words
    ///
    /// - Parameters:
    ///   - stopwords: the stopwords to remove
    ///   - bagOfWords: the bag of words
    /// - Returns: the bag of words without stopwords
    /// - Note: It may seem counterintuitive at first. It is much faster to check if a word is a stopword and to remove it. The reason for this is that the set of stopwords is much larger then the given bag of words.
    internal static func remove(stopwords: Set<String>, from bagOfWords:Set<String>) -> Set<String> {
        var bagOfWordsWithoutStopwords = Set<String>()
        for word in bagOfWords {
            if !stopwords.contains(word) {
                bagOfWordsWithoutStopwords.insert(word)
            }
        }
        
        return bagOfWordsWithoutStopwords
    }
    
}
