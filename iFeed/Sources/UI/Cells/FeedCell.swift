//
//  FeedCell.swift
//  iFeed
//
//  Created by Evgeny Karkan on 21.12.2022.
//  Copyright © 2022 Evgeny Karkan. All rights reserved.
//

import UIKit

final class FeedCell: UITableViewCell, Reusable {

    // MARK: - Properties
    @IBOutlet private weak var topLabel: UILabel!
    @IBOutlet private weak var bottomLabel: UILabel!
    @IBOutlet private weak var countLabel: UILabel!
    @IBOutlet private weak var dotView: UIView!

    var titleText: String? {
        didSet {
            guard let text = titleText, !text.isEmpty else {
                topLabel.isHidden = true
                accessibilityIdentifier = nil
                return
            }
            topLabel.text = text.collapsingWhitespace()
            topLabel.isHidden = false
            accessibilityIdentifier = AccessibilityID.feedCell(title: text)
        }
    }

    var subTitleText: String? {
        didSet {
            guard let text = subTitleText else {
                bottomLabel.isHidden = true
                return
            }
            bottomLabel.text = text
            bottomLabel.isHidden = text.isEmpty
        }
    }

    var itemsCountText: String? {
        didSet {
            countLabel.text = itemsCountText

            let shouldHideLabel = (itemsCountText == Int.zero.description) || (itemsCountText == nil)
            countLabel.isHidden = shouldHideLabel

            dotView.isHidden = true
        }
    }

    private lazy var leadingInset: (constraint: NSLayoutConstraint, base: CGFloat)? = {
        guard let match = contentView.constraints.first(where: { $0.identifier == "leadingInset" }) else {
            return nil
        }
        return (match, match.constant)
    }()

    var isNested: Bool = false {
        didSet {
            guard let inset = leadingInset else {
                return
            }
            inset.constraint.constant = isNested ? inset.base * 1.5 : inset.base
        }
    }

    var wasReadCell: Bool = false {
        didSet {
            dotView.isHidden = wasReadCell
        }
    }

    private let bottomSeparator: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    /// Height of `bottomSeparator`, kept at one physical pixel. Updated whenever
    /// the cell's `displayScale` trait changes (e.g. moving between displays).
    private var separatorHeightConstraint: NSLayoutConstraint?

    // MARK: - Base override
    override func awakeFromNib() {
        super.awakeFromNib()

        MainActor.assumeIsolated {
            dotView.layer.cornerRadius = dotView.bounds.midY
            dotView.layer.cornerCurve = .continuous
            dotView.layer.masksToBounds = true
            dotView.backgroundColor = .systemBlue

            /// The title/subtitle labels already scale via the nib; the count
            /// badge did not — opt it into Dynamic Type to match.
            countLabel.adjustsFontForContentSizeCategory = true

            contentView.addSubview(bottomSeparator)

            let separatorHeight = bottomSeparator.heightAnchor.constraint(equalToConstant: hairlineHeight)
            separatorHeightConstraint = separatorHeight

            NSLayoutConstraint.activate([
                bottomSeparator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                bottomSeparator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                bottomSeparator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                separatorHeight
            ])

            /// `displayScale` is 0 until the cell is in a window; this keeps the
            /// hairline at exactly one physical pixel once that becomes known.
            registerForTraitChanges([UITraitDisplayScale.self]) { (cell: Self, _) in
                cell.separatorHeightConstraint?.constant = cell.hairlineHeight
            }

            resetContent()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        resetContent()
    }

    private func resetContent() {
        topLabel.text = nil
        bottomLabel.text = nil
        countLabel.text = nil

        topLabel.isHidden = false
        bottomLabel.isHidden = false
        countLabel.isHidden = true
        dotView.isHidden = true

        isNested = false
        wasReadCell = false
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        guard editing else {
            return
        }

        topLabel.text = nil
        topLabel.fadeTransition(0.33)
        topLabel.text = titleText

        bottomLabel.text = nil
        bottomLabel.fadeTransition(0.33)
        bottomLabel.text = subTitleText
    }

    // MARK: - Accessibility
    /// VoiceOver reads the title as the label and the subtitle + unread state as
    /// the value (e.g. "Swift Blog" · "3 Unread", or "Swift 6 concurrency" ·
    /// "Jun 16, Unread"). Computed from the live cell state so it stays correct
    /// across reuse regardless of the order properties are set, and without
    /// making the cell a single element — which would hide the editing-mode
    /// delete control from assistive tech.
    override var accessibilityLabel: String? {
        get {
            guard !topLabel.isHidden else {
                return nil
            }
            return topLabel.text
        }
        set { }
    }

    override var accessibilityValue: String? {
        get {
            var parts: [String] = []
            if !bottomLabel.isHidden, let subtitle = bottomLabel.text, !subtitle.isEmpty {
                parts.append(subtitle)
            }
            if let unread = unreadAccessibilityDescription {
                parts.append(unread)
            }
            return parts.isEmpty ? nil : parts.joined(separator: ", ")
        }
        set { }
    }

    /// Spoken unread state — a count for feed rows ("3 Unread") or a flag for an
    /// unread article row ("Unread"). `nil` when there is nothing unread.
    private var unreadAccessibilityDescription: String? {
        let unread = String.localized(key: LocalizableKeys.Accessibility.unread)

        if !countLabel.isHidden, let count = countLabel.text,
           !count.isEmpty, count != Int.zero.description {
            return "\(count) \(unread)"
        }
        if !dotView.isHidden {
            return unread
        }
        return nil
    }
}

// MARK: - Reusable
/// To be adopted by reusable view subclasses in order to have dynamic reuse identifier

protocol Reusable: AnyObject {
    static var reuseId: String { get }
}

extension Reusable {
    static var reuseId: String {
        return String(describing: self)
    }
}
