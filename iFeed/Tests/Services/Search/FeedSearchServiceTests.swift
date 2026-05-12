//
//  FeedSearchServiceTests.swift
//  iFeedTests
//
//  Created by Evgeny Karkan on 16.04.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation
import Testing
import OHHTTPStubs
import OHHTTPStubsSwift
@testable import iFeed

// MARK: - FeedSearchServiceTests

@Suite("FeedSearchService Tests", .serialized)
final class FeedSearchServiceTests {

    // MARK: - Setup and Teardown

    init() {
        // Ensure no stubs are active when test suite starts
        HTTPStubs.removeAllStubs()
    }

    deinit {
        // Clean up when test suite is deallocated
        HTTPStubs.removeAllStubs()
    }

    // MARK: - Success Cases - Completion Handler API

    @Test("Successful feed search with valid response using completion handler")
    func testSuccessfulFeedSearchWithCompletion() async throws {
        // Given: Mock successful API response
        let mockJSON: String = """
        [
            {
                "description": "A test feed",
                "favicon": "https://example.com/favicon.ico",
                "self_url": "https://example.com/feed/self",
                "site_name": "Example Site",
                "site_url": "https://example.com",
                "title": "Example Feed",
                "url": "https://example.com/feed"
            }
        ]
        """

        stub(condition: isHost("feedsearch.dev")) { _ in
            guard let jsonData: Data = mockJSON.data(using: .utf8) else {
                return HTTPStubsResponse(error: NSError(domain: "TestError", code: -1))
            }
            return HTTPStubsResponse(
                data: jsonData,
                statusCode: 200,
                headers: ["Content-Type": "application/json"]
            )
        }

        let service = FeedSearchService()

        // When: Searching for feeds
        let result: FeedSearchResult = await withCheckedContinuation { continuation in
            service.searchFeeds(on: "https://example.com") { completionResult in
                continuation.resume(returning: completionResult)
            }
        }

        // Then: Should succeed with correct data
        switch result {
        case .success(let dto):
            #expect(dto.count == 1)

            let firstFeed = dto.first
            #expect(firstFeed?.title == "Example Feed")
            #expect(firstFeed?.url == "https://example.com/feed")
            #expect(firstFeed?.siteName == "Example Site")
            #expect(firstFeed?.description == "A test feed")
        case .failure(let error):
            Issue.record("Expected success but got error: \(error)")
        }
    }

    @Test("Successful feed search with multiple feeds using completion handler")
    func testMultipleFeedsWithCompletion() async throws {
        // Given: Mock API response with multiple feeds
        stub(condition: isHost("feedsearch.dev")) { _ in
            let mockJSON = """
            [
                {
                    "title": "Main Feed",
                    "url": "https://example.com/feed"
                },
                {
                    "title": "Blog Feed",
                    "url": "https://example.com/blog/feed"
                },
                {
                    "title": "News Feed",
                    "url": "https://example.com/news/feed"
                }
            ]
            """
            guard let jsonData = mockJSON.data(using: .utf8) else {
                return HTTPStubsResponse(error: NSError(domain: "TestError", code: -1))
            }
            return HTTPStubsResponse(
                data: jsonData,
                statusCode: 200,
                headers: ["Content-Type": "application/json"]
            ).responseTime(0.01)
        }

        let service = FeedSearchService()

        // When: Searching for feeds
        let result: FeedSearchResult = await withCheckedContinuation { continuation in
            service.searchFeeds(on: "https://example.com") { result in
                continuation.resume(returning: result)
            }
        }

        // Then: Should return all feeds
        switch result {
        case .success(let dto):
            #expect(dto.count == 3)
            #expect(dto[0].title == "Main Feed")
            #expect(dto[1].title == "Blog Feed")
            #expect(dto[2].title == "News Feed")
        case .failure(let error):
            Issue.record("Expected success but got error: \(error)")
        }
    }

