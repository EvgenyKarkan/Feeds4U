//
//  FeedSearchResultsCell.swift
//  iFeed
//
//  Created by Evgeny Karkan on 08.04.2023.
//  Copyright © 2023 Evgeny Karkan. All rights reserved.
//

import UIKit

final class FeedSearchResultsCell: UITableViewCell, Reusable {

    // MARK: - Properties
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!

    @IBOutlet private weak var imagesStackView: UIStackView!
    @IBOutlet private weak var addImageView: UIImageView!
    @IBOutlet private weak var checkMarkImageView: UIImageView!

    // MARK: - Base override
    override func awakeFromNib() {
        super.awakeFromNib()

        resetUI()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        resetUI()
    }

    // MARK: - Public
    func updateWithResults(_ model: FeedSearchResults) {
        titleLabel.text = model.data.title?.capitalized
        descriptionLabel.text = model.data.description?.capitalized

        switch model.state {
        case .added:
            checkMarkImageView.isHidden = false
            addImageView.isHidden = true
        case .notAdded:
            addImageView.isHidden = false
            checkMarkImageView.isHidden = true
        }
    }
}

// MARK: - Private
private extension FeedSearchResultsCell {

    func resetUI() {
        titleLabel.text = nil
        descriptionLabel.text = nil

        addImageView.isHidden = false
        checkMarkImageView.isHidden = true
    }
}
