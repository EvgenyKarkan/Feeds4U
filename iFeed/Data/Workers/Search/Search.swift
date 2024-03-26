//
//  Search.swift
//  iFeed
//
//  Created by Julius Bahr on 22.04.18.
//  Copyright © 2018 Evgeny Karkan. All rights reserved.
//

import Foundation

/// Performs local search

struct Search {

    private var matchingEngine: MatchingEngine?
    private let coreDataManager = Brain.brain.coreDater

    mutating func fillMatchingEngine(completion: @escaping () -> Void) {
        /// Get all FeedItems
        guard let allFeedItems = coreDataManager.allFeedItems(), !allFeedItems.isEmpty else {
            completion()
            return
        }

        /// Create a matching engine based on these feed items
        let textualData = allFeedItems.map { (feedItem) -> TextualData in
            return TextualData(inputString: feedItem.title,
                               origin: nil,
                               originObject: feedItem)
        }

        matchingEngine = MatchingEngine()
        matchingEngine?.fillMatchingEngine(with: textualData,
                                           onlyRemoveFrequentStopwords: true,
                                           completion: completion)
    }

    func search(for searchTerm: String, resultsFound: ([FeedItem]?) -> Void) {
        guard matchingEngine?.isFilled ?? false else {
            resultsFound(nil)
            return
        }

        let query = TextualData(inputString: searchTerm,
                                origin: nil,
                                originObject: nil)

        try? matchingEngine?.results(betterThan: 0.005, for: query, resultsFound: { (results) in
            if let results = results, !results.isEmpty {
                var feedItems: [FeedItem] = []

                /// We need to convert back the textual matches to the originating FeedItems
                results.forEach { (result) in
                    result.textualResults.forEach { (textualData) in
                        if let originObject = textualData.originObject as? FeedItem {
                            feedItems.append(originObject)
                        } else {
                            print("Unable to convert result back to FeedItem.")
                        }
                    }
                }

                /// Sort by date
                let sortedItems = feedItems.sorted(by: { (item1: FeedItem, item2: FeedItem) -> Bool in
                    return item1.publishDate > item2.publishDate
                })

                resultsFound(sortedItems)
            } else {
                resultsFound(nil)
            }
        })
    }
}
