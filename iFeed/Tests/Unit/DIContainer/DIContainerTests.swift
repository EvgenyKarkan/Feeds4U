//
//  DIContainerTests.swift
//  iFeed
//
//  Created by Evgeny Karkan on 22.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Testing
import Foundation
@testable import iFeed

/// Verifies the container's wiring contract: which dependencies are shared
/// (memoised per container) and which are handed out fresh, plus the concrete
/// types produced on the production path.
///
/// `storage()` / `localSearch()` are intentionally not exercised: they build the
/// real `CoreDataManager` (touching the on-disk store), and the DEBUG override
/// branch is only reachable through the UI-test bootstrap, which mutates global
/// `UITestSupport` state and is unsafe to trigger from parallel unit tests.
@Suite("DIContainer Tests")
@MainActor
struct DIContainerTests {

    private let sut = DIContainer()

    // MARK: - parser (not shared)

    @Test("parser returns a fresh instance per call")
    func parserIsNotShared() {
        // When
        let first = sut.parser()
        let second = sut.parser()

        // Then
        // Parser holds a single weak delegate and cancels the previous parse when a
        // new one starts. Sharing one instance across modules would let one module
        // hijack another's in-flight parse, so each call must produce a new parser.
        #expect(first is Parser)
        #expect(first as AnyObject !== second as AnyObject)
    }

    // MARK: - opmlParser (not shared)

    @Test("opmlParser returns an OPMLParser")
    func opmlParserReturnsOPMLParser() {
        // When
        let parser = sut.opmlParser()

        // Then — a stateless value type wired fresh per call.
        #expect(parser is OPMLParser)
    }

    // MARK: - keyedStorage (shared)

    @Test("keyedStorage returns shared standard defaults")
    func keyedStorageReturnsStandardDefaultsAndIsShared() {
        // When
        let first = sut.keyedStorage()
        let second = sut.keyedStorage()

        // Then
        #expect(first as AnyObject === second as AnyObject)
        #expect(first as? UserDefaults === UserDefaults.standard)
    }

    // MARK: - summarizer (shared)

    @Test("summarizer returns the same shared instance")
    func summarizerIsShared() {
        // When — the summarization service is stateless and memoized.
        let first = sut.summarizer()
        let second = sut.summarizer()

        // Then
        #expect(first is SummarizationService)
        #expect(first as AnyObject === second as AnyObject)
    }

    // MARK: - exploreService (shared)

    @Test("exploreService returns the same shared instance")
    func exploreServiceIsShared() {
        // When
        let first = sut.exploreService()
        let second = sut.exploreService()

        // Then
        #expect(first is ExploreFeedsService)
        #expect(first as AnyObject === second as AnyObject)
    }

    // MARK: - foldersManager (shared)

    @Test("foldersManager returns the same shared instance")
    func foldersManagerIsShared() {
        // When
        let first = sut.foldersManager()
        let second = sut.foldersManager()

        // Then
        #expect(first is FeedFolderManager)
        #expect(first as AnyObject === second as AnyObject)
    }

    // MARK: - sharing scope

    @Test("shared instances are scoped per container, not global")
    func sharedInstancesAreScopedPerContainer() {
        // Given — a second, independent container.
        let other = DIContainer()

        // When
        let mine = sut.summarizer()
        let theirs = other.summarizer()

        // Then — "shared" means shared within one container, not globally.
        #expect(mine as AnyObject !== theirs as AnyObject)
    }
}
