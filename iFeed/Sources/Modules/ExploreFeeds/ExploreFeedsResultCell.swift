//
//  ExploreFeedsResultCell.swift
//  iFeed
//
//  Created by Evgeny Karkan on 08.04.2023.
//  Copyright © 2023 Evgeny Karkan. All rights reserved.
//

import UIKit

final class ExploreFeedsResultCell: UITableViewCell, Reusable {

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
    func updateWithResults(_ model: ExploreFeedsResult) {
        titleLabel.text = model.data.title?.capitalized
        descriptionLabel.text = model.data.description?.capitalized

        checkMarkImageView.isHidden = !model.isAdded
        addImageView.isHidden = model.isAdded
    }
}

// MARK: - Private
private extension ExploreFeedsResultCell {

    func resetUI() {
        titleLabel.text = nil
        descriptionLabel.text = nil

        addImageView.isHidden = false
        checkMarkImageView.isHidden = true
    }
}
