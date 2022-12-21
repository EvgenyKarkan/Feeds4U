//
//  EVKCacher.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/27/16.
//  Copyright © 2016 Evgeny Karkan. All rights reserved.
//

import Foundation

final class EVKCacher {

    // MARK: - Singleton
    static let cacher = EVKCacher()
    
    // MARK: - APIs
    func startToCache() {
        /// configure cache to minimize its capacity
        URLCache.shared = URLCache(memoryCapacity: .zero, diskCapacity: .zero, diskPath: "nsurlcache")
    }
}
