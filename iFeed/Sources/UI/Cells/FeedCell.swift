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
                return
            }

            // TODO: - Put this logic out of Cell
            let cleanedText = text
                .components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
                .joined(separator: " ")

            topLabel.text = cleanedText
            topLabel.isHidden = cleanedText.isEmpty
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

    var wasReadCell: Bool = false {
        didSet {
            dotView.isHidden = wasReadCell
        }
    }

    // MARK: - Base override
    override func awakeFromNib() {
        super.awakeFromNib()

        titleText = nil
        subTitleText = nil
        itemsCountText = nil

        dotView.layer.cornerRadius = dotView.bounds.midY
        dotView.layer.cornerCurve = .continuous
        dotView.layer.masksToBounds = true
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