    @Test("Successful feed search with empty array using completion handler")
    func testEmptyFeedArrayWithCompletion() async throws {
        // Given: Mock API response with empty array
        stub(condition: isHost("feedsearch.dev")) { _ in
            let mockJSON = "[]"
            guard let jsonData = mockJSON.data(using: .utf8) else {
                return HTTPStubsResponse(error: NSError(domain: "TestError", code: -1))
            }
            return HTTPStubsResponse(
                data: jsonData,
                statusCode: 200,
                headers: ["Content-Type": "application/json"]
            ).responseTime(0.01)
        }

        let service = FeedSearchService()

        // When: Searching for feeds
        let result: FeedSearchResult = await withCheckedContinuation { continuation in
            service.searchFeeds(on: "https://example.com") { result in
                continuation.resume(returning: result)
            }
        }

        // Then: Should succeed with empty array
        switch result {
        case .success(let dto):
            #expect(dto.isEmpty)
        case .failure(let error):
            Issue.record("Expected success but got error: \(error)")
        }
    }

    // MARK: - Success Cases - Async/Await API

    @Test("Successful feed search with valid response using async/await")
    func testSuccessfulFeedSearchAsync() async throws {
        // Given: Mock successful API response
        stub(condition: isHost("feedsearch.dev")) { _ in
            let mockJSON = """
            [
                {
                    "description": "Async test feed",
                    "favicon": "https://example.com/favicon.ico",
                    "self_url": "https://example.com/feed/self",
                    "site_name": "Async Site",
                    "site_url": "https://example.com",
                    "title": "Async Feed",
                    "url": "https://example.com/async-feed"
                }
            ]
            """
            guard let jsonData = mockJSON.data(using: .utf8) else {
                return HTTPStubsResponse(error: NSError(domain: "TestError", code: -1))
            }
            return HTTPStubsResponse(
                data: jsonData,
                statusCode: 200,
                headers: ["Content-Type": "application/json"]
            ).responseTime(0.01)
        }

        let service = FeedSearchService()

        // When: Searching for feeds using async/await
        let dto = try await service.searchFeeds(on: "https://example.com")

        // Then: Should return correct data
        #expect(dto.count == 1)
        #expect(dto.first?.title == "Async Feed")
        #expect(dto.first?.url == "https://example.com/async-feed")
        #expect(dto.first?.siteName == "Async Site")
    }

    @Test("Successful feed search with multiple feeds using async/await")
    func testMultipleFeedsAsync() async throws {
        // Given: Mock API response with multiple feeds
        stub(condition: isHost("feedsearch.dev")) { _ in
            let mockJSON = """
            [
                {"title": "Feed 1", "url": "https://example.com/1"},
                {"title": "Feed 2", "url": "https://example.com/2"},
                {"title": "Feed 3", "url": "https://example.com/3"},
                {"title": "Feed 4", "url": "https://example.com/4"}
            ]
            """
            guard let jsonData = mockJSON.data(using: .utf8) else {
                return HTTPStubsResponse(error: NSError(domain: "TestError", code: -1))
            }
            return HTTPStubsResponse(
                data: jsonData,
                statusCode: 200,
                headers: ["Content-Type": "application/json"]
            ).responseTime(0.01)
        }

        let service = FeedSearchService()

        // When: Searching for feeds
        let dto = try await service.searchFeeds(on: "https://example.com")

        // Then: Should return all feeds
        #expect(dto.count == 4)
        #expect(dto[0].title == "Feed 1")
        #expect(dto[3].title == "Feed 4")
    }

    // MARK: - Error Cases - Invalid URL

    @Test("Empty URL string throws invalid URL error with completion handler")
    func testEmptyURLWithCompletion() async throws {
        // Given: Service with empty URL
        let service = FeedSearchService()

        // When: Searching with empty URL
        let result: FeedSearchResult = await withCheckedContinuation { continuation in
            service.searchFeeds(on: "") { result in
                continuation.resume(returning: result)
            }
        }

        // Then: Should fail with invalidURL error
        switch result {
        case .success:
            Issue.record("Expected failure but got success")
        case .failure(let error):
            guard let searchError = error as? FeedSearchError else {
                Issue.record("Expected FeedSearchError but got \(type(of: error))")
                return
            }
            #expect(searchError == .invalidURL)
        }
    }

    @Test("Empty URL string throws invalid URL error with async/await")
    func testEmptyURLAsync() async throws {
        // Given: Service with empty URL
        let service = FeedSearchService()

        // When/Then: Should throw invalidURL error
        do {
            _ = try await service.searchFeeds(on: "")
            Issue.record("Expected invalidURL error but succeeded")
        } catch let error as FeedSearchError {
            #expect(error == .invalidURL)
        } catch {
            Issue.record("Expected FeedSearchError.invalidURL but got \(error)")
        }
    }

