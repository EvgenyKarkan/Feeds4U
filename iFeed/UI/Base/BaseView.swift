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
    private(set) lazy var tableView = UITableView()
    private(set) lazy var label = UILabel()

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

    // MARK: - Public API
    func initialViewSetup() {
        backgroundColor = .systemBackground

        /// Label
        label.backgroundColor = backgroundColor
        label.font = .systemFont(ofSize: 18)
        label.textAlignment = .center
        label.numberOfLines = .zero
        label.text = String.localized(key: LocalizableKeys.addNewFeed)
        label.textColor = UIColor(resource: .tangerine)
        addSubview(label)

        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        /// Tableview
        tableView.backgroundColor = backgroundColor
        tableView.cellLayoutMarginsFollowReadableWidth = false
        addSubview(tableView)

        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        ])

        let nib = UINib(nibName: String(describing: FeedCell.self), bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: FeedCell.reuseId)
    }

    func reloadTableView() {
        tableView.reloadData()
    }
}
