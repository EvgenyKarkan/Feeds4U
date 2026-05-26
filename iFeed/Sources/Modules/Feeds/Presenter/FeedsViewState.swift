//
//  FeedsViewState.swift
//  iFeed
//
//  Created by Evgeny Karkan on 30.04.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation
import CoreData

// MARK: - FeedsSection
struct FeedsSection {
    let folder: FeedFolder?
    let feeds: [Feed]
}

// MARK: - FeedsViewState
struct FeedsViewState {
    // MARK: - Properties
    let sections: [FeedsSection]
    let unreadCounts: [NSManagedObjectID: Int]

    var allFeeds: [Feed] {
        sections.flatMap(\.feeds)
    }

    // MARK: - Init
    init(sections: [FeedsSection] = [], unreadCounts: [NSManagedObjectID: Int] = [:]) {
        self.sections = sections
        self.unreadCounts = unreadCounts
    }
}