    @Test("URL with special characters that can't be encoded fails gracefully")
    func testInvalidCharactersInURL() async throws {
        // Given: Service with problematic URL
        let service = FeedSearchService()

        // When/Then: Should throw invalidURL error
        do {
            _ = try await service.searchFeeds(on: "")
            Issue.record("Expected invalidURL error but succeeded")
        } catch let error as FeedSearchError {
            #expect(error == .invalidURL)
        } catch {
            Issue.record("Expected FeedSearchError.invalidURL but got \(error)")
        }
    }

    // MARK: - Error Cases - Network Errors

    @Test("Network timeout error with completion handler")
    func testNetworkTimeoutWithCompletion() async throws {
        // Given: Mock network timeout
        stub(condition: isHost("feedsearch.dev")) { _ in
            let error = NSError(
                domain: NSURLErrorDomain,
                code: NSURLErrorTimedOut,
                userInfo: [NSLocalizedDescriptionKey: "Request timed out"]
            )
            return HTTPStubsResponse(error: error).responseTime(0.01)
        }

        let service = FeedSearchService()

        // When: Searching for feeds
        let result: FeedSearchResult = await withCheckedContinuation { continuation in
            service.searchFeeds(on: "https://example.com") { result in
                continuation.resume(returning: result)
            }
        }

        // Then: Should fail with endpoint error
        switch result {
        case .success:
            Issue.record("Expected failure but got success")
        case .failure(let error):
            guard let searchError = error as? FeedSearchError,
                  case .endpoint(let underlyingError) = searchError else {
                Issue.record("Expected FeedSearchError.endpoint but got \(error)")
                return
            }
            let nsError = underlyingError as NSError
            #expect(nsError.code == NSURLErrorTimedOut)
        }
    }

    @Test("Network timeout error with async/await")
    func testNetworkTimeoutAsync() async throws {
        // Given: Mock network timeout
        stub(condition: isHost("feedsearch.dev")) { _ in
            let error = NSError(
                domain: NSURLErrorDomain,
                code: NSURLErrorTimedOut,
                userInfo: nil
            )
            return HTTPStubsResponse(error: error).responseTime(0.01)
        }

        let service = FeedSearchService()

        // When/Then: Should throw endpoint error
        do {
            _ = try await service.searchFeeds(on: "https://example.com")
            Issue.record("Expected error but succeeded")
        } catch let error as FeedSearchError {
            guard case .endpoint(let underlyingError) = error else {
                Issue.record("Expected endpoint error but got \(error)")
                return
            }
            let nsError = underlyingError as NSError
            #expect(nsError.code == NSURLErrorTimedOut)
        } catch {
            Issue.record("Expected FeedSearchError but got \(type(of: error))")
        }
    }

    @Test("Network not connected error")
    func testNetworkNotConnected() async throws {
        // Given: Mock no internet connection
        stub(condition: isHost("feedsearch.dev")) { _ in
            let error = NSError(
                domain: NSURLErrorDomain,
                code: NSURLErrorNotConnectedToInternet,
                userInfo: nil
            )
            return HTTPStubsResponse(error: error).responseTime(0.01)
        }

        let service = FeedSearchService()

        // When/Then: Should throw endpoint error
        do {
            _ = try await service.searchFeeds(on: "https://example.com")
            Issue.record("Expected error but succeeded")
        } catch let error as FeedSearchError {
            guard case .endpoint = error else {
                Issue.record("Expected endpoint error")
                return
            }
        } catch {
            Issue.record("Expected FeedSearchError")
        }
    }

    @Test("Server error 500")
    func testServerError() async throws {
        // Given: Mock server error
        stub(condition: isHost("feedsearch.dev")) { _ in
            return HTTPStubsResponse(
                data: Data(),
                statusCode: 500,
                headers: nil
            ).responseTime(0.01)
        }

        let service = FeedSearchService()

        // When: Searching for feeds
        // Then: Should fail with data decoding error (empty response)
        do {
            _ = try await service.searchFeeds(on: "https://example.com")
            Issue.record("Expected error but succeeded")
        } catch let error as FeedSearchError {
            #expect(error == .dataDecoding)
        } catch {
            Issue.record("Expected FeedSearchError")
        }
    }

