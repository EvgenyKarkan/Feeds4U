//
//  EVKBrain.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/4/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit
import CoreData

class EVKBrain: NSObject {
   
    // MARK: - Readonly properties
    private (set) var parser: EVKXMLParser!
    private (set) var coreDater: EVKCoreDataManager!
    
    // MARK: - Singleton
    class var brain: EVKBrain {
        
        struct Singleton {
            static let instance = EVKBrain()
        }
        
        return Singleton.instance
    }
    
    // MARK: - Init
    override init() {
        
      self.parser    = EVKXMLParser()
      self.coreDater = EVKCoreDataManager()
        
      super.init()
    }
    
    // MARK: - Public API
    func createEntity(#name: String) -> NSManagedObject {
        
        return self.coreDater.createEntity(name: name)
    }
    
    func feedForIndexPath(#indexPath: NSIndexPath) -> Feed {
        
        assert(!indexPath.isEqual(nil), "Index path param is nil")
        
        var feed: Feed?
        
        var feedsCount = self.coreDater.allFeeds().count
        
        if feedsCount > 0 && indexPath.row < feedsCount {
            feed = self.coreDater.allFeeds()[indexPath.row]
        }
        
        assert(feed != nil, "Feed for index path is nil")
        
        return feed!
    }
}
