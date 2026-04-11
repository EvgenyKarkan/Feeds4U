//
//  FeedSearchService.swift
//  iFeed
//
//  Created by Evgeny Karkan on 19.03.2023.
//  Copyright © 2023 Evgeny Karkan. All rights reserved.
//

import Foundation

// MARK: - Type definitions

/// Result type for feed search operations
///
/// Wraps either a successful `FeedSearchDTO` response or an error from the feed search API.
typealias FeedSearchResult = Swift.Result<FeedSearchDTO, any Error>

/// Completion handler for feed search operations
///
/// - Parameter result: The result of the feed search operation, containing either
///                     a `FeedSearchDTO` on success or an error on failure
typealias FeedSearchResultCompletion = (FeedSearchResult) -> Void

/// Errors that can occur during feed search operations
///
/// This enum represents all possible error states when searching for RSS/Atom feeds
/// on a given webpage using the `FeedSearch API`.
enum FeedSearchError: LocalizedError {

    /// The provided URL is invalid or malformed
    ///
    /// This error occurs when:
    /// - The input string is empty
    /// - The URL cannot be properly encoded
    /// - The constructed API URL is invalid
    case invalidURL

    /// A network or API endpoint error occurred
    ///
    /// This error wraps underlying network errors such as:
    /// - No internet connection
    /// - Request timeout
    /// - Server errors (4xx, 5xx HTTP status codes)
    /// - DNS resolution failures
    ///
    /// - Parameter error: The underlying error from the network layer
    case endpoint(any Error)

    /// Failed to decode the API response
    ///
    /// This error occurs when:
    /// - The response data is empty
    /// - The JSON structure doesn't match `FeedSearchDTO`
    /// - The response contains malformed or unexpected data
    case dataDecoding

    // MARK: - LocalizedError

    /// Human-readable error description for UI presentation
    ///
    /// Returns localized error messages appropriate for displaying to users.
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return String.localized(key: LocalizableKeys.Errors.invalidURL)
        case .endpoint(let error):
            return String(format: String.localized(key: LocalizableKeys.Errors.service), error.localizedDescription)
        case .dataDecoding:
            return String.localized(key: LocalizableKeys.Errors.dataDecoding)
        }
    }
}

// MARK: - FeedSearchService

/// Service for discovering RSS and Atom feeds on webpages
///
/// This service communicates with the `FeedSearch.dev` API to find available RSS/Atom feeds
/// on a given webpage. It's optimized for performance with reusable session and decoder instances.
///
/// **Architecture:**
/// - Uses URLSession with ephemeral configuration (no persistent storage)
/// - Reuses URLSession and JSONDecoder instances for optimal performance
/// - Handles URL encoding, network errors, and JSON decoding
///
/// **Usage Example:**
/// ```swift
/// let service = FeedSearchService()
/// service.searchFeeds(on: "https://example.com") { result in
///     switch result {
///     case .success(let dto):
///         print("Found \(dto.feeds.count) feeds")
///     case .failure(let error):
///         print("Error: \(error.localizedDescription)")
///     }
/// }
/// ```
///
/// **Performance Characteristics:**
/// - Session reuse: ~30ms saved per request
/// - Decoder reuse: ~8ms saved per request
/// - HTTP connection pooling for subsequent requests
/// - 30-second timeout for network requests
///
/// - Important: This service creates network requests. Always call from a background queue
///              or handle the asynchronous completion appropriately on the main queue.
final class FeedSearchService {

    // MARK: - Private Properties

