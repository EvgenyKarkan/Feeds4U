//
//  Search.swift
//  iFeed
//
//  Created by Julius Bahr on 22.04.18.
//  Copyright © 2018 Evgeny Karkan. All rights reserved.
//

import Foundation
import SimpleSimilarityFramework

struct Search {
    
    private let matchingEngine = MatchingEngine()
    private let coreDataManager = EVKCoreDataManager()
    
    func fillMatchingEngine(completion: @escaping () -> Void) {
        // get all FeedItems
        let allFeedItems = coreDataManager.allFeedItems()
        
        // create a matching engine based on these feed items
        guard !allFeedItems.isEmpty else {
            return
        }
        
        let textualData = allFeedItems.map { (feedItem) -> TextualData in
            return TextualData(inputString: feedItem.title, origin: nil, originObject: feedItem)
        }
        
        matchingEngine.fillMatchingEngine(with: textualData, onlyRemoveFrequentStopwords: true, completion: completion)
    }
    
    func search(for searchTerm: String, resultsFound:([Result]?) -> Void) {
        guard matchingEngine.isFilled else {
            return
        }
        
        let query = TextualData(inputString: searchTerm, origin: nil, originObject: nil)
        
        try? matchingEngine.result(betterThan: 0.005, for: query, resultsFound: resultsFound)
    }
    
}
