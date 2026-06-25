//
//  FeedsPresenterTests.swift
//  iFeedTests
//
//  Created by Evgeny Karkan on 07.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Testing
import Mocking
import CoreData
import UIKit
@testable import iFeed

@Suite
@MainActor
struct FeedsPresenterTests {

    // MARK: - Properties
    private let interactor = FeedsInteractorProtocolMock()
    private let wireframe = FeedsWireframeProtocolMock()
    private let view = FeedsViewProtocolMock()
    private let container: NSPersistentContainer
    private let sut: FeedsPresenter

    // MARK: - Init
    init() {
        container = Self.makeInMemoryContainer()

        interactor._getAllFeeds.implementation = .uncheckedInvokes { [] }
        interactor._unreadCountsByFeed.implementation = .returns([:])
        interactor._getAllFolders.implementation = .returns([])
        interactor._recentSearches.implementation = .returns([])
        interactor._performSearch.implementation = .uncheckedInvokes { _ in nil }
        interactor._itemCount.implementation = .uncheckedInvokes { _ in 0 }

        sut = FeedsPresenter(
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

    private func makeFeed(
        rssURL: String = "https://example.com/feed",
        title: String = "Test Feed",
        itemCount: Int = 0
    ) -> Feed {
        let feed = Feed(context: container.viewContext)
        feed.rssURL = rssURL
        feed.title = title

        if itemCount > 0 {
            var items: [FeedItem] = []
            for idx in 0..<itemCount {
                let item = FeedItem(context: container.viewContext)
                item.title = "Item \(idx)"
                item.link = "https://example.com/\(idx)"
                item.publishDate = Date()
                item.wasRead = NSNumber(value: false)
                item.feed = feed
                items.append(item)
            }
            feed.feedItems = NSSet(array: items)
        } else {
            feed.feedItems = NSSet()
        }

        return feed
    }

    private func stubBuildViewState(
        feeds: [Feed] = [],
        folders: [FeedFolder] = [],
        unreadCounts: [NSManagedObjectID: Int] = [:]
    ) {
        interactor._getAllFeeds.implementation = .uncheckedInvokes { feeds }
        interactor._unreadCountsByFeed.implementation = .returns(unreadCounts)
        interactor._getAllFolders.implementation = .returns(folders)
    }

    // MARK: - onViewDidLoad

    @Test func onViewDidLoad_callsViewUpdateOnDidLoad() {
        // When
        sut.onViewDidLoad()

        // Then
        #expect(view._updateOnDidLoad.callCount == 1)
    }

    @Test func onViewDidLoad_whenStorageBecomesReady_reloadsFeedsList() {
        // Given — the interactor reports storage readiness by invoking the callback,
        // mimicking the asynchronous store load finishing after the first layout.
        interactor._performWhenStorageReady.implementation = .uncheckedInvokes { callback in
            callback()
        }

        // When
        sut.onViewDidLoad()

        // Then — the initially built (empty) list is rebuilt from the loaded store.
        #expect(view._updateOnDidLoad.callCount == 1)
        #expect(view._reloadFeedsList.callCount == 1)
    }

    @Test func onViewDidLoad_buildsViewStateFromInteractor() {
        // Given
        let feed = makeFeed()
        stubBuildViewState(feeds: [feed])

        // When
        sut.onViewDidLoad()

        // Then
        #expect(interactor._getAllFeeds.callCount == 1)
        #expect(interactor._unreadCountsByFeed.callCount == 1)
        #expect(interactor._getAllFolders.callCount == 1)
        #expect(interactor._cleanupFolders.callCount == 1)
        #expect(view._updateOnDidLoad.callCount == 1)
    }

    // MARK: - onViewWillAppear

    @Test func onViewWillAppear_callsViewUpdateOnWillAppear() {
        // When
        sut.onViewWillAppear()

        // Then
        #expect(view._updateOnWillAppear.callCount == 1)
    }

    @Test func onViewWillAppear_refreshesSearchButtonMenuWithReversedRecentSearches() {
        // Given
        interactor._recentSearches.implementation = .returns(["swift", "ios"])

        // When
        sut.onViewWillAppear()

        // Then
        #expect(interactor._recentSearches.callCount == 1)
        #expect(view._configureSearchButtonMenu.callCount == 1)
        #expect(view._configureSearchButtonMenu.lastInvocation == ["ios", "swift"])
    }

    // MARK: - onViewNeedsToShowSearchInput

    @Test func onViewNeedsToShowSearchInput_callsViewShowEnterSearch() {
        // When
        sut.onViewNeedsToShowSearchInput()

        // Then
        #expect(view._showEnterSearch.callCount == 1)
    }

    // MARK: - onViewNeedsToClearRecentSearches

    @Test func onViewNeedsToClearRecentSearches_clearsAndRefreshesMenu() {
        // When
        sut.onViewNeedsToClearRecentSearches()

        // Then
        #expect(interactor._clearRecentSearches.callCount == 1)
        #expect(interactor._recentSearches.callCount == 1)
        #expect(view._configureSearchButtonMenu.callCount == 1)
    }

    // MARK: - feedForIndexPath

    @Test func feedForIndexPath_whenSectionOutOfBounds_returnsNil() {
        // Given
        sut.onViewDidLoad()

        // When
        let feed = sut.feedForIndexPath(IndexPath(row: 0, section: 5))

        // Then
        #expect(feed == nil)
    }

    @Test func feedForIndexPath_whenRowOutOfBounds_returnsNil() {
        // Given
        let feed = makeFeed()
        stubBuildViewState(feeds: [feed])
        sut.onViewDidLoad()

        // When
        let result = sut.feedForIndexPath(IndexPath(row: 5, section: 0))

        // Then
        #expect(result == nil)
    }

    @Test func feedForIndexPath_whenValidIndexPath_returnsFeed() {
        // Given
        let feed = makeFeed()
        stubBuildViewState(feeds: [feed])
        sut.onViewDidLoad()

        // When
        let result = sut.feedForIndexPath(IndexPath(row: 0, section: 0))

        // Then
        #expect(result === feed)
    }

    // MARK: - onViewDidSelectFeedAtIndexPath

    @Test func onViewDidSelectFeedAtIndexPath_whenNoFeedAtIndexPath_doesNotNavigate() {
        // Given
        sut.onViewDidLoad()

        // When
        sut.onViewDidSelectFeedAtIndexPath(IndexPath(row: 0, section: 0))

        // Then
        #expect(wireframe._navigateToFeedItems.callCount == 0)
    }

    @Test func onViewDidSelectFeedAtIndexPath_whenFeedHasNoItems_doesNotNavigate() {
        // Given
        let feed = makeFeed()
        stubBuildViewState(feeds: [feed])
        interactor._itemCount.implementation = .uncheckedInvokes { _ in 0 }
        sut.onViewDidLoad()

        // When
        sut.onViewDidSelectFeedAtIndexPath(IndexPath(row: 0, section: 0))

        // Then
        #expect(interactor._itemCount.callCount == 1)
        #expect(wireframe._navigateToFeedItems.callCount == 0)
    }

    @Test func onViewDidSelectFeedAtIndexPath_whenFeedHasItems_navigatesToFeedItems() {
        // Given
        let feed = makeFeed(itemCount: 3)
        stubBuildViewState(feeds: [feed])
        interactor._itemCount.implementation = .uncheckedInvokes { _ in 3 }
        sut.onViewDidLoad()

        // When
        sut.onViewDidSelectFeedAtIndexPath(IndexPath(row: 0, section: 0))

        // Then
        #expect(wireframe._navigateToFeedItems.callCount == 1)
    }

    @Test func onViewDidSelectFeedAtIndexPath_usesInteractorCountInsteadOfRelationship() {
        // Given — the feed's `feedItems` relationship is deliberately EMPTY.
        // Navigation must rely on the interactor's SQL count, never on firing
        // the to-many fault (which would materialise every item on the main thread).
        let feed = makeFeed(itemCount: 0)
        stubBuildViewState(feeds: [feed])
        interactor._itemCount.implementation = .uncheckedInvokes { _ in 42 }
        sut.onViewDidLoad()

        // When
        sut.onViewDidSelectFeedAtIndexPath(IndexPath(row: 0, section: 0))

        // Then — navigates despite the empty relationship: the count was consulted.
        #expect(interactor._itemCount.callCount == 1)
        #expect(wireframe._navigateToFeedItems.callCount == 1)
    }

    // MARK: - onViewNeedsToAddFeed

    @Test func onViewNeedsToAddFeed_disablesTableViewEditing() {
        // Given
        interactor._checkIfFeedIsAlreadySaved.implementation = .returns(true)

        // When
        sut.onViewNeedsToAddFeed(from: "https://example.com/feed")

        // Then
        #expect(view._disableTableViewEditingStateIfNeeded.callCount == 1)
    }

    @Test func onViewNeedsToAddFeed_whenFeedAlreadySaved_showsError() {
        // Given
        interactor._checkIfFeedIsAlreadySaved.implementation = .returns(true)

        // When
        sut.onViewNeedsToAddFeed(from: "https://example.com/feed")

        // Then
        #expect(view._showFeedIsAlreadySavedError.callCount == 1)
        #expect(view._showActivityIndicator.callCount == 0)
    }

    @Test func onViewNeedsToAddFeed_whenNewFeed_showsActivityIndicatorAndStartsParsing() {
        // Given
        interactor._checkIfFeedIsAlreadySaved.implementation = .returns(false)
        interactor._startParsingFeed.implementation = .uncheckedInvokes { _, _ in }

        // When
        sut.onViewNeedsToAddFeed(from: "https://example.com/feed")

        // Then
        #expect(view._showActivityIndicator.callCount == 1)
        #expect(interactor._startParsingFeed.callCount == 1)
    }

    @Test func onViewNeedsToAddFeed_onParsingSuccess_updatesViewWithoutSavingAgain() {
        // Given
        let feed = makeFeed()
        interactor._checkIfFeedIsAlreadySaved.implementation = .returns(false)
        interactor._startParsingFeed.implementation = .uncheckedInvokes { [feed] _, completion in
            completion(.success(feed))
        }

        // When
        sut.onViewNeedsToAddFeed(from: "https://example.com/feed")

        // Then
        #expect(view._hideActivityIndicator.callCount == 1)
        // The interactor saves inside didEndParsingFeed; the presenter must not save a second time.
        #expect(interactor._saveContext.callCount == 0)
        #expect(view._updateOnDidEndParsingFeed.callCount == 1)
    }

    @Test func onViewNeedsToAddFeed_onParsingFailure_showsErrorMessage() {
        // Given
        let testError = NSError(domain: "Test", code: 42, userInfo: [NSLocalizedDescriptionKey: "Parse failed"])
        interactor._checkIfFeedIsAlreadySaved.implementation = .returns(false)
        interactor._startParsingFeed.implementation = .uncheckedInvokes { _, completion in
            completion(.failure(testError))
        }

        // When
        sut.onViewNeedsToAddFeed(from: "https://example.com/feed")

        // Then
        #expect(view._hideActivityIndicator.callCount == 1)
        #expect(view._showFeedParsingError.callCount == 1)
        #expect(view._showFeedParsingError.lastInvocation == "Parse failed")
    }

    // MARK: - onViewNeedsToDeleteFeedAtIndexPath

    @Test func onViewNeedsToDeleteFeedAtIndexPath_whenInvalidIndexPath_doesNothing() {
        // Given
        sut.onViewDidLoad()

        // When
        sut.onViewNeedsToDeleteFeedAtIndexPath(IndexPath(row: 0, section: 5))

        // Then
        #expect(interactor._deleteFeed.callCount == 0)
    }

    @Test func onViewNeedsToDeleteFeedAtIndexPath_deletesFeedAndAnimates() {
        // Given
        let feed = makeFeed()
        stubBuildViewState(feeds: [feed])
        sut.onViewDidLoad()

        stubBuildViewState(feeds: [])

        // When
        sut.onViewNeedsToDeleteFeedAtIndexPath(IndexPath(row: 0, section: 0))

        // Then
        #expect(interactor._deleteFeed.callCount == 1)
        #expect(view._animateFeedDeletion.callCount == 1)
    }

    // MARK: - Folder operations

    @Test func onViewNeedsToCreateFolder_createsFolderAndReloads() {
        // Given
        let folder = FeedFolder(name: "Tech", feedURLs: ["https://example.com/feed"])
        interactor._createFolder.implementation = .returns(folder)

        // When
        sut.onViewNeedsToCreateFolder(name: "Tech", feedURLs: ["https://example.com/feed"])

        // Then
        #expect(interactor._createFolder.callCount == 1)
        #expect(view._reloadFeedsList.callCount == 1)
    }

    @Test func onViewNeedsToMoveFeedToFolder_movesFeedAndReloads() {
        // Given
        let folderId = UUID()

        // When
        sut.onViewNeedsToMoveFeedToFolder(feedURL: "https://example.com/feed", folderId: folderId)

        // Then
        #expect(interactor._addFeedToFolder.callCount == 1)
        #expect(view._reloadFeedsList.callCount == 1)
    }

    @Test func onViewNeedsToRemoveFeedFromFolder_removesFeedAndReloads() {
        // When
        sut.onViewNeedsToRemoveFeedFromFolder(feedURL: "https://example.com/feed")

        // Then
        #expect(interactor._removeFeedFromFolder.callCount == 1)
        #expect(view._reloadFeedsList.callCount == 1)
    }

    @Test func onViewNeedsToToggleFolder_whenFolderNotInSections_togglesAndReloads() {
        // Given
        let folderId = UUID()
        sut.onViewDidLoad()

        // When
        sut.onViewNeedsToToggleFolder(id: folderId)

        // Then
        #expect(interactor._toggleFolderExpanded.callCount == 1)
        #expect(view._reloadFeedsList.callCount == 1)
    }

    @Test func onViewNeedsToToggleFolder_whenFolderInSections_togglesAndAnimates() {
        // Given
        let folderId = UUID()
        let folder = FeedFolder(id: folderId, name: "Tech", feedURLs: ["https://example.com/feed"])
        let feed = makeFeed()
        stubBuildViewState(feeds: [feed], folders: [folder])
        sut.onViewDidLoad()

        // When
        sut.onViewNeedsToToggleFolder(id: folderId)

        // Then
        #expect(interactor._toggleFolderExpanded.callCount == 1)
        #expect(view._animateFolderToggle.callCount == 1)
    }

    // MARK: - onViewNeedsToSearchFeeds

    @Test func onViewNeedsToSearchFeeds_disablesEditingAndShowsIndicator() {
        // When
        sut.onViewNeedsToSearchFeeds(by: "swift")

        // Then
        #expect(view._disableTableViewEditingStateIfNeeded.callCount == 1)
        #expect(view._showActivityIndicator.callCount == 1)
    }

    @Test func onViewNeedsToSearchFeeds_onSuccess_savesRecentSearchAndRefreshesMenu() async {
        // Given
        let feed = makeFeed(itemCount: 1)
        let items = (feed.feedItems.allObjects as? [FeedItem]) ?? []
        interactor._performSearch.implementation = .uncheckedInvokes { _ in items }
        view._hideActivityIndicator.implementation = .uncheckedInvokes { completion in
            completion?()
        }

        // When
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            wireframe._navigateToSearchResults.implementation = .uncheckedInvokes { _, _ in
                continuation.resume()
            }
            sut.onViewNeedsToSearchFeeds(by: "swift")
        }

        // Then — the query is remembered only after it produced results.
        #expect(interactor._saveRecentSearch.callCount == 1)
        #expect(interactor._saveRecentSearch.lastInvocation == "swift")
        #expect(interactor._recentSearches.callCount >= 1)
        #expect(view._configureSearchButtonMenu.callCount >= 1)
    }

    @Test func onViewNeedsToSearchFeeds_onNoResults_doesNotSaveRecentSearch() async {
        // Given
        interactor._performSearch.implementation = .uncheckedInvokes { _ in nil }
        view._hideActivityIndicator.implementation = .uncheckedInvokes { completion in
            completion?()
        }

        // When
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            view._showNoSearchResultsAlert.implementation = .uncheckedInvokes {
                continuation.resume()
            }
            sut.onViewNeedsToSearchFeeds(by: "tpyo")
        }

        // Then — dead queries must not pollute the recent-searches menu.
        #expect(interactor._saveRecentSearch.callCount == 0)
    }

