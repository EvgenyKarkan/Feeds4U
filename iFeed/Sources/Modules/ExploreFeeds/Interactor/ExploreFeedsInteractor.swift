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
    private let localSearchService: any Searchable

    private var parsingCompletion: ((Result<Feed, any Error>) -> Void)?
    private var parsingURL: String?

    // MARK: - Properties
    init(results: ExploreFeedsDTO,
         webPage: String,
         parser: any ParserProtocol,
         storage: any StorageProtocol,
         localSearchService: any Searchable) {
        self.results = results
        self.webPage = webPage
        self.parser = parser
        self.storage = storage
        self.localSearchService = localSearchService
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

    /// Hands the parsed data to storage, which creates and saves the feed with
    /// all its items on a background context — large imports no longer stall
    /// the main thread. The completion fires back on the main actor.
    func didEndParsingFeed(with data: ParsedFeedData) {
        /// Nobody is waiting for the result (e.g. the parse was cancelled) — skip the import.
        /// The URL is unwrapped here rather than defaulted: `rssURL` is the feed's
        /// identity, and persisting a feed with an empty URL would silently break
        /// refresh, duplicate detection, and folder membership. If the invariant
        /// "completion and URL are set together" ever breaks, fail loudly instead.
        guard parsingCompletion != nil, let rssURL = parsingURL else {
            parsingCompletion?(.failure(StorageError.feedCreationFailed))
            parsingCompletion = nil
            parsingURL = nil
            return
        }

        storage.importFeed(data, rssURL: rssURL) { [weak self] feedID in
            /// Storage contractually delivers this callback on the main actor
            /// (see `StorageProtocol.importFeed`).
            MainActor.assumeIsolated {
                guard let self else {
                    return
                }

                if let feedID, let feed = self.storage.loadFeed(withID: feedID) {
                    /// The corpus changed — the search index must be rebuilt before the next query.
                    self.localSearchService.markIndexDirty()
                    self.parsingCompletion?(.success(feed))
                } else {
                    self.parsingCompletion?(.failure(StorageError.feedCreationFailed))
                }
                self.parsingCompletion = nil
                self.parsingURL = nil
            }
        }
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
