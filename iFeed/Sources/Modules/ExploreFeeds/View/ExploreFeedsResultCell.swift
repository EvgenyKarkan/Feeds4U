//
//  ExploreFeedsResultCell.swift
//  iFeed
//
//  Created by Evgeny Karkan on 08.04.2023.
//  Copyright © 2023 Evgeny Karkan. All rights reserved.
//

import UIKit

private enum Constants {
    static let addImage = UIImage(systemName: "arrow.down.circle")
    static let addedImage = UIImage(systemName: "checkmark.circle")
}

final class ExploreFeedsResultCell: UITableViewCell, Reusable {

    // MARK: - Properties
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var addImageView: UIImageView!

    private var isShowingAddedState = false

    // MARK: - Base override
    override func awakeFromNib() {
        super.awakeFromNib()

        MainActor.assumeIsolated {
            resetUI()
        }
    }

    // no prepareForReuse
    // Avoid clearing labels during fast scrolling. The next configure pass replaces
    // all visible content, and skipping temporary nil assignments prevents extra layout work.

    // MARK: - Public
    func update(title: String?, description: String?, isAdded: Bool) {
        update(titleLabel, with: title)
        update(descriptionLabel, with: description)
        updateStatusImage(isAdded: isAdded)
    }
}

// MARK: - Private
private extension ExploreFeedsResultCell {

    func resetUI() {
        update(titleLabel, with: nil)
        update(descriptionLabel, with: nil)
        updateStatusImage(isAdded: false)
    }

    func update(_ label: UILabel, with text: String?) {
        let shouldHide = text == nil

        // Hidden arranged labels are removed from UIStackView layout. That keeps cells compact
        // when either title or description is missing and matches the cached height calculation.
        if label.isHidden != shouldHide {
            label.isHidden = shouldHide
        }

        if label.text != text {
            label.text = text
        }
    }

    func updateStatusImage(isAdded: Bool) {
        guard isShowingAddedState != isAdded || addImageView.image == nil else {
            return
        }

        isShowingAddedState = isAdded
        addImageView.image = isAdded ? Constants.addedImage : Constants.addImage
        addImageView.tintColor = isAdded ? .label : .systemGray4
        addImageView.isHidden = false
    }
}
