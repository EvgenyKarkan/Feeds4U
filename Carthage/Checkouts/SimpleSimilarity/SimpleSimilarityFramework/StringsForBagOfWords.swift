//
//  StringsForBagOfWords.swift
//  SimpleSimilarityFramework
//
//  Created by Julius Bahr on 19.02.18.
//  Copyright © 2018 Julius Bahr. All rights reserved.
//

import Foundation

/// Mapping of bag of words to the originating string that resulted in the same bag of words
internal struct StringsForBagsOfWords {
    private var stringsForBagOfWords: [Set<String>:[CorpusEntry]] = [:]
    
    /// All corpus entries that share the same bag of words
    internal func strings(for bagOfWords: Set<String>) -> [CorpusEntry]? {
        return stringsForBagOfWords[bagOfWords]
    }

    /// Adds a corpus entry
    ///
    /// - Parameter corpusEntry: the corpus entry to add
    internal mutating func add(corpusEntry: CorpusEntry) {
        let existingEntryForBagOfWords = stringsForBagOfWords[corpusEntry.bagOfWords]
        
        if var localExistingEntryForBagOfWords = existingEntryForBagOfWords {
            localExistingEntryForBagOfWords.append(corpusEntry)
            stringsForBagOfWords[corpusEntry.bagOfWords] = localExistingEntryForBagOfWords
        } else {
            stringsForBagOfWords[corpusEntry.bagOfWords] = [corpusEntry]
        }
    }
}
