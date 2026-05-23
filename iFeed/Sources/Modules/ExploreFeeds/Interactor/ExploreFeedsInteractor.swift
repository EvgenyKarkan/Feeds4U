//
//  ExploreFeedsInteractor.swift
//  iFeed
//
//  Created by Evgeny Karkan on 20.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation

final class ExploreFeedsInteractor {
    // MARK: - Properties
    private let results: ExploreFeedsDTO
    private let webPage: String
    private let parser: any ParserProtocol
    private let storage: any StorageProtocol

    private var parsingCompletion: ((Result<Feed, any Error>) -> Void)?

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

        parser.setDelegate(self)
        parser.beginParsingURL(feedURL)
    }
}

// MARK: - ParserDelegateProtocol
extension ExploreFeedsInteractor: ParserDelegateProtocol {

    func didEndParsingFeed(_ feed: Feed) {
        parsingCompletion?(.success(feed))
        parsingCompletion = nil
    }

    func didFailParsingFeed() {
        let error = NSError(domain: #function, code: #line)
        parsingCompletion?(.failure(error))
        parsingCompletion = nil
    }
}
