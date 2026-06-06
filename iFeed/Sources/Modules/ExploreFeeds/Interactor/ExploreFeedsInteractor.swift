//
//  ExploreFeedsInteractor.swift
//  iFeed
//
//  Created by Evgeny Karkan on 20.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation

@MainActor
final class ExploreFeedsInteractor {
    // MARK: - Properties
    private let results: ExploreFeedsDTO
    private let webPage: String
    private let parser: any ParserProtocol
    private let storage: any StorageProtocol

    private var parsingCompletion: ((Result<Feed, any Error>) -> Void)?
    private var parsingURL: String?

    // MARK: - Properties
    init(results: ExploreFeedsDTO,
         webPage: String,
         parser: any ParserProtocol,
         storage: any StorageProtocol) {
        self.results = results
        self.webPage = webPage
        self.parser = parser
        self.storage = storage
    }
}

// MARK: - ExploreFeedsInteractorProtocol
extension ExploreFeedsInteractor: ExploreFeedsInteractorProtocol {

    func getWebPageTitle() -> String {
        return webPage
    }

    /// Cross-references explore results with already saved feed URLs, returning display-ready models.
    func getResultsWithSavedStatus() -> [ExploreFeedsResult] {
        let savedURLs = storage.savedFeedURLs()

        // Normalizes each element's RSS URL via URL parsing, then checks whether
        // the normalized URL is already present among the user's saved feeds.
        return results.map { element in
            let isAlreadyStored = element.rssURL
                .flatMap { URL(string: $0)?.absoluteString }
                .map { savedURLs.contains($0) } ?? false
            return ExploreFeedsResult(data: element, isAdded: isAlreadyStored)
        }
    }

    func checkIfFeedIsAlreadySaved(with url: String) -> Bool {
        return storage.containsFeed(withRSSURL: url)
    }

    func saveContext() throws {
        storage.saveChanges()
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
        parsingURL = url

        parser.setDelegate(self)
        parser.beginParsingURL(feedURL)
    }
}

// MARK: - ParserDelegateProtocol
extension ExploreFeedsInteractor: ParserDelegateProtocol {

    func didEndParsingFeed(with data: ParsedFeedData) {
        guard let feed = storage.makeFeed() else {
            didFailParsingFeed(with: StorageError.feedCreationFailed)
            return
        }

        feed.title = data.title
        feed.rssURL = parsingURL ?? ""
        feed.summary = data.summary

        for itemData in data.items {
            guard let feedItem = storage.makeFeedItem() else {
                continue
            }
            feedItem.title = itemData.title
            feedItem.link = itemData.link
            feedItem.htmlContent = itemData.htmlContent
            feedItem.publishDate = itemData.publishDate

            /// Create a relationship
            feedItem.feed = feed
        }

        parsingCompletion?(.success(feed))
        parsingCompletion = nil
        parsingURL = nil
    }

    func didFailParsingFeed(with error: any Error) {
        parsingCompletion?(.failure(error))
        parsingCompletion = nil
        parsingURL = nil
    }

    func didCancelParsingFeed() {
        parsingCompletion = nil
        parsingURL = nil
    }
}
