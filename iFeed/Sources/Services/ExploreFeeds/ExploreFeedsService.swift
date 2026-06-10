//
//  ExploreFeedsService.swift
//  iFeed
//
//  Created by Evgeny Karkan on 19.03.2023.
//  Copyright © 2023 Evgeny Karkan. All rights reserved.
//

import Foundation
#if DEBUG
import Mocking
#endif

// MARK: - Type definitions

typealias ExploreFeedsServiceResult = Swift.Result<ExploreFeedsDTO, any Error>
typealias ExploreFeedsServiceResultCompletion = @Sendable (ExploreFeedsServiceResult) -> Void

/// Errors that can occur during feed search operations
enum ExploreFeedsError: LocalizedError {

    /// The provided URL is invalid or malformed
    case invalidURL

    /// A network or API error occurred, wrapping the underlying error
    case endpoint(any Error)

    /// Failed to decode the API response (empty body or unexpected JSON structure)
    case dataDecoding

    /// The request was blocked by Cloudflare protection and the user cancelled the challenge
    case cloudflareBlocked

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return String.localized(key: LocalizableKeys.Errors.invalidURL)
        case .endpoint(let error):
            return String(format: String.localized(key: LocalizableKeys.Errors.service), error.localizedDescription)
        case .dataDecoding:
            return String.localized(key: LocalizableKeys.Errors.dataDecoding)
        case .cloudflareBlocked:
            return String.localized(key: LocalizableKeys.Errors.cloudflareBlocked)
        }
    }
}

// MARK: - ExploreFeedsServiceProtocol

/// Abstracts feed search functionality for dependency injection and testing.
#if DEBUG
@Mocked(compilationCondition: .debug)
#endif
protocol ExploreFeedsServiceProtocol {

    /// Searches for RSS/Atom feeds on a given webpage (completion-based wrapper around the async variant).
    ///
    /// - Important: The completion handler may be called on a background thread.
    func searchFeeds(on webPage: String, completion: @escaping ExploreFeedsServiceResultCompletion)

    /// Searches for RSS/Atom feeds on a given webpage.
    ///
    /// Queries the FeedSearch.dev API to discover RSS 2.0, RSS 1.0, Atom, and JSON Feed URLs
    /// available on the specified webpage.
    ///
    /// - Parameter webPage: The URL of the webpage to search (e.g., "https://example.com")
    /// - Returns: An `ExploreFeedsDTO` containing the discovered feeds
    /// - Throws: `ExploreFeedsError` if the URL is invalid, the network request fails, or decoding fails
    func searchFeeds(on webPage: String) async throws -> ExploreFeedsDTO
}

// MARK: - ExploreFeedsService

/// Discovers RSS/Atom feeds on webpages via the FeedSearch.dev API.
///
/// Uses an ephemeral `URLSession` (no persistent cookies/cache) with a 30-second timeout.
/// Both the session and `JSONDecoder` are reused across requests for connection pooling
/// and reduced allocation overhead.
final class ExploreFeedsService: @unchecked Sendable {

    // MARK: - Private Properties

    /// Ephemeral session — no disk cache, waits for connectivity, 30s timeout.
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.waitsForConnectivity = true
        configuration.timeoutIntervalForRequest = 30
        return URLSession(configuration: configuration)
    }()

    private let decoder = JSONDecoder()

    // MARK: - Lifecycle

    deinit {
        session.invalidateAndCancel()
    }
}

// MARK: - ExploreFeedsServiceProtocol Conformance

extension ExploreFeedsService: ExploreFeedsServiceProtocol {

    /// Completion-based wrapper — delegates to the async variant.
    func searchFeeds(on webPage: String, completion: @escaping ExploreFeedsServiceResultCompletion) {
        Task { [weak self] in
            guard let self else {
                /// The service was deallocated, so its owning module is gone and
                /// nobody is left to present a result. Reporting `.dataDecoding`
                /// here (as before) would surface a misleading "can't parse data"
                /// alert — dropping the request silently is the honest outcome.
                return
            }
            do {
                let dto = try await self.searchFeeds(on: webPage)
                completion(.success(dto))
            } catch let error as ExploreFeedsError {
                completion(.failure(error))
            } catch {
                completion(.failure(ExploreFeedsError.endpoint(error)))
            }
        }
    }

    /// Queries FeedSearch.dev for RSS/Atom/JSON Feed URLs found on `webPage`.
    ///
    /// - Parameter webPage: The webpage URL to scan (e.g., "https://example.com")
    /// - Returns: An `ExploreFeedsDTO` with discovered feeds
    /// - Throws: `ExploreFeedsError.invalidURL` if the URL is empty or malformed,
    ///           `.endpoint` on network failure, `.dataDecoding` if the response can't be parsed
    func searchFeeds(on webPage: String) async throws -> ExploreFeedsDTO {
        guard !webPage.isEmpty else {
            throw ExploreFeedsError.invalidURL
        }

        guard let encodedWebPage = webPage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://feedsearch.dev/api/v1/search?url=\(encodedWebPage)") else {
            throw ExploreFeedsError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.attribution = .user
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let data: Data
        do {
            (data, _) = try await session.data(for: request)
        } catch {
            throw ExploreFeedsError.endpoint(error)
        }

        guard !data.isEmpty else {
            throw ExploreFeedsError.dataDecoding
        }

        do {
            return try decoder.decode(ExploreFeedsDTO.self, from: data)
        } catch {
            throw ExploreFeedsError.dataDecoding
        }
    }
}
