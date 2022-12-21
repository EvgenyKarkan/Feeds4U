//
//  EVKBrain.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/4/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import CoreData

final class EVKBrain {
   
    // MARK: - Readonly properties
    let parser: EVKParser
    let coreDater: EVKCoreDataManager
    let presenter: EVKPresenter
    let analytics: EVKAnalytics
    let cacher: EVKCacher
    
    // MARK: - Singleton
    static let brain = EVKBrain()
    
    // MARK: - Init
    init() {
        parser = EVKParser.parser
        coreDater = EVKCoreDataManager.manager
        presenter = EVKPresenter.presenter
        analytics = EVKAnalytics.analytics
        cacher = EVKCacher.cacher
    }
    
    // MARK: - Public APIs
    func startServices() {
        presenter.showStartScreen()
        analytics.startCrashlytics()
        cacher.startToCache()
    }
    
    func createEntity(name: String) -> NSManagedObject {
        return coreDater.createEntity(name: name)
    }
    
    func feedForIndexPath(indexPath: IndexPath) -> Feed {
        var feed: Feed?
        let feedsCount = coreDater.allFeeds().count
        
        if feedsCount > 0 && indexPath.row < feedsCount {
            feed = coreDater.allFeeds()[indexPath.row]
        }
        assert(feed != nil, "Feed for index path is nil")
        
        return feed!
    }
    
    func isDuplicateURL(_ rssURL: String) -> Bool {
        var returnValue: Bool = false
        let allItems: [Feed] = EVKBrain.brain.coreDater.allFeeds()
        
        for item: Feed in allItems {
            if rssURL == item.rssURL {
                returnValue = true
            }
        }
        
        return returnValue
    }
}
