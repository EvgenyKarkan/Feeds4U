//
//  EVKFeedListView.swift
//  iFeed
//
//  Created by Evgeny Karkan on 8/15/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit


class EVKFeedListView: UIView {

    //MARK: - Properties

    var tableView: UITableView!
    
    
    //MARK: - Initializers
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.lightGrayColor()
        
        
        self.tableView = UITableView()
        self.addSubview(self.tableView)
        self.tableView.backgroundColor = UIColor.blueColor().colorWithAlphaComponent(0.5)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
   
    
    //MARK: - UIView override
    
    override func layoutSubviews() {
        
        super.layoutSubviews()
        
        let yPoint: CGFloat = 0.0
        self.tableView.frame = CGRectMake(0.0, yPoint, self.bounds.size.width, self.bounds.size.height - yPoint)
    }
}
