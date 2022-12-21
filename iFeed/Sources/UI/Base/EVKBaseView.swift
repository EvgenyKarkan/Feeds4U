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
    private(set) var tableView = UITableView()
    private var label = UILabel()
    
    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialViewSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init() {
        super.init(frame: .zero)
        
        initialViewSetup()
    }
    
    // MARK: - UIView override
    override func layoutSubviews() {
        super.layoutSubviews()
        
        tableView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
        
        label.sizeToFit()
        label.frame = CGRect(x: bounds.width / 2 - label.frame.width / 2,
                             y: bounds.height / 2 - label.frame.height / 2,
                             width: label.frame.width,
                             height: label.frame.height)
        label.frame = label.frame.integral
    }
    
    // MARK: - Public API
    func initialViewSetup() {
        //to override in subclasses
        backgroundColor = .white
        
        label.backgroundColor = .white
        label.font = UIFont(name: "HelveticaNeue", size: 16.0)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "No any RSS feed"
        label.textColor = UIColor(named: "Tangerine")
        addSubview(label)
        
        tableView.backgroundColor = .white
        tableView.cellLayoutMarginsFollowReadableWidth = false
        addSubview(tableView)
    }
}