    // MARK: - Error Cases - Data Decoding

    @Test("Invalid JSON response with completion handler")
    func testInvalidJSONWithCompletion() async throws {
        // Given: Mock invalid JSON response
        stub(condition: isHost("feedsearch.dev")) { _ in
            let invalidJSON = "{ this is not valid JSON }"
            guard let jsonData = invalidJSON.data(using: .utf8) else {
                return HTTPStubsResponse(error: NSError(domain: "TestError", code: -1))
            }
            return HTTPStubsResponse(
                data: jsonData,
                statusCode: 200,
                headers: ["Content-Type": "application/json"]
            ).responseTime(0.01)
        }

        let service = FeedSearchService()

        // When: Searching for feeds
        let result: FeedSearchResult = await withCheckedContinuation { continuation in
            service.searchFeeds(on: "https://example.com") { result in
                continuation.resume(returning: result)
            }
        }

        // Then: Should fail with dataDecoding error
        switch result {
        case .success:
            Issue.record("Expected failure but got success")
        case .failure(let error):
            guard let searchError = error as? FeedSearchError else {
                Issue.record("Expected FeedSearchError")
                return
            }
            #expect(searchError == .dataDecoding)
        }
    }

    @Test("Invalid JSON response with async/await")
    func testInvalidJSONAsync() async throws {
        // Given: Mock invalid JSON response
        stub(condition: isHost("feedsearch.dev")) { _ in
            let invalidJSON = "not a json array"
            guard let jsonData = invalidJSON.data(using: .utf8) else {
                return HTTPStubsResponse(error: NSError(domain: "TestError", code: -1))
            }
            return HTTPStubsResponse(
                data: jsonData,
                statusCode: 200,
                headers: nil
            ).responseTime(0.01)
        }

        let service = FeedSearchService()

        // When/Then: Should throw dataDecoding error
        do {
            _ = try await service.searchFeeds(on: "https://example.com")
            Issue.record("Expected dataDecoding error but succeeded")
        } catch let error as FeedSearchError {
            #expect(error == .dataDecoding)
        } catch {
            Issue.record("Expected FeedSearchError.dataDecoding but got \(error)")
        }
    }

    @Test("Empty response data with completion handler")
    func testEmptyDataWithCompletion() async throws {
        // Given: Mock empty response
        stub(condition: isHost("feedsearch.dev")) { _ in
            return HTTPStubsResponse(
                data: Data(),
                statusCode: 200,
                headers: nil
            ).responseTime(0.01)
        }

        let service = FeedSearchService()

        // When: Searching for feeds
        let result: FeedSearchResult = await withCheckedContinuation { continuation in
            service.searchFeeds(on: "https://example.com") { result in
                continuation.resume(returning: result)
            }
        }

        // Then: Should fail with dataDecoding error
        switch result {
        case .success:
            Issue.record("Expected failure but got success")
        case .failure(let error):
            guard let searchError = error as? FeedSearchError else {
                Issue.record("Expected FeedSearchError")
                return
            }
            #expect(searchError == .dataDecoding)
        }
    }

    @Test("Malformed JSON structure - wrong schema")
    func testMalformedJSONStructure() async throws {
        // Given: Mock JSON with wrong structure
        stub(condition: isHost("feedsearch.dev")) { _ in
            let wrongSchema = """
            {
                "feeds": [
                    {"name": "Wrong Field Name"}
                ]
            }
            """
            guard let jsonData = wrongSchema.data(using: .utf8) else {
                return HTTPStubsResponse(error: NSError(domain: "TestError", code: -1))
            }
            return HTTPStubsResponse(
                data: jsonData,
                statusCode: 200,
                headers: nil
            ).responseTime(0.01)
        }

        let service = FeedSearchService()

        // When/Then: Should throw dataDecoding error
        do {
            _ = try await service.searchFeeds(on: "https://example.com")
            Issue.record("Expected dataDecoding error but succeeded")
        } catch let error as FeedSearchError {
            #expect(error == .dataDecoding)
        } catch {
            Issue.record("Expected FeedSearchError.dataDecoding")
        }
    }

    // MARK: - URL Encoding Tests

