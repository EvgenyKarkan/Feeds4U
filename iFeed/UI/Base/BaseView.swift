//
//  BaseView.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/5/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit

class BaseView: UIView {

    // MARK: - Properties
    let tableView = UITableView()
    private let label = UILabel()
    
    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialViewSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    init() {
        super.init(frame: .zero)
        
        initialViewSetup()
    }
    
    // MARK: - Base override
    override func layoutSubviews() {
        super.layoutSubviews()
        
        tableView.frame = CGRect(x: .zero, y: .zero, width: bounds.width, height: bounds.height)

        label.sizeToFit()
        label.frame = CGRect(x: bounds.midX - label.bounds.midX,
                             y: bounds.midY - label.bounds.midY,
                             width: label.frame.width,
                             height: label.frame.height)
        label.frame = label.frame.integral
    }
    
    // MARK: - Public API
    func initialViewSetup() {
        backgroundColor = .systemBackground
        
        label.backgroundColor = backgroundColor
        label.font = UIFont(name: "HelveticaNeue", size: 16)
        label.textAlignment = .center
        label.numberOfLines = .zero
        label.text = "No any RSS feed"
        label.textColor = UIColor(named: "Tangerine")
        addSubview(label)
        
        tableView.backgroundColor = backgroundColor
        tableView.cellLayoutMarginsFollowReadableWidth = false
        addSubview(tableView)

        let nib = UINib(nibName: String(describing: FeedCell.self), bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: FeedCell.reuseId)
    }

    func reloadTableView() {
        tableView.reloadData()
    }
}