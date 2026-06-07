//
//  FeedItemsPresenterTests.swift
//  iFeedTests
//
//  Created by Gemini CLI on 07.06.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Testing
import Mocking
import UIKit
@testable import iFeed

@Suite(.serialized)
@MainActor
struct FeedItemsPresenterTests {

    // MARK: - Properties

    private let interactor = FeedItemsInteractorProtocolMock()
    private let wireframe = FeedItemsWireframeProtocolMock()
    private let view = FeedItemsViewProtocolMock()
    private let sut: FeedItemsPresenter

    // MARK: - Init

    init() {
        sut = FeedItemsPresenter(
            interactor: interactor,
            wireframe: wireframe,
            view: view
        )
    }

    // MARK: - onViewDidLoad

    @Test func onViewDidLoad_setsCorrectViewState() {
        // Given
        interactor._hasUnreadItems.implementation = .returns(true)
        let emptyItems: [FeedItem] = []
        interactor._getFeedItems.implementation = .returns(emptyItems)
        interactor._getFeed.implementation = .returns(nil)
        interactor._getSearchTitle.implementation = .returns(nil)

        // When
        sut.onViewDidLoad()

        // Then
        let viewState = view._updateOnDidLoad.lastInvocation
        #expect(viewState?.isMarkAllAsReadVisible == true)
    }

    // MARK: - onMarkAllAsReadTapped

    @Test func onMarkAllAsReadTapped_triggersInteractorAndUpdatesView() {
        // Given
        interactor._markAllItemsAsRead.implementation = .uncheckedInvokes { }
        let emptyItems: [FeedItem] = []
        interactor._getFeedItems.implementation = .returns(emptyItems)
        interactor._getFeed.implementation = .returns(nil)
        interactor._getSearchTitle.implementation = .returns(nil)
        interactor._hasUnreadItems.implementation = .returns(false)

        // When
        sut.onMarkAllAsReadTapped()

        // Then
        #expect(interactor._markAllItemsAsRead.callCount == 1)

        let viewState = view._updateOnDidEndParsingFeed.lastInvocation
        #expect(viewState?.isMarkAllAsReadVisible == false)
    }
}