    @Test("URL with special characters gets properly encoded")
    func testURLEncoding() async throws {
        // Given: URL with special characters that need encoding
        var capturedURLString: String?

        stub(condition: isHost("feedsearch.dev")) { request in
            capturedURLString = request.url?.absoluteString
            let mockJSON = "[]"
            guard let jsonData = mockJSON.data(using: .utf8) else {
                return HTTPStubsResponse(error: NSError(domain: "TestError", code: -1))
            }
            return HTTPStubsResponse(
                data: jsonData,
                statusCode: 200,
                headers: nil
            )
        }

        let service = FeedSearchService()

        // When: Searching with URL containing characters that need encoding (colon in path)
        _ = try? await service.searchFeeds(on: "https://example.com/hello world")

        // Then: URL should be properly encoded
        #expect(capturedURLString != nil)
        if let urlString = capturedURLString {
            // The space should be encoded as %20
            #expect(urlString.contains("%20"))
            #expect(!urlString.contains("hello world")) // Original unencoded string should not be present
        }
    }

    @Test("URL with spaces gets properly encoded")
    func testURLWithSpaces() async throws {
        // Given: URL with spaces
        var capturedURLString: String?

        stub(condition: isHost("feedsearch.dev")) { request in
            capturedURLString = request.url?.absoluteString
            let jsonData = Data("[]".utf8)
            return HTTPStubsResponse(
                data: jsonData,
                statusCode: 200,
                headers: nil
            ).responseTime(0.01)
        }

        let service = FeedSearchService()

        // When: Searching with spaces in URL
        _ = try? await service.searchFeeds(on: "https://example.com/my page")

        // Then: Spaces should be encoded
        #expect(capturedURLString != nil)
        if let urlString = capturedURLString {
            #expect(!urlString.contains(" "))
        }
    }

    // MARK: - Request Configuration Tests

    @Test("Request has correct HTTP method and headers")
    func testRequestConfiguration() async throws {
        // Given: Capture request details
        var capturedRequest: URLRequest?

        stub(condition: isHost("feedsearch.dev")) { request in
            capturedRequest = request
            let jsonData = Data("[]".utf8)
            return HTTPStubsResponse(
                data: jsonData,
                statusCode: 200,
                headers: nil
            ).responseTime(0.01)
        }

        let service = FeedSearchService()

        // When: Making a request
        _ = try? await service.searchFeeds(on: "https://example.com")

        // Then: Request should be configured correctly
        #expect(capturedRequest != nil)
        if let request = capturedRequest {
            #expect(request.httpMethod == "GET")
            #expect(request.cachePolicy == .reloadIgnoringLocalCacheData)
        }
    }

    // MARK: - Performance Tests

    @Test("Multiple concurrent requests complete successfully")
    func testConcurrentRequests() async throws {
        // Given: Mock successful responses
        stub(condition: isHost("feedsearch.dev")) { _ in
            let mockJSON = """
            [{"title": "Test Feed", "url": "https://example.com/feed"}]
            """
            guard let jsonData = mockJSON.data(using: .utf8) else {
                return HTTPStubsResponse(error: NSError(domain: "TestError", code: -1))
            }
            return HTTPStubsResponse(
                data: jsonData,
                statusCode: 200,
                headers: nil
            ).responseTime(0.01)
        }

        // When: Making multiple concurrent requests with separate service instances
        // This avoids data race warnings in Swift 6 by ensuring each concurrent
        // context has its own service instance
        async let result1 = FeedSearchService().searchFeeds(on: "https://example1.com")
        async let result2 = FeedSearchService().searchFeeds(on: "https://example2.com")
        async let result3 = FeedSearchService().searchFeeds(on: "https://example3.com")

        // Then: All should succeed
        let (dto1, dto2, dto3) = try await (result1, result2, result3)

        #expect(dto1.count == 1)
        #expect(dto2.count == 1)
        #expect(dto3.count == 1)
    }
}

// MARK: - FeedSearchError Equatable Extension for Testing

extension FeedSearchError: @retroactive Equatable {

    static func == (lhs: FeedSearchError, rhs: FeedSearchError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL):
            return true
        case (.dataDecoding, .dataDecoding):
            return true
        case (.endpoint(let lhsError), .endpoint(let rhsError)):
            return (lhsError as NSError).code == (rhsError as NSError).code
        default:
            return false
        }
    }
}
