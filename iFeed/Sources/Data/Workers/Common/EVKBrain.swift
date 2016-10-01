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
    fileprivate (set) var parser: EVKXMLParser!
    fileprivate (set) var coreDater: EVKCoreDataManager!
    fileprivate (set) var presenter: EVKPresenter!
    fileprivate (set) var analytics: EVKAnalytics!
    fileprivate (set) var cacher: EVKCacher!
    
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
    
    func createEntity(name: String) -> NSManagedObject {
        return self.coreDater.createEntity(name: name)
    }
    
    func feedForIndexPath(indexPath: IndexPath) -> Feed {
        var feed: Feed?
        let feedsCount = self.coreDater.allFeeds().count
        
        if feedsCount > 0 && (indexPath as NSIndexPath).row < feedsCount {
            feed = self.coreDater.allFeeds()[(indexPath as NSIndexPath).row]
        }
        assert(feed != nil, "Feed for index path is nil")
        
        return feed!
    }
    
    func isDuplicateURL(_ rssURL: String) -> Bool {
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
