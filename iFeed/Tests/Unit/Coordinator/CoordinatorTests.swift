//
//  CoordinatorTests.swift
//  iFeedTests
//
//  Created by Evgeny Karkan on 11.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation
import Testing
import Mocking
import CoreData
import UIKit
@testable import iFeed

@Suite("Coordinator Tests")
@MainActor
struct CoordinatorTests {

    // MARK: - feedURL(fromDeepLink:)

    @Test func feedURLFromDeepLink_stripsSchemeAndSlashes_andPrependsHTTPS() throws {
        // Given — the canonical deep-link shape.
        let url = try #require(URL(string: "feed://www.swift.org/atom.xml"))

        // When / Then — `feed://` is a transport wrapper, the result must be
        // a fetchable absolute URL, not the raw "//www…" resource specifier.
        #expect(Coordinator.feedURL(fromDeepLink: url) == "https://www.swift.org/atom.xml")
    }

    @Test func feedURLFromDeepLink_keepsExplicitHTTPSScheme() throws {
        // Given — `feed://https://…` style links carry their own scheme.
        let url = try #require(URL(string: "feed://https://www.swift.org/atom.xml"))

        // When / Then
        #expect(Coordinator.feedURL(fromDeepLink: url) == "https://www.swift.org/atom.xml")
    }

    @Test func feedURLFromDeepLink_keepsExplicitHTTPScheme() throws {
        // Given — a legacy plain-HTTP feed must not be force-upgraded.
        let url = try #require(URL(string: "feed://http://legacy.example.com/rss"))

        // When / Then
        #expect(Coordinator.feedURL(fromDeepLink: url) == "http://legacy.example.com/rss")
    }

    @Test func feedURLFromDeepLink_withoutDoubleSlash_normalizesToo() throws {
        // Given — the `feed:host/path` form (no authority slashes).
        let url = try #require(URL(string: "feed:www.example.com/rss"))

        // When / Then
        #expect(Coordinator.feedURL(fromDeepLink: url) == "https://www.example.com/rss")
    }

    @Test func feedURLFromDeepLink_withAppScheme_normalizes() throws {
        // Given — the app's own registered scheme behaves like `feed://`.
        let url = try #require(URL(string: "Feeds4U://www.example.com/rss"))

        // When / Then
        #expect(Coordinator.feedURL(fromDeepLink: url) == "https://www.example.com/rss")
    }

    @Test func feedURLFromDeepLink_withEmptySpecifier_returnsNil() throws {
        // Given — a bare scheme with nothing to extract.
        let url = try #require(URL(string: "feed://"))

        // When / Then
        #expect(Coordinator.feedURL(fromDeepLink: url) == nil)
    }

    // MARK: - Push re-entrancy guard

    @Test func onNeedToShowArticleReader_pushesReaderOnce() {
        // Given
        let (sut, nav, factory) = makeCoordinator()
        factory._makeArticleReaderModule.implementation = .uncheckedInvokes { _, _, _ in UIViewController() }

        // When
        sut.onNeedToShowArticleReader(for: "Title", htmlContent: "<p>x</p>", articleURL: nil)

        // Then — exactly one module pushed onto the root.
        #expect(factory._makeArticleReaderModule.callCount == 1)
        #expect(nav.viewControllers.count == 2)
    }

    @Test func onNeedToShowArticleReader_whilePushInFlight_ignoresSecondPush() {
        // Given
        let (sut, nav, factory) = makeCoordinator()
        factory._makeArticleReaderModule.implementation = .uncheckedInvokes { _, _, _ in UIViewController() }

        // When — a synchronous double-trigger before the first push settles.
        sut.onNeedToShowArticleReader(for: "Title", htmlContent: "<p>x</p>", articleURL: nil)
        sut.onNeedToShowArticleReader(for: "Title", htmlContent: "<p>x</p>", articleURL: nil)

        // Then — the second request is ignored; no double-push.
        #expect(factory._makeArticleReaderModule.callCount == 1)
        #expect(nav.viewControllers.count == 2)
    }

    @Test func onNeedToShowArticleReader_afterPushSettles_allowsNextPush() async {
        // Given
        let (sut, nav, factory) = makeCoordinator()
        factory._makeArticleReaderModule.implementation = .uncheckedInvokes { _, _, _ in UIViewController() }

        // When — the guard is released on the next run-loop tick (no window).
        sut.onNeedToShowArticleReader(for: "A", htmlContent: "<p>a</p>", articleURL: nil)
        try? await Task.sleep(for: .milliseconds(50))
        sut.onNeedToShowArticleReader(for: "B", htmlContent: "<p>b</p>", articleURL: nil)

        // Then — both pushes are honoured once the first has settled.
        #expect(factory._makeArticleReaderModule.callCount == 2)
        #expect(nav.viewControllers.count == 3)
    }

    @Test func onNeedToShowFeedDetails_whilePushInFlight_ignoresSecondPush() throws {
        // Given
        let (sut, nav, factory) = makeCoordinator()
        factory._makeFeedItemsModule.implementation = .uncheckedInvokes { _, _ in UIViewController() }
        let feed = try makeFeed()

        // When — rapid double-tap on a feed row.
        sut.onNeedToShowFeedDetails(for: feed)
        sut.onNeedToShowFeedDetails(for: feed)

        // Then — only one FeedItems module is pushed.
        #expect(factory._makeFeedItemsModule.callCount == 1)
        #expect(nav.viewControllers.count == 2)
    }

    @Test func onNeedToShowSearchResults_whilePushInFlight_ignoresSecondPush() {
        // Given
        let (sut, nav, factory) = makeCoordinator()
        factory._makeFeedItemsModuleForSearchResults.implementation = .uncheckedInvokes { _, _, _ in UIViewController() }

        // When
        sut.onNeedToShowSearchResults(with: [], matching: "swift")
        sut.onNeedToShowSearchResults(with: [], matching: "swift")

        // Then
        #expect(factory._makeFeedItemsModuleForSearchResults.callCount == 1)
        #expect(nav.viewControllers.count == 2)
    }

    // MARK: - Helpers

    // swiftlint:disable:next large_tuple
    private func makeCoordinator() -> (Coordinator, UINavigationController, ModuleFactoryProtocolMock) {
        let nav = UINavigationController(rootViewController: UIViewController())
        let factory = ModuleFactoryProtocolMock()
        let sut = Coordinator(container: DIContainer(), controller: nav, moduleFactory: factory)
        return (sut, nav, factory)
    }

    private func makeFeed() throws -> Feed {
        let container = NSPersistentContainer(name: "iFeed", managedObjectModel: TestCoreDataModel.shared)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, _ in }

        let feed = Feed(context: container.viewContext)
        feed.rssURL = "https://example.com/rss"
        feed.title = "Example"
        return feed
    }
}
