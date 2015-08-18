//
//  EVKFeedListViewController.swift
//  iFeed
//
//  Created by Evgeny Karkan on 8/14/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit


class EVKFeedListViewController: UIViewController {

    //MARK: - property    
    var feedView: EVKFeedListView
    
    
    //MARK: - Initializers
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        
        feedView = EVKFeedListView()
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    //MARK: - Life cycle
    override func loadView() {
        
        var aView = EVKFeedListView (frame: UIScreen.mainScreen().bounds)
        
        feedView = aView
        self.view = aView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startParsing()
    }
    
    
    //MARK: - Private
    private func startParsing() {
        
        let parser = EVKXMLParser()
        
        //parser.beginParseURL(NSURL(string: "http://douua.org/lenta/feed/")!)
        
        parser.beginParseURL(NSURL(string: "http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/ws/RSS/toppaidapplications/limit=25/xml")!)
        
        //http://rss.nytimes.com/services/xml/rss/nyt/HomePage.xml
    }
}
