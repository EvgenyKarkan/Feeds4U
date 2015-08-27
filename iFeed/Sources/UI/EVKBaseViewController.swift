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
        
        let actionSheetController: UIAlertController = UIAlertController(title: nil, message: "Enter new feed", preferredStyle: .Alert)
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
            self.view.endEditing(true)
        }
        
        actionSheetController.addAction(cancelAction)
        
        let nextAction: UIAlertAction = UIAlertAction(title: "Add", style: .Default) { action -> Void in
            self.addOnAlertViewPressed()
        }
        
        actionSheetController.addAction(nextAction)
        
        actionSheetController.addTextFieldWithConfigurationHandler { textField -> Void in
            textField.placeholder = "http://www.something.com/rss"
        }
        
        self.presentViewController(actionSheetController, animated: true, completion: nil)
    }
    
    func addOnAlertViewPressed() {
        //to override in sublasses
    }
}