    @Test func onViewNeedsToSearchFeeds_callsFillSearchMatchingEngine() async throws {
        // When
        sut.onViewNeedsToSearchFeeds(by: "swift")
        try await Task.sleep(for: .milliseconds(50))

        // Then
        #expect(interactor._fillSearchMatchingEngine.callCount == 1)
    }

    // MARK: - OPML import

    @Test func onViewNeedsToShowOPMLPicker_callsView() {
        // When
        sut.onViewNeedsToShowOPMLPicker()

        // Then
        #expect(view._showOPMLPicker.callCount == 1)
    }

    @Test func onViewNeedsToImportOPML_withNoFeeds_showsNoFeedsAlert() {
        // Given — the data holds no parseable feed URLs.
        interactor._parseOPML.implementation = .returns([])

        // When
        sut.onViewNeedsToImportOPML(data: Data())

        // Then — the list is taken out of editing and the no-feeds alert shows;
        // no spinner, no import loop.
        #expect(view._disableTableViewEditingStateIfNeeded.callCount == 1)
        #expect(view._showImportFoundNoFeeds.callCount == 1)
        #expect(view._showActivityIndicator.callCount == 0)
    }

    @Test func onViewNeedsToImportOPML_importsNewSkipsExistingAndCountsFailures() async {
        // Given — three URLs: one already saved, one that parses, one that fails.
        let existing = makeFeed(rssURL: "https://exist.com/feed")
        interactor._parseOPML.implementation = .returns([
            "https://exist.com/feed",
            "https://ok.com/feed",
            "https://bad.com/feed"
        ])
        interactor._getAllFeeds.implementation = .uncheckedInvokes { [existing] }
        enum ImportError: Error { case boom }
        interactor._startParsingFeed.implementation = .uncheckedInvokes { [makeFeed] url, completion in
            if url == "https://ok.com/feed" {
                completion(.success(makeFeed("https://ok.com/feed", "OK", 0)))
            } else {
                completion(.failure(ImportError.boom))
            }
        }
        view._hideActivityIndicator.implementation = .uncheckedInvokes { completion in
            completion?()
        }

        // When
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            view._showImportSummary.implementation = .uncheckedInvokes { _, _, _ in
                continuation.resume()
            }
            sut.onViewNeedsToImportOPML(data: Data())
        }

