//
//  EVKBaseView.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/5/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit


class EVKBaseView: UIView {

    // MARK: - Properties
    var tableView: UITableView!
    private var bottomLabel: UILabel!
    
    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.whiteColor()
        
        self.bottomLabel                 = UILabel()
        self.bottomLabel.backgroundColor = UIColor.whiteColor()
        self.bottomLabel.font            = UIFont (name: "HelveticaNeue", size: 16.0)
        self.bottomLabel.textAlignment   = NSTextAlignment.Center
        self.bottomLabel.numberOfLines   = 0
        self.bottomLabel.text            = "You don't have any RSS feed yet"
        self.bottomLabel.textColor       = UIColor.orangeColor()
        self.addSubview(self.bottomLabel)
        
        self.tableView                 = UITableView()
        self.tableView.backgroundColor = UIColor.whiteColor()
        self.addSubview(self.tableView)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UIView override
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let yPoint: CGFloat  = 0.0
        self.tableView.frame = CGRectMake(0.0, yPoint, self.bounds.size.width, self.bounds.size.height - yPoint)
        
        self.bottomLabel.sizeToFit()
        self.bottomLabel.frame = CGRectMake(self.bounds.size.width / 2 - CGRectGetWidth(self.bottomLabel.frame) / 2,
                                            self.bounds.size.height / 2 - CGRectGetHeight(self.bottomLabel.frame) / 2,
                                            CGRectGetWidth(self.bottomLabel.frame),
                                            CGRectGetHeight(self.bottomLabel.frame))
        self.bottomLabel.frame = CGRectIntegral(self.bottomLabel.frame)
    }
}
