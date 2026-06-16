//
//  FeedItemsPresenterTests.swift
//  iFeedTests
//
//  Created by Gemini CLI on 07.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Testing
import Mocking
import CoreData
import UIKit
@testable import iFeed

@Suite
@MainActor
struct FeedItemsPresenterTests {

    // MARK: - Properties

    private let interactor = FeedItemsInteractorProtocolMock()
    private let wireframe = FeedItemsWireframeProtocolMock()
    private let view = FeedItemsViewProtocolMock()
    private let container: NSPersistentContainer
    private let sut: FeedItemsPresenter

    // MARK: - Init

    init() {
        container = Self.makeInMemoryContainer()

        sut = FeedItemsPresenter(
            interactor: interactor,
            wireframe: wireframe,
            view: view
        )
    }

    // MARK: - Helpers

    private static func makeInMemoryContainer() -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "iFeed", managedObjectModel: TestCoreDataModel.shared)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.url = URL(fileURLWithPath: "/dev/null")
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Failed to load in-memory store: \(error)")
            }
        }
        return container
    }

    private func makeFeed(rssURL: String = "https://example.com/feed") -> Feed {
        let feed = Feed(context: container.viewContext)
        feed.rssURL = rssURL
        feed.title = "Test Feed"
        feed.feedItems = NSSet()
        return feed
    }

    private func makeFeedItem(
        title: String = "Item",
        link: String = "https://example.com/item",
        htmlContent: String? = nil
    ) -> FeedItem {
        let feed = makeFeed()
        let item = FeedItem(context: container.viewContext)
        item.title = title
        item.link = link
        item.htmlContent = htmlContent
        item.publishDate = Date()
        item.wasRead = NSNumber(value: false)
        item.feed = feed
        return item
    }

    private func stubDefaultViewState() {
        let emptyItems: [FeedItem] = []
        interactor._getFeedItems.implementation = .uncheckedInvokes { emptyItems }
        interactor._getFeed.implementation = .uncheckedInvokes { nil }
        interactor._getSearchTitle.implementation = .returns(nil)
        interactor._hasUnreadItems.implementation = .returns(false)
    }

    /// Drives `onViewDidLoad()` with the given items so the presenter caches them
    /// as the displayed snapshot that row selection resolves against.
    private func loadView(with items: [FeedItem]?) {
        interactor._getFeedItems.implementation = .uncheckedInvokes { items }
        interactor._getFeed.implementation = .uncheckedInvokes { nil }
        interactor._getSearchTitle.implementation = .returns(nil)
        interactor._hasUnreadItems.implementation = .returns(false)
        sut.onViewDidLoad()
    }

    // MARK: - onViewDidLoad

    @Test func onViewDidLoad_setsCorrectViewState() {
        // Given
        interactor._hasUnreadItems.implementation = .returns(true)
        let emptyItems: [FeedItem] = []
        interactor._getFeedItems.implementation = .uncheckedInvokes { emptyItems }
        interactor._getFeed.implementation = .uncheckedInvokes { nil }
        interactor._getSearchTitle.implementation = .returns(nil)

        // When
        sut.onViewDidLoad()

        // Then
        let viewState = view._updateOnDidLoad.lastInvocation
        #expect(viewState?.isMarkAllAsReadVisible == true)
    }

    @Test func onViewDidLoad_whenItemsExist_prewarmsSafari() {
        // Given
        let item = makeFeedItem()
        let items = [item]
        interactor._getFeedItems.implementation = .uncheckedInvokes { items }
        interactor._getFeed.implementation = .uncheckedInvokes { nil }
        interactor._getSearchTitle.implementation = .returns(nil)
        interactor._hasUnreadItems.implementation = .returns(false)

        // When
        sut.onViewDidLoad()

        // Then
        #expect(view._updateOnDidLoad.callCount == 1)
        #expect(wireframe._prewarmSafari.callCount == 1)
    }

    @Test func onViewDidLoad_whenItemsNil_doesNotPrewarmSafari() {
        // Given
        let nilItems: [FeedItem]? = nil
        interactor._getFeedItems.implementation = .uncheckedInvokes { nilItems }
        interactor._getFeed.implementation = .uncheckedInvokes { nil }
        interactor._getSearchTitle.implementation = .returns(nil)
        interactor._hasUnreadItems.implementation = .returns(false)

        // When
        sut.onViewDidLoad()

        // Then
        #expect(view._updateOnDidLoad.callCount == 1)
        #expect(wireframe._prewarmSafari.callCount == 0)
    }

    @Test func onViewDidLoad_passesSearchTitleInViewState() {
        // Given
        let emptyItems: [FeedItem] = []
        interactor._getFeedItems.implementation = .uncheckedInvokes { emptyItems }
        interactor._getFeed.implementation = .uncheckedInvokes { nil }
        interactor._getSearchTitle.implementation = .returns("swift")
        interactor._hasUnreadItems.implementation = .returns(false)

        // When
        sut.onViewDidLoad()

        // Then
        let viewState = view._updateOnDidLoad.lastInvocation
        #expect(viewState?.searchTitle == "swift")
    }

    // MARK: - onViewWillAppear

    @Test func onViewWillAppear_callsViewUpdate() {
        // When
        sut.onViewWillAppear()

        // Then
        #expect(view._updateOnWillAppear.callCount == 1)
    }

    // MARK: - onViewWillDisappear

    @Test func onViewWillDisappear_whenMovingFromParent_invalidatesPrewarm() {
        // When
        sut.onViewWillDisappear(isMovingFromParent: true, isBeingDismissed: false)

        // Then
        #expect(wireframe._invalidateSafariPrewarm.callCount == 1)
    }

    @Test func onViewWillDisappear_whenBeingDismissed_invalidatesPrewarm() {
        // When
        sut.onViewWillDisappear(isMovingFromParent: false, isBeingDismissed: true)

        // Then
        #expect(wireframe._invalidateSafariPrewarm.callCount == 1)
    }

    @Test func onViewWillDisappear_whenStayingOnScreen_doesNotInvalidatePrewarm() {
        // When
        sut.onViewWillDisappear(isMovingFromParent: false, isBeingDismissed: false)

        // Then
        #expect(wireframe._invalidateSafariPrewarm.callCount == 0)
    }

    // MARK: - onViewDidSelectFeedItemAtIndexPath

    @Test func onViewDidSelectFeedItem_whenItemsNil_doesNothing() {
        // Given
        loadView(with: nil)
        let cell = UITableViewCell()

        // When
        sut.onViewDidSelectFeedItemAtIndexPath(IndexPath(row: 0, section: 0), cell: cell)

        // Then
        #expect(interactor._markItemAsReadIfNeeded.callCount == 0)
        #expect(wireframe._pushArticleReader.callCount == 0)
        #expect(wireframe._presentSafari.callCount == 0)
    }

    @Test func onViewDidSelectFeedItem_whenItemsEmpty_doesNothing() {
        // Given
        loadView(with: [])
        let cell = UITableViewCell()

        // When
        sut.onViewDidSelectFeedItemAtIndexPath(IndexPath(row: 0, section: 0), cell: cell)

        // Then
        #expect(interactor._markItemAsReadIfNeeded.callCount == 0)
    }

    @Test func onViewDidSelectFeedItem_whenIndexOutOfBounds_doesNothing() {
        // Given
        let item = makeFeedItem()
        loadView(with: [item])
        let cell = UITableViewCell()

        // When
        sut.onViewDidSelectFeedItemAtIndexPath(IndexPath(row: 5, section: 0), cell: cell)

        // Then
        #expect(interactor._markItemAsReadIfNeeded.callCount == 0)
    }

    @Test func onViewDidSelectFeedItem_marksItemAsRead() {
        // Given
        let item = makeFeedItem(link: "https://example.com/article")
        loadView(with: [item])
        let cell = UITableViewCell()

        // When
        sut.onViewDidSelectFeedItemAtIndexPath(IndexPath(row: 0, section: 0), cell: cell)

        // Then
        #expect(interactor._markItemAsReadIfNeeded.callCount == 1)
        // Selection resolves against the displayed snapshot — only onViewDidLoad fetched.
        #expect(interactor._getFeedItems.callCount == 1)
    }

    @Test func onViewDidSelectFeedItem_whenLongHtmlContent_pushesArticleReader() {
        // Given
        let longHTML = String(repeating: "a", count: 300)
        let item = makeFeedItem(
            title: "Article Title",
            link: "https://example.com/article",
            htmlContent: longHTML
        )
        loadView(with: [item])
        let cell = UITableViewCell()

        // When
        sut.onViewDidSelectFeedItemAtIndexPath(IndexPath(row: 0, section: 0), cell: cell)

        // Then
        #expect(wireframe._pushArticleReader.callCount == 1)
        #expect(wireframe._pushArticleReader.lastInvocation?.0 == "Article Title")
        #expect(wireframe._pushArticleReader.lastInvocation?.1 == longHTML)
        #expect(wireframe._presentSafari.callCount == 0)
        // The reader received its own copy — the content row must be released
        // so the article body does not stay resident while the list is open.
        #expect(interactor._releaseHTMLContent.callCount == 1)
        #expect(interactor._releaseHTMLContent.lastInvocation === item)
    }

    @Test func onViewDidSelectFeedItem_whenShortHtmlContent_presentsSafari() {
        // Given
        let shortHTML = "Short content"
        let item = makeFeedItem(
            link: "https://example.com/article",
            htmlContent: shortHTML
        )
        loadView(with: [item])
        let cell = UITableViewCell()

        // When
        sut.onViewDidSelectFeedItemAtIndexPath(IndexPath(row: 0, section: 0), cell: cell)

        // Then
        #expect(wireframe._presentSafari.callCount == 1)
        #expect(wireframe._pushArticleReader.callCount == 0)
        // Checking the length above fired the content fault too — release it.
        #expect(interactor._releaseHTMLContent.callCount == 1)
    }

    @Test func onViewDidSelectFeedItem_whenNilHtmlContentAndValidURL_presentsSafari() {
        // Given
        let item = makeFeedItem(link: "https://example.com/article", htmlContent: nil)
        loadView(with: [item])
        let cell = UITableViewCell()

        // When
        sut.onViewDidSelectFeedItemAtIndexPath(IndexPath(row: 0, section: 0), cell: cell)

        // Then
        #expect(wireframe._presentSafari.callCount == 1)
        #expect(wireframe._pushArticleReader.callCount == 0)
    }

    // MARK: - onViewDidPullToRefresh

    @Test func onViewDidPullToRefresh_whenFeedNil_doesNotParse() {
        // Given
        interactor._getFeed.implementation = .uncheckedInvokes { nil }

        // When
        sut.onViewDidPullToRefresh()

        // Then
        #expect(interactor._startParsingFeed.callCount == 0)
    }

    @Test func onViewDidPullToRefresh_whenFeedURLEmpty_doesNotParse() {
        // Given
        let feed = makeFeed(rssURL: "")
        interactor._getFeed.implementation = .uncheckedInvokes { feed }

        // When
        sut.onViewDidPullToRefresh()

        // Then
        #expect(interactor._startParsingFeed.callCount == 0)
    }

    @Test func onViewDidPullToRefresh_startsParsingWithFeedURL() {
        // Given
        let feed = makeFeed(rssURL: "https://example.com/feed")
        interactor._getFeed.implementation = .uncheckedInvokes { feed }
        interactor._startParsingFeed.implementation = .uncheckedInvokes { _, _ in }

        // When
        sut.onViewDidPullToRefresh()

        // Then
        #expect(interactor._startParsingFeed.callCount == 1)
    }

    @Test func onViewDidPullToRefresh_onSuccess_updatesViewAndPrewarmsSafari() {
        // Given
        let feed = makeFeed(rssURL: "https://example.com/feed")
        let item = makeFeedItem()
        let items = [item]

        interactor._getFeed.implementation = .uncheckedInvokes { feed }
        interactor._startParsingFeed.implementation = .uncheckedInvokes { _, completion in
            completion(.success(()))
        }
        interactor._getFeedItems.implementation = .uncheckedInvokes { items }
        interactor._hasUnreadItems.implementation = .returns(false)

        // When
        sut.onViewDidPullToRefresh()

        // Then
        #expect(view._updateOnDidEndParsingFeed.callCount == 1)
        #expect(wireframe._prewarmSafari.callCount == 1)
    }

    @Test func onViewDidPullToRefresh_onSuccess_whenItemsNil_doesNotPrewarmSafari() {
        // Given
        let feed = makeFeed(rssURL: "https://example.com/feed")
        let nilItems: [FeedItem]? = nil

        interactor._getFeed.implementation = .uncheckedInvokes { feed }
        interactor._startParsingFeed.implementation = .uncheckedInvokes { _, completion in
            completion(.success(()))
        }
        interactor._getFeedItems.implementation = .uncheckedInvokes { nilItems }
        interactor._hasUnreadItems.implementation = .returns(false)

        // When
        sut.onViewDidPullToRefresh()

        // Then
        #expect(view._updateOnDidEndParsingFeed.callCount == 1)
        #expect(wireframe._prewarmSafari.callCount == 0)
    }

    @Test func onViewDidPullToRefresh_onFailure_showsError() {
        // Given
        let feed = makeFeed(rssURL: "https://example.com/feed")
        let testError = NSError(domain: "Test", code: 42, userInfo: [NSLocalizedDescriptionKey: "Parse failed"])

        interactor._getFeed.implementation = .uncheckedInvokes { feed }
        interactor._startParsingFeed.implementation = .uncheckedInvokes { _, completion in
            completion(.failure(testError))
        }

        // When
        sut.onViewDidPullToRefresh()

        // Then
        #expect(view._updateOnDidFailParsingFeed.callCount == 1)
        #expect(view._updateOnDidFailParsingFeed.lastInvocation == "Parse failed")
    }

    // MARK: - onMarkAllAsReadTapped

    @Test func onMarkAllAsReadTapped_triggersInteractorAndUpdatesView() {
        // Given
        interactor._markAllItemsAsRead.implementation = .uncheckedInvokes { }
        let emptyItems: [FeedItem] = []
        interactor._getFeedItems.implementation = .uncheckedInvokes { emptyItems }
        interactor._getFeed.implementation = .uncheckedInvokes { nil }
        interactor._getSearchTitle.implementation = .returns(nil)
        interactor._hasUnreadItems.implementation = .returns(false)

        // When
        sut.onMarkAllAsReadTapped()

        // Then
        #expect(interactor._markAllItemsAsRead.callCount == 1)

        let viewState = view._updateOnDidEndParsingFeed.lastInvocation
        #expect(viewState?.isMarkAllAsReadVisible == false)
    }

    // MARK: - FeedItemsView accessibility

    @Test func feedItemsView_exposesRefreshAccessibilityAction() {
        // Given / When
        let feedItemsView = FeedItemsView()

        // Then — a single custom action lets VoiceOver users trigger a refresh
        // (the pull gesture is unavailable under VoiceOver).
        let actions = feedItemsView.tableView.accessibilityCustomActions
        #expect(actions?.count == 1)
        #expect(actions?.first?.name == String.localized(key: LocalizableKeys.Accessibility.refresh))
    }

    @Test func feedItemsView_hideRefreshControl_removesAccessibilityAction() {
        // Given
        let feedItemsView = FeedItemsView()

        // When — search-results mode hides the refresh control.
        feedItemsView.hideRefreshControl()

        // Then — the now-meaningless refresh action is dropped too.
        #expect(feedItemsView.tableView.refreshControl == nil)
        #expect(feedItemsView.tableView.accessibilityCustomActions == nil)
    }
}