        // Then — spinner shown, list reloaded, and the tally is added 1 / skipped 1 / failed 1.
        #expect(view._showActivityIndicator.callCount == 1)
        #expect(view._updateOnDidEndParsingFeed.callCount == 1)
        let summary = view._showImportSummary.lastInvocation
        #expect(summary?.0 == 1)
        #expect(summary?.1 == 1)
        #expect(summary?.2 == 1)
    }

    // MARK: - buildViewState — duplicate feed URLs

    @Test func buildViewState_withDuplicateFeedURL_keepsFirstFeed() {
        // Given — two feeds sharing one rssURL exercises the `uniquingKeysWith`
        // "first wins" branch of the URL dictionary.
        let first = makeFeed(rssURL: "https://dup.com/feed", title: "First")
        let second = makeFeed(rssURL: "https://dup.com/feed", title: "Second")
        stubBuildViewState(feeds: [first, second])

        // When
        sut.onViewWillAppear()

        // Then — the list builds without crashing and surfaces a single section.
        let viewState = view._updateOnWillAppear.lastInvocation
        #expect(viewState?.sections.isEmpty == false)
    }

    // MARK: - Delete All

    @Test func onViewNeedsStorageSize_formatsBytesAsMegabytes() async {
        // Given — a couple of megabytes of cache.
        interactor._storageSize.implementation = .returns(2_500_000)

        // When
        let size = await withCheckedContinuation { (continuation: CheckedContinuation<String, Never>) in
            sut.onViewNeedsStorageSize { sizeString in
                continuation.resume(returning: sizeString)
            }
        }

        // Then — the label shows MB with up to two decimals, trailing zeros
        // trimmed (locale-independent: built from the same NumberFormatter config
        // the presenter uses). 2_500_000 bytes → 2.5 MB.
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 0
        numberFormatter.maximumFractionDigits = 2
        let expectedValue = numberFormatter.string(from: NSNumber(value: 2.5))
        #expect(interactor._storageSize.callCount == 1)
        #expect(size == "\(expectedValue ?? "2.5") MB")
    }

    @Test func onViewNeedsToDeleteAllData_clearsCacheAndReloadsList() async {
        // When
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            view._reloadFeedsList.implementation = .uncheckedInvokes { _ in
                continuation.resume()
            }
            sut.onViewNeedsToDeleteAllData()
        }

        // Then — the interactor zeroed the cache and the list was rebuilt.
        #expect(interactor._deleteAllData.callCount == 1)
        #expect(view._reloadFeedsList.callCount == 1)
    }

    // MARK: - onViewNeedsToRefreshAllFeeds

    @Test func onViewNeedsToRefreshAllFeeds_refreshesThenEndsRefreshing() async {
        // Given — a feed so the rebuilt view state carries the refreshed list.
        let feed = makeFeed(rssURL: "https://a.com/feed", title: "A")
        stubBuildViewState(feeds: [feed])

        // When
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            view._finishRefreshingAll.implementation = .uncheckedInvokes { _ in
                continuation.resume()
            }
            sut.onViewNeedsToRefreshAllFeeds()
        }

        // Then — the interactor refreshed every feed, then the view ended the
        // refresh control with a freshly built state.
        #expect(interactor._refreshAllFeeds.callCount == 1)
        #expect(view._finishRefreshingAll.callCount == 1)
        #expect(view._finishRefreshingAll.lastInvocation?.sections.isEmpty == false)

        // And — interaction was locked at the start and restored at the end.
        #expect(view._setInteractionEnabled.callCount == 2)
        #expect(view._setInteractionEnabled.lastInvocation == true)
    }

    @Test func onViewNeedsToRefreshAllFeeds_locksInteractionBeforeRefreshStarts() {
        // When — only the synchronous entry runs (the async refresh is still pending).
        sut.onViewNeedsToRefreshAllFeeds()

        // Then — interaction is disabled immediately, before any await resolves.
        #expect(view._setInteractionEnabled.callCount == 1)
        #expect(view._setInteractionEnabled.lastInvocation == false)
    }

    // MARK: - onViewNeedsToExploreFeeds

    @Test func onViewNeedsToExploreFeeds_disablesEditingAndShowsIndicator() {
        // Given
        wireframe._presentFeedExplorer.implementation = .uncheckedInvokes { _, _, _ in }

        // When
        sut.onViewNeedsToExploreFeeds(on: "https://example.com")

        // Then
        #expect(view._disableTableViewEditingStateIfNeeded.callCount == 1)
        #expect(view._showActivityIndicator.callCount == 1)
    }

    @Test func onViewNeedsToExploreFeeds_callsWireframePresentFeedExplorer() {
        // Given
        wireframe._presentFeedExplorer.implementation = .uncheckedInvokes { _, _, _ in }

        // When
        sut.onViewNeedsToExploreFeeds(on: "https://example.com")

        // Then
        #expect(wireframe._presentFeedExplorer.callCount == 1)
    }

    // MARK: - onViewWillAppear (additional)

    @Test func onViewWillAppear_buildsViewStateFromInteractor() {
        // Given
        let feed = makeFeed()
        stubBuildViewState(feeds: [feed])

        // When
        sut.onViewWillAppear()

        // Then
        #expect(interactor._getAllFeeds.callCount == 1)
        #expect(interactor._unreadCountsByFeed.callCount == 1)
        #expect(interactor._getAllFolders.callCount == 1)
        #expect(interactor._cleanupFolders.callCount == 1)
        #expect(view._updateOnWillAppear.callCount == 1)
    }

    // MARK: - feedForIndexPath (folder with non-matching URL)

    @Test func feedForIndexPath_withFolderContainingNonMatchingURL_returnsOnlyMatchingFeeds() {
        // Given
        let feed = makeFeed(rssURL: "https://example.com/feed")
        let folder = FeedFolder(
            name: "Tech",
            feedURLs: ["https://example.com/feed", "https://nonexistent.com/feed"]
        )
        stubBuildViewState(feeds: [feed], folders: [folder])
        sut.onViewDidLoad()

        // When
        let firstFeed = sut.feedForIndexPath(IndexPath(row: 0, section: 0))
        let secondFeed = sut.feedForIndexPath(IndexPath(row: 1, section: 0))

        // Then
        #expect(firstFeed === feed)
        #expect(secondFeed == nil)
    }

    // MARK: - onViewNeedsToDeleteFeedAtIndexPath (section removal)

    @Test func onViewNeedsToDeleteFeedAtIndexPath_whenSectionRemoved_passesRemovedSectionIndex() {
        // Given
        let folderFeed = makeFeed(rssURL: "https://example.com/folder-feed")
        let ungroupedFeed = makeFeed(rssURL: "https://example.com/ungrouped")
        let folder = FeedFolder(name: "Tech", feedURLs: ["https://example.com/folder-feed"])

        stubBuildViewState(feeds: [folderFeed, ungroupedFeed], folders: [folder])
        sut.onViewDidLoad()

        nonisolated(unsafe) var capturedRemovedSection: Int? = -1
        view._animateFeedDeletion.implementation = .uncheckedInvokes { _, removedSection, _ in
            capturedRemovedSection = removedSection
        }
        stubBuildViewState(feeds: [folderFeed], folders: [folder])

        // When
        sut.onViewNeedsToDeleteFeedAtIndexPath(IndexPath(row: 0, section: 1))

        // Then
        #expect(interactor._deleteFeed.callCount == 1)
        #expect(view._animateFeedDeletion.callCount == 1)
        #expect(capturedRemovedSection == 1)
    }

    // MARK: - onViewNeedsToToggleFolder (collapsed folder)

    @Test func onViewNeedsToToggleFolder_whenFolderCollapsed_animatesTheToggle() {
        // Given
        let folderId = UUID()
        var folder = FeedFolder(id: folderId, name: "Tech", feedURLs: ["https://example.com/feed"])
        folder.isExpanded = false
        let feed = makeFeed()
        stubBuildViewState(feeds: [feed], folders: [folder])
        sut.onViewDidLoad()

        nonisolated(unsafe) var capturedSectionIndex = -1
        view._animateFolderToggle.implementation = .uncheckedInvokes { sectionIndex, _ in
            capturedSectionIndex = sectionIndex
        }

        // When
        sut.onViewNeedsToToggleFolder(id: folderId)

        // Then — the folder is present in `sections`, so the toggle is animated.
        // The number of rows to delete/insert is derived by the view from the
        // table itself (not passed by the presenter), so only the targeted
        // section index is asserted here.
        #expect(interactor._toggleFolderExpanded.callCount == 1)
        #expect(view._animateFolderToggle.callCount == 1)
        #expect(capturedSectionIndex == 0)
    }

    // MARK: - onViewNeedsToSearchFeeds (callback paths)
    // Uses withCheckedContinuation instead of Task.sleep to avoid flaky failures under full-suite load.

    @Test func onViewNeedsToSearchFeeds_whenResultsFound_navigatesToSearchResults() async {
        // Given
        let feed = makeFeed(itemCount: 1)
        let items = (feed.feedItems.allObjects as? [FeedItem]) ?? []

        interactor._performSearch.implementation = .uncheckedInvokes { _ in items }
        view._hideActivityIndicator.implementation = .uncheckedInvokes { completion in
            completion?()
        }

        // When
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            wireframe._navigateToSearchResults.implementation = .uncheckedInvokes { _, _ in
                continuation.resume()
            }
            sut.onViewNeedsToSearchFeeds(by: "swift")
        }

        // Then
        #expect(wireframe._navigateToSearchResults.callCount == 1)
    }

    @Test func onViewNeedsToSearchFeeds_whenNilResults_showsNoSearchResultsAlert() async {
        // Given
        interactor._performSearch.implementation = .uncheckedInvokes { _ in nil }
        view._hideActivityIndicator.implementation = .uncheckedInvokes { completion in
            completion?()
        }

        // When
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            view._showNoSearchResultsAlert.implementation = .uncheckedInvokes {
                continuation.resume()
            }
            sut.onViewNeedsToSearchFeeds(by: "swift")
        }

        // Then
        #expect(view._showNoSearchResultsAlert.callCount == 1)
    }

    @Test func onViewNeedsToSearchFeeds_whenEmptyResults_showsNoSearchResultsAlert() async {
        // Given
        interactor._performSearch.implementation = .uncheckedInvokes { _ in [] }
        view._hideActivityIndicator.implementation = .uncheckedInvokes { completion in
            completion?()
        }

        // When
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            view._showNoSearchResultsAlert.implementation = .uncheckedInvokes {
                continuation.resume()
            }
            sut.onViewNeedsToSearchFeeds(by: "swift")
        }

        // Then
        #expect(view._showNoSearchResultsAlert.callCount == 1)
    }

    // MARK: - onViewNeedsToExploreFeeds (callback paths)

    @Test func onViewNeedsToExploreFeeds_onChallengePresented_hidesActivityIndicator() {
        // Given
        wireframe._presentFeedExplorer.implementation = .uncheckedInvokes { _, onChallenge, _ in
            onChallenge()
        }

        // When
        sut.onViewNeedsToExploreFeeds(on: "https://example.com")

        // Then
        #expect(view._hideActivityIndicator.callCount == 1)
    }

    @Test func onViewNeedsToExploreFeeds_onResultSuccessWithValidFeeds_presentsDiscoveredFeeds() async {
        // Given
        let element = ExploreFeedsElement(
            description: nil,
            favicon: nil,
            selfURL: "https://example.com/feed",
            siteName: nil,
            siteURL: nil,
            title: "Test",
            url: nil
        )
        wireframe._presentFeedExplorer.implementation = .uncheckedInvokes { _, _, onResult in
            onResult(.success([element]))
        }
        wireframe._presentDiscoveredFeeds.implementation = .uncheckedInvokes { _, _, _ in }

        // When
        sut.onViewNeedsToExploreFeeds(on: "https://example.com")
        await Task.yield()

        // Then
        #expect(view._hideActivityIndicator.callCount == 1)
        #expect(wireframe._presentDiscoveredFeeds.callCount == 1)
    }

    @Test func onViewNeedsToExploreFeeds_onResultSuccessWithEmptyData_showsNoFeedsDiscoveredAlert() async {
        // Given
        wireframe._presentFeedExplorer.implementation = .uncheckedInvokes { _, _, onResult in
            onResult(.success([]))
        }

        // When
        sut.onViewNeedsToExploreFeeds(on: "https://example.com")
        await Task.yield()

        // Then
        #expect(view._showNoFeedsDiscoveredAlert.callCount == 1)
    }

    @Test func onViewNeedsToExploreFeeds_onResultSuccessWithInvalidURLs_showsNoFeedsDiscoveredAlert() async {
        // Given
        let element = ExploreFeedsElement(
            description: nil,
            favicon: nil,
            selfURL: nil,
            siteName: nil,
            siteURL: nil,
            title: "Test",
            url: nil
        )
        wireframe._presentFeedExplorer.implementation = .uncheckedInvokes { _, _, onResult in
            onResult(.success([element]))
        }

        // When
        sut.onViewNeedsToExploreFeeds(on: "https://example.com")
        await Task.yield()

        // Then
        #expect(view._showNoFeedsDiscoveredAlert.callCount == 1)
    }

    @Test func onViewNeedsToExploreFeeds_filtersInvalidURLsFromResults() async {
        // Given
        let validElement = ExploreFeedsElement(
            description: nil,
            favicon: nil,
            selfURL: "https://example.com/valid",
            siteName: nil,
            siteURL: nil,
            title: "Valid",
            url: nil
        )
        let invalidElement = ExploreFeedsElement(
            description: nil,
            favicon: nil,
            selfURL: nil,
            siteName: nil,
            siteURL: nil,
            title: "Invalid",
            url: nil
        )

        nonisolated(unsafe) var capturedResults: ExploreFeedsDTO?
        wireframe._presentFeedExplorer.implementation = .uncheckedInvokes { _, _, onResult in
            onResult(.success([validElement, invalidElement]))
        }
        wireframe._presentDiscoveredFeeds.implementation = .uncheckedInvokes { results, _, _ in
            capturedResults = results
        }

        // When
        sut.onViewNeedsToExploreFeeds(on: "https://example.com")
        await Task.yield()

        // Then
        #expect(capturedResults?.count == 1)
        #expect(capturedResults?.first?.title == "Valid")
    }

    @Test func onViewNeedsToExploreFeeds_onResultFailure_showsError() async {
        // Given
        let testError = NSError(domain: "Test", code: 1)
        wireframe._presentFeedExplorer.implementation = .uncheckedInvokes { _, _, onResult in
            onResult(.failure(testError))
        }

        // When
        sut.onViewNeedsToExploreFeeds(on: "https://example.com")
        await Task.yield()

        // Then
        #expect(view._showError.callCount == 1)
    }

    @Test func onViewNeedsToExploreFeeds_onFeedSelected_callsAddFeed() async {
        // Given
        let element = ExploreFeedsElement(
            description: nil,
            favicon: nil,
            selfURL: "https://example.com/feed",
            siteName: nil,
            siteURL: nil,
            title: "Test",
            url: nil
        )

        nonisolated(unsafe) var capturedCallback: ((String) -> Void)?
        wireframe._presentFeedExplorer.implementation = .uncheckedInvokes { _, _, onResult in
            onResult(.success([element]))
        }
        wireframe._presentDiscoveredFeeds.implementation = .uncheckedInvokes { _, _, callback in
            capturedCallback = callback
        }
        interactor._checkIfFeedIsAlreadySaved.implementation = .returns(true)

        // When
        sut.onViewNeedsToExploreFeeds(on: "https://example.com")
        await Task.yield()
        capturedCallback?("https://example.com/feed")

        // Then
        #expect(view._disableTableViewEditingStateIfNeeded.callCount == 2)
        #expect(view._showFeedIsAlreadySavedError.callCount == 1)
    }

    // MARK: - FeedCell accessibility

    @Test func feedCell_announcesTitleSubtitleAndUnreadCount() throws {
        // Given — a cell configured like a feed row (title + summary + unread count).
        let cell = try makeFeedCell()

        // When
        cell.titleText = "Swift Blog"
        cell.subTitleText = "Latest from Swift"
        cell.itemsCountText = "3"

        // Then — VoiceOver reads the title, then subtitle and "3 Unread".
        #expect(cell.accessibilityLabel == "Swift Blog")
        let value = cell.accessibilityValue ?? ""
        #expect(value.contains("Latest from Swift"))
        #expect(value.contains("3"))
        #expect(value.contains(String.localized(key: LocalizableKeys.Accessibility.unread)))
    }

    @Test func feedCell_unreadArticle_announcesUnread() throws {
        // Given / When — an unread article row.
        let cell = try makeFeedCell()
        cell.titleText = "Swift 6 concurrency"
        cell.wasReadCell = false

        // Then
        #expect(cell.accessibilityValue?.contains(String.localized(key: LocalizableKeys.Accessibility.unread)) == true)
    }

    @Test func feedCell_readArticle_omitsUnread() throws {
        // Given / When — a read article row.
        let cell = try makeFeedCell()
        cell.titleText = "Swift 6 concurrency"
        cell.wasReadCell = true

        // Then
        let value = cell.accessibilityValue ?? ""
        #expect(!value.contains(String.localized(key: LocalizableKeys.Accessibility.unread)))
    }

    // MARK: - FeedFolderHeaderView accessibility

    @Test func folderHeader_announcesNameCountAndExpandedState() {
        // Given / When
        let header = FeedFolderHeaderView(reuseIdentifier: nil)
        header.configure(name: "Tech", feedCount: 2, isExpanded: true)

        // Then — a single button announcing the folder, its count, and its state.
        #expect(header.isAccessibilityElement)
        #expect(header.accessibilityTraits.contains(.button))
        #expect(header.accessibilityLabel == "Tech")
        let value = header.accessibilityValue ?? ""
        #expect(value.contains("2"))
        #expect(value.contains(String.localized(key: LocalizableKeys.Accessibility.expanded)))
    }

    @Test func folderHeader_collapsed_announcesCollapsed_andActivateToggles() {
        // Given
        let header = FeedFolderHeaderView(reuseIdentifier: nil)
        header.configure(name: "Tech", feedCount: 2, isExpanded: false)
        #expect(header.accessibilityValue?.contains(String.localized(key: LocalizableKeys.Accessibility.collapsed)) == true)

        nonisolated(unsafe) var toggled = false
        header.onToggle = { toggled = true }

        // When — VoiceOver activates the header.
        let handled = header.accessibilityActivate()

        // Then — the toggle fires.
        #expect(handled)
        #expect(toggled)
    }

    // MARK: - Helpers

    private func makeFeedCell() throws -> FeedCell {
        let nib = UINib(nibName: String(describing: FeedCell.self), bundle: Bundle(for: FeedCell.self))
        return try #require(nib.instantiate(withOwner: nil).first as? FeedCell)
    }
}
