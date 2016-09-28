//
//  EVKBaseView.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/5/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//


class EVKBaseView: UIView {

    // MARK: - Properties
    private (set) var tableView: UITableView!
    private var bottomLabel: UILabel!
    
    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.initialViewSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init() {
        super.init(frame: CGRectZero)
        
        self.initialViewSetup()
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
    
    // MARK: - Public API
    func initialViewSetup() {
        //to override in subclasses
        self.backgroundColor = UIColor.whiteColor()
        
        bottomLabel                      = UILabel()
        self.bottomLabel.backgroundColor = UIColor.whiteColor()
        self.bottomLabel.font            = UIFont (name: "HelveticaNeue", size: 16.0)
        self.bottomLabel.textAlignment   = NSTextAlignment.Center
        self.bottomLabel.numberOfLines   = 0
        self.bottomLabel.text            = "No any RSS feed"
        self.bottomLabel.textColor       = UIColor(red:0.99, green:0.7, blue:0.23, alpha:1)
        self.addSubview(self.bottomLabel)
        
        tableView                      = UITableView()
        self.tableView.backgroundColor = UIColor.whiteColor()
        
        if #available(iOS 9.0, *) {
            self.tableView.cellLayoutMarginsFollowReadableWidth = false
        }
        
        self.addSubview(self.tableView)
    }
}
