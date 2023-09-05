//
//  Brain.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/4/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import CoreData

final class Brain {
   
    // MARK: - Properties
    let parser: Parser
    let coreDater: CoreDataManager
    let presenter: Presenter
    let analytics: Analytics
    let cacher: Cacher
    
    // MARK: - Singleton
    static let brain = Brain()
    
    // MARK: - Init
    init() {
        parser = Parser.parser
        coreDater = CoreDataManager.manager
        presenter = Presenter.presenter
        analytics = Analytics.analytics
        cacher = Cacher.cacher
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
    
    func feedForIndexPath(_ indexPath: IndexPath) -> Feed? {
        let index = indexPath.row
        let allFeeds = coreDater.allFeeds()

        guard !allFeeds.isEmpty, index < allFeeds.count else {
            return nil
        }
        
        return allFeeds[index]
    }
    
    func isAlreadySavedURL(_ rssURL: String) -> Bool {
        var returnValue: Bool = false
        let allItems: [Feed] = Brain.brain.coreDater.allFeeds()
        
        for item: Feed in allItems {
            if rssURL == item.rssURL {
                returnValue = true
            }
        }
        
        return returnValue
    }
}
