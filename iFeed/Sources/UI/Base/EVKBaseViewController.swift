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
    func showEnterFeedAlertView(feedURL: String) {
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
            
            if !feedURL.isEmpty {
                textField.text = feedURL
            }
        }
        
        let rootVConWindow = UIApplication.sharedApplication().delegate?.window!!.rootViewController
        rootVConWindow!.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func showInvalidRSSAlert() {
        self.showAlertMessage("RSS feed can't be parsed")
    }
    
    func showDuplicateRSSAlert() {
        self.showAlertMessage("RSS feed already exists,\n try another one")
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
            self.showInvalidRSSAlert()
        }
    }
    
    // MARK: - EVKXMLParserProtocol API
    func didEndParsingFeed(feed: Feed) {
        //to override in subclasses
    }
    
    func didFailParsingFeed() {
        self.showInvalidRSSAlert()
    }
    
   // MARK: - Common alert
   func showAlertMessage(message : String) {
       let alertController = UIAlertController(title: "Oops...", message: message, preferredStyle:.Alert)

       let okAction: UIAlertAction = UIAlertAction(title: "Ok", style:.Default) { action -> Void in
            self.view.endEditing(true)
       }

       alertController.addAction(okAction)

       self.presentViewController(alertController, animated: true, completion: nil)
   }
}
