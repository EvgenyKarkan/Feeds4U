//
//  FeedSearchService.swift
//  iFeed
//
//  Created by Evgeny Karkan on 19.03.2023.
//  Copyright © 2023 Evgeny Karkan. All rights reserved.
//

import Foundation

// MARK: - Type definitions
typealias FeedSearchResult = Swift.Result<FeedSearchDTO, Error>
typealias FeedSearchResultCompletion = (FeedSearchResult) -> Void

enum FeedSearchError: LocalizedError {
    case invalidURL
    case endpoint(Error)
    case dataDecoding

    // MARK: - LocalizedError
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

// MARK: - FeedSearchService, performs web search
final class FeedSearchService {

    func searchFeeds(on webPage: String, completion: @escaping FeedSearchResultCompletion) {
        guard !webPage.isEmpty,
            let url = URL(string: "\("https://feedsearch.dev/api/v1/search?url=")\(webPage)") else {
            completion(FeedSearchResult.failure(FeedSearchError.invalidURL))
            return
        }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.waitsForConnectivity = true
        configuration.timeoutIntervalForRequest = 30

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let session = URLSession(configuration: configuration)

        let task: URLSessionDataTask = session.dataTask(with: request) { data, _, error in
            if let error {
                completion(FeedSearchResult.failure(FeedSearchError.endpoint(error)))
                return
            }
            guard let dtoData = data,
                let dto = try? JSONDecoder().decode(FeedSearchDTO.self, from: dtoData) else {
                completion(FeedSearchResult.failure(FeedSearchError.dataDecoding))
                return
            }
            completion(FeedSearchResult.success(dto))
        }

        task.resume()
    }
}
