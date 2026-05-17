//
//  FeedsViewState.swift
//  iFeed
//
//  Created by Evgeny Karkan on 30.04.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation
import CoreData

struct FeedsViewState {
    // MARK: - Properties
    let feeds: [Feed]
    let unreadCounts: [NSManagedObjectID: Int]

    // MARK: - Init
    init(feeds: [Feed] = [], unreadCounts: [NSManagedObjectID: Int] = [:]) {
        self.feeds = feeds
        self.unreadCounts = unreadCounts
    }
}
