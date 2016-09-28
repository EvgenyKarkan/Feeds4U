//
//  EVKBrain.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/4/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import CoreData


class EVKBrain: NSObject {
   
    // MARK: - Readonly properties
    private (set) var parser: EVKXMLParser!
    private (set) var coreDater: EVKCoreDataManager!
    private (set) var presenter: EVKPresenter!
    private (set) var analytics: EVKAnalytics!
    private (set) var cacher: EVKCacher!
    
    // MARK: - Singleton
    class var brain: EVKBrain {
        struct Singleton {
            static let instance = EVKBrain()
        }
        return Singleton.instance
    }
    
    // MARK: - Init
    override init() {
        parser    = EVKXMLParser()
        coreDater = EVKCoreDataManager()
        presenter = EVKPresenter.presenter
        analytics = EVKAnalytics.analytics
        cacher    = EVKCacher.cacher
        
        super.init()
    }
    
    // MARK: - Public APIs
    func startServices() {
        self.presenter.showStartScreen()
        self.analytics.startCrashlytics()
        self.cacher.startToCache()
    }
    
    func createEntity(name name: String) -> NSManagedObject {
        return self.coreDater.createEntity(name: name)
    }
    
    func feedForIndexPath(indexPath indexPath: NSIndexPath) -> Feed {
        assert(!indexPath.isEqual(nil), "Index path param is nil")
        
        var feed: Feed?
        let feedsCount = self.coreDater.allFeeds().count
        
        if feedsCount > 0 && indexPath.row < feedsCount {
            feed = self.coreDater.allFeeds()[indexPath.row]
        }
        assert(feed != nil, "Feed for index path is nil")
        
        return feed!
    }
    
    func isDuplicateURL(rssURL: String) -> Bool {
        var returnValue: Bool = false
        let allItems: [Feed]  = EVKBrain.brain.coreDater.allFeeds()
        
        for item: Feed in allItems {
            if rssURL == item.rssURL {
                returnValue = true
            }
        }
        
        return returnValue
    }
}
