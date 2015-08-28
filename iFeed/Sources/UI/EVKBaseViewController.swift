//
//  EVKBaseViewController.swift
//  iFeed
//
//  Created by Evgeny Karkan on 8/27/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit


class EVKBaseViewController: UIViewController {

    override func viewDidLoad() {
        
        super.viewDidLoad()

        self.title = "iFeed"
    }
    
    //MARK: - Public API
    
    func showAlertView(sender: AnyObject) {
        
        let alertController: UIAlertController = UIAlertController(title: nil, message: "Enter new feed", preferredStyle: .Alert)
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
            self.view.endEditing(true)
        }
        
        alertController.addAction(cancelAction)
        
        let nextAction: UIAlertAction = UIAlertAction(title: "Add", style: .Default) { action -> Void in
            
            if let textField = alertController.textFields?.first as? UITextField {
                
                if !textField.text.isEmpty {
                    self.addFeedPressed(textField.text)
                }
            }
        }
        
        alertController.addAction(nextAction)
        
        alertController.addTextFieldWithConfigurationHandler { textField -> Void in
      
            textField.placeholder = "http://www.something.com/rss"
            
            textField.text = "http://douua.org/lenta/feed/"
        }
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func addFeedPressed(URL: String) {
        //to override in sublasses
    }
}
