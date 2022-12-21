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
            topLabel.text = titleText
        }
    }

    var subTitleText: String? {
        didSet {
            bottomLabel.text = subTitleText
        }
    }

    var itemsCountText: String? {
        didSet {
            countLabel.text = itemsCountText
            countLabel.isHidden = (itemsCountText == nil)

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

        itemsCountText = nil

        dotView.layer.cornerRadius = dotView.frame.height / 2
        dotView.layer.cornerCurve = .continuous
        dotView.layer.masksToBounds = true
    }
}

// MARK: - Reusable Protocol
public protocol Reusable: AnyObject {
    static var reuseId: String { get }
}

public extension Reusable {
    static var reuseId: String {
        return String(describing: self)
    }
}
