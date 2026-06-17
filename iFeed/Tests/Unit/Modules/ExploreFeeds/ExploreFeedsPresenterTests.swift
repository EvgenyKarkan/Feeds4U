//
//  ExploreFeedsPresenterTests.swift
//  iFeedTests
//
//  Created by Evgeny Karkan on 17.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation
import Testing
import Mocking
import CoreData
@testable import iFeed

@Suite("ExploreFeeds Presenter Tests")
@MainActor
struct ExploreFeedsPresenterTests {

    private let interactor = ExploreFeedsInteractorProtocolMock()
    private let view = ExploreFeedsViewProtocolMock()
    private let wireframe = ExploreFeedsWireframeProtocolMock()

    init() {
        // Safe defaults so unstubbed non-void calls never crash.
        interactor._getWebPageTitle.implementation = .returns("")
        interactor._getResultsWithSavedStatus.implementation = .returns([])
        interactor._checkIfFeedIsAlreadySaved.implementation = .returns(false)
    }

    private func makeSUT() -> ExploreFeedsPresenter {
        ExploreFeedsPresenter(interactor: interactor, wireframe: wireframe, view: view)
    }

    private func makeFeed() -> Feed {
        let container = NSPersistentContainer(name: "iFeed", managedObjectModel: TestCoreDataModel.shared)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, _ in }
        return Feed(context: container.viewContext)
    }

    // MARK: - onViewDidLoad

    @Test func onViewDidLoad_buildsStateFromInteractorAndUpdatesView() {
        // Given
        interactor._getWebPageTitle.implementation = .returns("Swift Blog")
        let sut = makeSUT()

        // When
        sut.onViewDidLoad()

        // Then
        #expect(view._updateOnDidLoad.callCount == 1)
        #expect(view._updateOnDidLoad.lastInvocation?.webPageTitle == "Swift Blog")
    }

    // MARK: - onViewNeedsToAddFeed — already saved

    @Test func onViewNeedsToAddFeed_whenAlreadySaved_showsErrorAndSkipsParsing() {
        // Given
        interactor._checkIfFeedIsAlreadySaved.implementation = .returns(true)
        let sut = makeSUT()

        // When
        sut.onViewNeedsToAddFeed(from: "https://example.com/rss")

        // Then — duplicate is rejected before any parsing or spinner.
        #expect(view._showFeedIsAlreadySavedError.callCount == 1)
        #expect(interactor._startParsingFeed.callCount == 0)
        #expect(view._showActivityIndicator.callCount == 0)
    }

    // MARK: - onViewNeedsToAddFeed — success

    @Test func onViewNeedsToAddFeed_onParsingSuccess_hidesSpinnerAndRefreshesState() {
        // Given
        let feed = makeFeed()
        interactor._checkIfFeedIsAlreadySaved.implementation = .returns(false)
        interactor._startParsingFeed.implementation = .uncheckedInvokes { _, completion in
            completion(.success(feed))
        }
        let sut = makeSUT()

        // When
        sut.onViewNeedsToAddFeed(from: "https://example.com/rss")

        // Then
        #expect(view._showActivityIndicator.callCount == 1)
        #expect(view._hideActivityIndicator.callCount == 1)
        #expect(view._update.callCount == 1)
        #expect(view._showFeedParsingError.callCount == 0)
    }

    // MARK: - onViewNeedsToAddFeed — failure

    @Test func onViewNeedsToAddFeed_onParsingFailure_hidesSpinnerAndShowsError() {
        // Given
        enum TestError: Error { case boom }
        interactor._checkIfFeedIsAlreadySaved.implementation = .returns(false)
        interactor._startParsingFeed.implementation = .uncheckedInvokes { _, completion in
            completion(.failure(TestError.boom))
        }
        let sut = makeSUT()

        // When
        sut.onViewNeedsToAddFeed(from: "https://example.com/rss")

        // Then
        #expect(view._showActivityIndicator.callCount == 1)
        #expect(view._hideActivityIndicator.callCount == 1)
        #expect(view._showFeedParsingError.callCount == 1)
        #expect(view._update.callCount == 0)
    }
}
