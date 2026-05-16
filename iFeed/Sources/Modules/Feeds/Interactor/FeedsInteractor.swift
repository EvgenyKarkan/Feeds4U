//
//  FeedsInteractor.swift
//  iFeed
//
//  Created by Evgeny Karkan on 30.04.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation
import CoreData.NSManagedObjectID

final class FeedsInteractor {
    // MARK: - Properties
    private let parser: any ParserProtocol
    private let storage: any StorageProtocol
    private var localSearchService: any Searchable
    private let exploreFeedsService: any ExploreFeedsServiceProtocol

    private var parsingCompletion: ((Result<Feed, any Error>) -> Void)?

    // MARK: - Init
    init(parser: any ParserProtocol,
         storage: any StorageProtocol,
         localSearchService: any Searchable,
         exploreFeedsService: any ExploreFeedsServiceProtocol) {
        self.parser = parser
        self.storage = storage
        self.localSearchService = localSearchService
        self.exploreFeedsService = exploreFeedsService
    }
}

// MARK: - FeedsInteractorProtocol
extension FeedsInteractor: FeedsInteractorProtocol {

    func getAllFeeds() -> [Feed] {
        return storage.loadFeeds()
    }

    func checkIfFeedIsAlreadySaved(with url: String) -> Bool {
        return storage.containsFeed(withRSSURL: url)
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
                      completion: @escaping ExploreFeedsServiceResultCompletion) {
        exploreFeedsService.searchFeeds(on: webSite, completion: completion)
    }

    func feedForIndexPath(_ indexPath: IndexPath) -> Feed? {
        return storage.feed(at: indexPath)
    }

    func unreadCountsByFeed() -> [NSManagedObjectID: Int] {
        return storage.unreadCountsByFeed()
    }

    func saveContext() throws {
        storage.saveChanges()
    }

    func deleteFeed(_ feed: Feed) {
        storage.delete(feed)
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
