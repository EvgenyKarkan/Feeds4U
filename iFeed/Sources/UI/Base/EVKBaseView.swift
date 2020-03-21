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
    private (set) var tableView: UITableView = UITableView()
    private var bottomLabel: UILabel = UILabel()
    
    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialViewSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init() {
        super.init(frame: CGRect.zero)
        
        initialViewSetup()
    }
    
    // MARK: - UIView override
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let yPoint: CGFloat = 0.0
        tableView.frame = CGRect(x: 0.0, y: yPoint, width: bounds.width, height: bounds.height - yPoint)
        
        bottomLabel.sizeToFit()
        bottomLabel.frame = CGRect(x: bounds.width / 2 - bottomLabel.frame.width / 2,
                                   y: bounds.height / 2 - bottomLabel.frame.height / 2,
                                   width: bottomLabel.frame.width,
                                   height: bottomLabel.frame.height)
        bottomLabel.frame = bottomLabel.frame.integral
    }
    
    // MARK: - Public API
    func initialViewSetup() {
        //to override in subclasses
        backgroundColor = .white
        
        bottomLabel.backgroundColor = .white
        bottomLabel.font = UIFont(name: "HelveticaNeue", size: 16.0)
        bottomLabel.textAlignment = .center
        bottomLabel.numberOfLines = 0
        bottomLabel.text = "No any RSS feed"
        bottomLabel.textColor = UIColor(named: "Tangerine")
        addSubview(bottomLabel)
        
        tableView.backgroundColor = .white
        tableView.cellLayoutMarginsFollowReadableWidth = false
        addSubview(tableView)
    }
}
