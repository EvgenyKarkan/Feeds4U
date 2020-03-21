//
//  EVKCacher.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/27/16.
//  Copyright © 2016 Evgeny Karkan. All rights reserved.
//

import Foundation

class EVKCacher: NSObject {

    // MARK: - Singleton
    static let cacher = EVKCacher()
    
    // MARK: - APIs
    func startToCache() {
        //configure cache to minimize its capacity
        let appCache = URLCache(memoryCapacity: 0, diskCapacity: 0, diskPath: "nsurlcache")
        URLCache.shared = appCache
    }
}
