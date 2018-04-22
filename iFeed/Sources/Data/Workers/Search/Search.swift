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
    
    private var matchingEngine: MatchingEngine = MatchingEngine()
    
    // TODO: need to pass in completion block
    func fillMatchingEngine() {
        // get all FeedItems
        let allFeedItems = EVKCoreDataManager().allFeedItems()
        
        // create a matching engine based on these feed items
        guard !allFeedItems.isEmpty else {
            return
        }
        
        let textualData = allFeedItems.map { (feedItem) -> TextualData in
            return TextualData(inputString: feedItem.title, origin: nil, originObject: feedItem)
        }
        
        matchingEngine.fillMatchingEngine(with: textualData, completion: {
            
        })
    }
    
    // TODO: need to pass in completion block
    func search(for searchTerm: String) {
        guard matchingEngine.isFilled else {
            return
        }
        
        let query = TextualData(inputString: searchTerm, origin: nil, originObject: nil)
        
        try? matchingEngine.result(betterThan: 0.05, for: query, resultsFound: { (result) in
            
        })
    }
    
    
}
