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
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.tintColor = .tertiaryLabel
        imageView.contentMode = .center
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption2)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let bottomSeparator: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    /// Height of `bottomSeparator`, kept at one physical pixel. Updated whenever
    /// the view's `displayScale` trait changes (e.g. moving between displays).
    private var separatorHeightConstraint: NSLayoutConstraint?

    // MARK: - Init
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        setupUI()

        /// `displayScale` is 0 until the view is in a window; this keeps the
        /// hairline at exactly one physical pixel once that becomes known.
        registerForTraitChanges([UITraitDisplayScale.self]) { (header: Self, _) in
            header.separatorHeightConstraint?.constant = header.hairlineHeight
        }
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    // MARK: - Public
    func configure(name: String, feedCount: Int, isExpanded: Bool) {
        nameLabel.text = name.uppercased()
        countLabel.text = "\(feedCount)"

        let angle: CGFloat = isExpanded ? .pi / 2 : .zero
        UIView.animate(withDuration: CATransaction.animationDuration()) {
            self.chevronImageView.transform = CGAffineTransform(rotationAngle: angle)
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
        contentView.addSubview(bottomSeparator)

        let stackBottomConstraint = stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        stackBottomConstraint.priority = .defaultHigh

        let separatorHeight = bottomSeparator.heightAnchor.constraint(equalToConstant: hairlineHeight)
        separatorHeightConstraint = separatorHeight

        NSLayoutConstraint.activate([
            chevronImageView.widthAnchor.constraint(equalToConstant: 16),
            chevronImageView.heightAnchor.constraint(equalToConstant: 16),

            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stackBottomConstraint,

            bottomSeparator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            bottomSeparator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomSeparator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorHeight
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(headerTapped))
        contentView.addGestureRecognizer(tap)

//        contentView.backgroundColor = UIColor(
//            red: .random(in: 0.3...1),
//            green: .random(in: 0.3...1),
//            blue: .random(in: 0.3...1),
//            alpha: 1
//        )

        contentView.backgroundColor = .systemBackground
    }

    @objc func headerTapped() {
        onToggle?()
    }
}
