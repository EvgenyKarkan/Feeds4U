//
//  EVKFeedListViewController+Search.swift
//  iFeed
//
//  Created by Julius Bahr on 20.04.18.
//  Copyright © 2018 Evgeny Karkan. All rights reserved.
//

import UIKit

extension EVKFeedListViewController {
    @objc func searchPressed (_ sender: UIButton) {
        assert(!sender.isEqual(nil), "sender is nil")
        
        self.showEnterSearch();
    }
    
    func showEnterSearch() {
        let alertController = UIAlertController(title: nil, message: "Search", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            self.view.endEditing(true)
        }
        alertController.addAction(cancelAction)
        
        let nextAction = UIAlertAction(title: "Search", style: .default) { action -> Void in
            if let textField = alertController.textFields?.first {
                
            }
        }
        
        alertController.addAction(nextAction)
        alertController.addTextField { textField -> Void in
            textField.placeholder = "Cute kittens"
        }
        
        let rootVConWindow = EVKBrain.brain.presenter.window.rootViewController
        rootVConWindow!.present(alertController, animated: true, completion: nil)
    }
}

