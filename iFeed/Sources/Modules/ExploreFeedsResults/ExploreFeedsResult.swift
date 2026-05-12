//
//  ExploreFeedsResult.swift
//  iFeed
//
//  Created by Evgeny Karkan on 29.08.2023.
//  Copyright © 2023 Evgeny Karkan. All rights reserved.
//

import Foundation

enum AddState {
    case added
    case notAdded
}

struct ExploreFeedsResult {
    let data: ExploreFeedsElement
    let state: AddState
}
