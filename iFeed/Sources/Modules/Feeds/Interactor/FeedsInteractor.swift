//
//  FeedsInteractor.swift
//  iFeed
//
//  Created by Evgeny Karkan on 30.04.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation

final class FeedsInteractor {
    // MARK: - Properties
    private let parser: any ParserProtocol
    private let coreDataService: any StorageProtocol
    private var localSearchService: any Searchable
    private let exploreFeedsService: any FeedSearchServiceProtocol

    private var parsingCompletion: ((Result<Feed, any Error>) -> Void)?

    // MARK: - Init
    init(parser: any ParserProtocol,
         coreDataService: any StorageProtocol,
         localSearchService: any Searchable,
         exploreFeedsService: any FeedSearchServiceProtocol) {
        self.parser = parser
        self.coreDataService = coreDataService
        self.localSearchService = localSearchService
        self.exploreFeedsService = exploreFeedsService
    }
}

// MARK: - FeedsInteractorProtocol
extension FeedsInteractor: FeedsInteractorProtocol {

    func getAllFeeds() -> [Feed] {
        return coreDataService.allFeeds()
    }

    func checkIfFeedIsAlreadySaved(with url: String) -> Bool {
        return coreDataService.isAlreadySavedURL(url)
    }

    func startParsingFeed(_ url: String, completion: @escaping (Result<Feed, any Error>) -> Void) {
        enum ParsingError: Error {
            case invalidURL
        }

        guard !url.isEmpty, let feedURL = URL(string: url) else {
            completion(.failure(ParsingError.invalidURL))
            return
        }

        parsingCompletion = completion

        parser.setDelegate(self)
        parser.beginParsingURL(feedURL)
    }

    func fillSearchMatchingEngine(completion: @escaping () -> Void) {
        localSearchService.fillMatchingEngine(completion: completion)
    }

    func performSearch(by searchTerm: String,
                       completion: @escaping ([FeedItem]?) -> Void) {
        localSearchService.search(for: searchTerm, resultsFound: completion)
    }

    func exploreFeeds(on webSite: String,
                      completion: @escaping FeedSearchResultCompletion) {
        exploreFeedsService.searchFeeds(on: webSite, completion: completion)
    }

    func feedForIndexPath(_ indexPath: IndexPath) -> Feed? {
        return coreDataService.feedForIndexPath(indexPath)
    }

    func saveContext() throws {
        coreDataService.saveContext()
    }

    func deleteFeed(_ feed: Feed) {
        coreDataService.deleteObject(feed)
        try? saveContext()
    }
}

// MARK: - ParserDelegateProtocol
extension FeedsInteractor: ParserDelegateProtocol {

    func didEndParsingFeed(_ feed: Feed) {
        parsingCompletion?(.success(feed))
    }

    func didFailParsingFeed() {
        let error = NSError(domain: #function, code: #line)
        parsingCompletion?(.failure(error))
    }
}
