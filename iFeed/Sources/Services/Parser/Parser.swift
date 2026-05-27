//
//  Parser.swift
//  iFeed
//
//  Created by Evgeny Karkan on 8/16/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import FeedKit
import Foundation
import Dispatch

// MARK: - ParserDelegateProtocol
protocol ParserDelegateProtocol: AnyObject {
    func didStartParsingFeed()
    func didEndParsingFeed(_ feed: Feed)
    #warning("ADD ERROR ARGUMENT HERE")
    func didFailParsingFeed()
}

extension ParserDelegateProtocol {
    func didStartParsingFeed() {}
}

// MARK: - ParserProtocol
protocol ParserProtocol {
    func beginParsingURL(_ url: URL)
    func setDelegate(_ delegate: any ParserDelegateProtocol)
}

// MARK: - Parser class
final class Parser: @unchecked Sendable {
    // MARK: - Properties
    private static let parsingQueue = DispatchQueue(label: "com.iFeed.parser", qos: .userInitiated)
    private let storage: any StorageProtocol
    weak var delegate: (any ParserDelegateProtocol)?

    // MARK: - Init
    // TODO: - Remove storage from parser, let client create the data objects and cache them
    init(storage: any StorageProtocol) {
        self.storage = storage
    }
}

// MARK: - ParserProtocol, Public API
extension Parser: ParserProtocol {

    enum ParsedFeedResult: Sendable {
        case success(ParsedFeedData)
        case failure(String)
    }

    func beginParsingURL(_ url: URL) { // maybe turn it to async?
        delegate?.didStartParsingFeed()

        let parser = FeedParser(URL: url)

        parser.parseAsync(queue: Self.parsingQueue) { result in
            let parsedResult: ParsedFeedResult

            switch result {
            case .success(let parsedFeed):
                parsedResult = .success(ParsedFeedData(parsedFeed: parsedFeed))
            case .failure(let error):
                parsedResult = .failure(error.localizedDescription)
            }

            DispatchQueue.main.async { [weak self] in
                switch parsedResult {
                case .success(let feedData):
                    self?.finishParsing(feedData: feedData, url: url)
                case .failure(let errorDescription):
                    #warning("HANDLE ERROR ON UI")
                    print("GOT PARSING ERROR ---> \(errorDescription)")
                    self?.delegate?.didFailParsingFeed()
                }
            }
        }
    }

    func setDelegate(_ delegate: any ParserDelegateProtocol) {
        self.delegate = delegate
    }
}

// MARK: - Private
private extension Parser {

    func finishParsing(feedData: ParsedFeedData, url: URL) {
        guard let feed = storage.makeFeed() else {
            delegate?.didFailParsingFeed()
            return
        }

        feed.title = feedData.title
        feed.rssURL = url.absoluteString
        feed.summary = feedData.summary

        feedData.items.forEach { itemData in
            guard let feedItem = storage.makeFeedItem() else {
                return
            }

            feedItem.title = itemData.title
            feedItem.link = itemData.link
            feedItem.htmlContent = itemData.htmlContent
            feedItem.publishDate = itemData.publishDate
            feedItem.feed = feed
        }

        delegate?.didEndParsingFeed(feed)
    }
}
