//
//  FeedFolderHeaderView.swift
//  iFeed
//
//  Created by Evgeny Karkan on 25.05.2026.
//  Copyright © 2026 Evgeny Karkan. All rights reserved.
//

import UIKit

final class FeedFolderHeaderView: UITableViewHeaderFooterView, Reusable {

    // MARK: - Properties
    var onToggle: (() -> Void)?

    private let chevronImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .separator
        imageView.contentMode = .center
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()

    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Init
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    // MARK: - Public
    func configure(name: String, feedCount: Int, isExpanded: Bool) {
        nameLabel.text = name.uppercased()
        countLabel.text = "\(feedCount)"

        let imageName = isExpanded ? "chevron.down" : "chevron.right"
        UIView.transition(with: chevronImageView, duration: 0.2, options: .transitionCrossDissolve) {
            self.chevronImageView.image = UIImage(systemName: imageName)
        }
    }
}

// MARK: - Private
private extension FeedFolderHeaderView {

    func setupUI() {

        let stack = UIStackView(arrangedSubviews: [nameLabel, countLabel, chevronImageView])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            chevronImageView.widthAnchor.constraint(equalToConstant: 16),
            chevronImageView.heightAnchor.constraint(equalToConstant: 16),

            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(headerTapped))
        contentView.addGestureRecognizer(tap)

        contentView.backgroundColor = UIColor(
            red: .random(in: 0.3...1),
            green: .random(in: 0.3...1),
            blue: .random(in: 0.3...1),
            alpha: 1
        )
    }

    @objc func headerTapped() {
        onToggle?()
    }
}
