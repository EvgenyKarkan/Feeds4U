//
//  BaseView.swift
//  iFeed
//
//  Created by Evgeny Karkan on 9/5/15.
//  Copyright (c) 2015 Evgeny Karkan. All rights reserved.
//

import UIKit

class BaseView: UIView { // rename to BaseFeedListView

    // MARK: - Properties
    private(set) lazy var tableView: UITableView = {
        let table = UITableView()
        table.backgroundColor = backgroundColor
        table.cellLayoutMarginsFollowReadableWidth = false
        table.translatesAutoresizingMaskIntoConstraints = false

        // Performance optimizations
        table.estimatedRowHeight = 44
        table.rowHeight = UITableView.automaticDimension

        // Register cell once during initialization
        let nib = UINib(nibName: String(describing: FeedCell.self), bundle: nil)
        table.register(nib, forCellReuseIdentifier: FeedCell.reuseId)

        return table
    }()

    private(set) lazy var label: UILabel = {
        let lbl = UILabel()
        lbl.backgroundColor = backgroundColor
        lbl.font = .systemFont(ofSize: 18)
        lbl.textAlignment = .center
        lbl.numberOfLines = .zero
        lbl.text = String.localized(key: LocalizableKeys.Feed.addNew)
        lbl.textColor = UIColor(resource: .tangerine)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    // MARK: - Init
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

    // MARK: - Public API
    func initialViewSetup() {
        backgroundColor = .systemBackground

        // Add subviews
        addSubview(label)
        addSubview(tableView)

        // Setup constraints once
        setupConstraints()
    }

    func reloadTableView() {
        tableView.reloadData()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Label constraints
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),

            // TableView constraints
            tableView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        ])
    }
}
