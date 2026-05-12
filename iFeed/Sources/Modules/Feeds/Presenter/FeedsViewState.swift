//
//  FeedsViewState.swift
//  iFeed
//
//  Created by Evgeny Karkan on 30.04.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import Foundation

struct FeedsViewState {

    let feeds: [Feed]

    init(feeds: [Feed] = []) {
        self.feeds = feeds
    }
}
