//
//  FeedsView.swift
//  iFeed
//
//  Created by Evgeny Karkan on 8/15/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit

// MARK: - FeedsListViewDelegate
@MainActor
protocol FeedsListViewDelegate: AnyObject {
    /// Fired when the user pulls the feeds list to refresh every saved feed.
    func didPullToRefreshAllFeeds()
}

final class FeedsView: BaseListView {

    // MARK: - Property
    weak var refreshDelegate: (any FeedsListViewDelegate)?
    private lazy var refreshControl = UIRefreshControl()

    // MARK: - Base override
    override func initialViewSetup() {
        super.initialViewSetup()

        refreshControl.tintColor = .systemGray
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)

        tableView.refreshControl = refreshControl
        refreshControl.layer.zPosition = tableView.layer.zPosition - 1

        configureRefreshAccessibility()
    }

    // MARK: - Action
    @objc private func refresh(_ sender: UIRefreshControl) {
        triggerRefreshHaptic()
        refreshDelegate?.didPullToRefreshAllFeeds()
    }

    /// A light tap confirms a refresh was initiated — whether by the pull gesture
    /// or the VoiceOver custom action.
    private func triggerRefreshHaptic() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Exposes pull-to-refresh to assistive technologies. The pull gesture is not
    /// available under VoiceOver, so a custom action lets those users trigger a
    /// refresh from the list's rotor.
    private func configureRefreshAccessibility() {
        let title = String.localized(key: LocalizableKeys.Accessibility.refresh)
        let action = UIAccessibilityCustomAction(name: title) { [weak self] _ in
            guard let self else {
                return false
            }
            self.triggerRefreshHaptic()
            self.refreshControl.beginRefreshing()
            self.refreshDelegate?.didPullToRefreshAllFeeds()
            return true
        }
        tableView.accessibilityCustomActions = [action]
    }

    // MARK: - Public
    func endRefreshing() {
        guard refreshControl.isRefreshing else {
            return
        }
        refreshControl.endRefreshing()
    }
}
