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
    fileprivate (set) var tableView: UITableView!
    fileprivate var bottomLabel: UILabel!
    
    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.initialViewSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init() {
        super.init(frame: CGRect.zero)
        
        self.initialViewSetup()
    }
    
    // MARK: - UIView override
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let yPoint: CGFloat  = 0.0
        self.tableView.frame = CGRect(x: 0.0, y: yPoint, width: self.bounds.size.width, height: self.bounds.size.height - yPoint)
        
        self.bottomLabel.sizeToFit()
        self.bottomLabel.frame = CGRect(x: self.bounds.size.width / 2 - self.bottomLabel.frame.width / 2,
                                            y: self.bounds.size.height / 2 - self.bottomLabel.frame.height / 2,
                                            width: self.bottomLabel.frame.width,
                                            height: self.bottomLabel.frame.height)
        self.bottomLabel.frame = self.bottomLabel.frame.integral
    }
    
    // MARK: - Public API
    func initialViewSetup() {
        //to override in subclasses
        self.backgroundColor = UIColor.white
        
        bottomLabel                      = UILabel()
        self.bottomLabel.backgroundColor = UIColor.white
        self.bottomLabel.font            = UIFont (name: "HelveticaNeue", size: 16.0)
        self.bottomLabel.textAlignment   = NSTextAlignment.center
        self.bottomLabel.numberOfLines   = 0
        self.bottomLabel.text            = "No any RSS feed"
        self.bottomLabel.textColor       = UIColor(red:0.99, green:0.7, blue:0.23, alpha:1)
        self.addSubview(self.bottomLabel)
        
        tableView                      = UITableView()
        self.tableView.backgroundColor = UIColor.white
        
        if #available(iOS 9.0, *) {
            self.tableView.cellLayoutMarginsFollowReadableWidth = false
        }
        
        self.addSubview(self.tableView)
    }
}
