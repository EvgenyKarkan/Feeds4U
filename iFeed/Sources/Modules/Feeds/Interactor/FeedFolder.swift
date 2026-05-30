//
//  FeedFolder.swift
//  iFeed
//
//  Created by Evgeny Karkan on 30.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation

struct FeedFolder: Codable, Equatable {
    // MARK: - Properties
    let id: UUID
    var name: String
    var feedURLs: [String]
    var isExpanded: Bool

    // MARK: - Init
    init(id: UUID = UUID(), name: String, feedURLs: [String]) {
        self.id = id
        self.name = name
        self.feedURLs = feedURLs
        self.isExpanded = true
    }
}
