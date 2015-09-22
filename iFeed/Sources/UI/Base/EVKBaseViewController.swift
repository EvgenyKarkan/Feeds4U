//
//  EVKBaseViewController.swift
//  iFeed
//
//  Created by Evgeny Karkan on 8/27/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit


class EVKBaseViewController: UIViewController, EVKXMLParserProtocol {

    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title                            = "Feeds4U"
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
    }
    
    // MARK: - Public API - Alerts
    func showEnterFeedAlertView(sender: AnyObject) {
        
        let alertController = UIAlertController(title: nil, message: "Add feed", preferredStyle: .Alert)
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
            self.view.endEditing(true)
        }
        
        alertController.addAction(cancelAction)
        
        let nextAction: UIAlertAction = UIAlertAction(title: "Add", style: .Default) { action -> Void in
            
            if let textField = alertController.textFields?.first {
                
                if !textField.text!.isEmpty {
                    self.addFeedPressed(textField.text!)
                }
                else {
                    self.showInvalidRSSAlert()
                }
            }
        }
        
        alertController.addAction(nextAction)
        
        alertController.addTextFieldWithConfigurationHandler { textField -> Void in
    
            textField.placeholder = "http://www.something.com/rss"
            
            
            //for test purpose
            //textField.text = "http://douua.org/lenta/feed/"
            
            //textField.text = "http://www.objc.io/feed.xml"
            
            //textField.text = "http://techcrunch.com/feed/"
            
            //textField.text = "http://feeds.mashable.com/Mashable"
            
            //textField.text = "http://images.apple.com/main/rss/hotnews/hotnews.rss"
            
            //textField.text = "http://www.techbargains.com/rss.xml"
            
            //textField.text = "http://petersteinberger.com/atom.xml"
            
            //textField.text = "http://highaltitudehacks.com/atom.xml" 
            
            //textField.text = "http://www.apple.com/pr/feeds/pr.rss"
            
            //textField.text = "https://developer.apple.com/news/rss/news.rss"
            
            //textField.text = "https://itunes.apple.com/ua/rss/newapplications/limit=100/xml"
            
//            textField.text = "https://www-304.ibm.com/partnerworld/wps/servlet/download/DownloadServlet?id=7NAGB0UNdJgiPCA$cnt&attachmentName=pwsac.xml&token=MTQ0Mjk1ODczNjU0OA==&locale=en_ALL_ZZ"
        }
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func showInvalidRSSAlert() {
        
        showAlertMessage("RSS feed can't be parsed")
    }
    
    func showDuplicateRSSAlert() {
        
        showAlertMessage("RSS feed already exists,\n try another one")
    }
    
    // MARK: - Public API - Add feed
    func addFeedPressed(URL: String) {
        //to override in sublasses
    }
    
    // MARK: - Public API - Parsing
    func startParsingURL(URL: String) {
        
        let parser            = EVKBrain.brain.parser
        parser.parserDelegate = self
        
        let url = NSURL(string: URL)
        
        if url != nil {
            parser.beginParseURL(NSURL(string: URL)!)
        }
        else {
            showInvalidRSSAlert()
        }
    }
    
    // MARK: - EVKXMLParserProtocol API
    func didEndParsingFeed(feed: Feed) {
        //to override in subclasses
    }
    
    func didFailParsingFeed() {
        
        showInvalidRSSAlert()
    }
    
   // MARK: - Common alert
   func showAlertMessage(message : String) {
    
       let alertController = UIAlertController(title: "Oops...", message: message, preferredStyle:.Alert)

       let okAction: UIAlertAction = UIAlertAction(title: "Ok", style:.Default) { action-> Void in
            self.view.endEditing(true)
       }

       alertController.addAction(okAction)

       self.presentViewController(alertController, animated: true, completion: nil)
   }
}