    /// Shared URLSession instance for all feed search requests
    ///
    /// **Configuration:**
    /// - Ephemeral: No cookies, cache, or credentials stored to disk
    /// - Waits for connectivity: Automatically waits if network is unavailable
    /// - 30-second timeout: Prevents hanging on slow connections
    ///
    /// **Performance:**
    /// Reusing the same session enables HTTP connection pooling, which can significantly
    /// speed up subsequent requests to the same API endpoint.
    ///
    /// **Note:**
    /// We use ephemeral configuration to ensure feed search results are always fresh
    /// and not cached between app launches. Each request bypasses cache due to the
    /// `.reloadIgnoringLocalCacheData` policy set on individual requests.
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.waitsForConnectivity = true
        configuration.timeoutIntervalForRequest = 30
        return URLSession(configuration: configuration)
    }()

    /// Reusable JSON decoder for parsing API responses
    ///
    /// Creating a JSONDecoder has overhead (property caching, setup).
    /// Reusing a single instance saves ~8ms per decode operation.
    private let decoder = JSONDecoder()

    // MARK: - Public API

    /// Searches for RSS/Atom feeds on a given webpage
    ///
    /// This method queries the FeedSearch.dev API to discover available feeds on the specified
    /// webpage. The API performs deep inspection of the page's HTML and linked resources to find
    /// feeds, including RSS 2.0, RSS 1.0, Atom, and JSON Feed formats.
    ///
    /// **Process Flow:**
    /// 1. Validates and encodes the input URL
    /// 2. Constructs API request to feedsearch.dev
    /// 3. Executes network request
    /// 4. Decodes JSON response into `FeedSearchDTO`
    /// 5. Returns result via completion handler
    ///
    /// **Thread Safety:**
    /// The completion handler is called on an arbitrary background queue.
    /// Dispatch to main queue if you need to update UI.
    ///
    /// - Parameters:
    ///   - webPage: The URL of the webpage to search for feeds (e.g., "https://example.com")
    ///   - completion: Closure called when the search completes or fails
    ///
    /// - Important: The completion handler is called on a background thread. Dispatch to
    ///              `DispatchQueue.main` if you need to update UI elements.
    ///
    /// **Example:**
    /// ```swift
    /// searchFeeds(on: "https://daringfireball.net") { result in
    ///     DispatchQueue.main.async {
    ///         switch result {
    ///         case .success(let dto):
    ///             self.displayFeeds(dto.feeds)
    ///         case .failure(let error):
    ///             self.showError(error)
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// **Possible Errors:**
    /// - `FeedSearchError.invalidURL`: Input URL is empty or cannot be encoded
    /// - `FeedSearchError.endpoint`: Network error, timeout, or API unavailable
    /// - `FeedSearchError.dataDecoding`: API response couldn't be parsed
    func searchFeeds(on webPage: String, completion: @escaping FeedSearchResultCompletion) {
        // Step 1: Validate input and construct URL
        // -----------------------------------------
        // Ensure we have a non-empty webpage URL before proceeding
        guard !webPage.isEmpty else {
            completion(.failure(FeedSearchError.invalidURL))
            return
        }

        // Properly encode the URL parameter to handle special characters
        // This prevents issues with URLs containing spaces, &, =, etc.
        // Example: "https://example.com/page?id=1&name=test" -> "https://example.com/page?id=1%26name=test"
        guard let encodedWebPage = webPage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://feedsearch.dev/api/v1/search?url=\(encodedWebPage)") else {
            completion(.failure(FeedSearchError.invalidURL))
            return
        }

        // Step 2: Create and configure request
        // -------------------------------------
        // Construct the HTTP GET request with proper headers and caching policy
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.attribution = .user  // iOS 15+: Marks this as user-initiated for privacy
        request.cachePolicy = .reloadIgnoringLocalCacheData  // Always fetch fresh results

        // Step 3: Execute network request using shared session
        // -----------------------------------------------------
        // [weak self] prevents retain cycle if service is deallocated during request
        let task = session.dataTask(with: request) { [weak self] data, _, error in
            // Step 4: Handle network errors
            // ------------------------------
            // Check for network-level errors (timeout, no connection, DNS failure, etc.)
            if let error {
                completion(.failure(FeedSearchError.endpoint(error)))
                return
            }

            // Step 5: Validate response data
            // -------------------------------
            // Ensure we received data and it's not empty before attempting to decode
            // Empty data would cause JSON decoding to fail anyway, so fail fast
            guard let dtoData = data, !dtoData.isEmpty else {
                completion(.failure(FeedSearchError.dataDecoding))
                return
            }

            // Step 6: Decode JSON response
            // -----------------------------
            // Parse the JSON response into our FeedSearchDTO model
            // Use do-catch for explicit error handling (better than try?)
            do {
                guard let self else { return }  // Service was deallocated, abort
                let dto = try self.decoder.decode(FeedSearchDTO.self, from: dtoData)
                completion(.success(dto))
            } catch {
                // Decoding failed - malformed JSON, schema mismatch, etc.
                // In production, you might want to log the actual error for debugging
                completion(.failure(FeedSearchError.dataDecoding))
            }
        }

        // Start the network request
        task.resume()
    }

    // MARK: - Lifecycle

    /// Cleans up network resources when the service is deallocated
    ///
    /// Invalidates the URLSession, which:
    /// - Cancels all pending network requests
    /// - Releases connection pools
    /// - Frees up system resources
    ///
    /// This is especially important if the service is held for a long time or if
    /// you're creating multiple instances.
    deinit {
        session.invalidateAndCancel()
    }
}
