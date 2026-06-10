//
//  ExploreFeedsResultsViewController.swift
//  iFeed
//
//  Created by Evgeny Karkan on 09.04.2023.
//  Copyright © 2023 Evgeny Karkan. All rights reserved.
//

import UIKit

/// Shows feed discovery results in a table optimized for smooth scrolling.
///
/// The cell layout is still defined in the XIB and rendered by Auto Layout, but row heights are
/// calculated from the normalized display strings before scrolling starts. That avoids per-cell
/// Auto Layout height measurement on the scroll path, while still supporting variable-height rows
/// and compact rows when title or description is missing.
final class ExploreFeedsResultsViewController: UITableViewController {

    // MARK: - Properties
    var presenter: (any ExploreFeedsViewDelegate)?

    private enum Constants {
        static let estimatedRowHeight: CGFloat = 74
        static let minimumRowHeight: CGFloat = 74
        static let horizontalInsets: CGFloat = 78
        static let verticalInsets: CGFloat = 32
        static let labelsSpacing: CGFloat = 5
        static let titleFont = UIFont(name: "HelveticaNeue", size: 16) ?? .systemFont(ofSize: 16)
        static let descriptionFont = UIFont(name: "HelveticaNeue-Light", size: 12) ?? .systemFont(ofSize: 12, weight: .light)
    }

    /// Prepared row data used by the table view.
    ///
    /// The cell still uses Auto Layout for rendering, but row heights are calculated here from
    /// normalized display text. This avoids asking UIKit to measure every cell while scrolling.
    private struct CellViewModel: Equatable {
        let title: String?
        let description: String?
        let rssURL: String?
        let isAdded: Bool
        let rowHeight: CGFloat

        init(result: ExploreFeedsResult, contentWidth: CGFloat) {
            title = Self.displayText(from: result.data.title)
            description = Self.displayText(from: result.data.description)
            rssURL = result.data.rssURL
            isAdded = result.isAdded
            rowHeight = Self.calculateRowHeight(title: title, description: description, contentWidth: contentWidth)
        }

        private static func displayText(from text: String?) -> String? {
            // Empty or whitespace-only values are treated as missing so the cell can hide
            // that label and the height cache can remove the matching vertical space.
            guard let value = text?.collapsingWhitespace(), !value.isEmpty else {
                return nil
            }

            return value.capitalized
        }

        /// Mirrors the XIB's vertical layout in a cheap string measurement pass.
        ///
        /// This keeps dynamic row heights, but moves the expensive sizing work out of
        /// `cellForRowAt`/scrolling and into data preparation.
        private static func calculateRowHeight(title: String?, description: String?, contentWidth: CGFloat) -> CGFloat {
            // Text does not span the full table width: subtract left padding, icon width,
            // spacing around the icon, and right padding from the available row width.
            let labelWidth = max(contentWidth - Constants.horizontalInsets, .zero)

            // Measure each label with the same font and width used by the XIB.
            // Missing labels return zero because the cell hides them in the stack view.
            let titleHeight = height(for: title, font: Constants.titleFont, width: labelWidth)
            let descriptionHeight = height(for: description, font: Constants.descriptionFont, width: labelWidth)

            // UIStackView only applies spacing between visible arranged subviews.
            let spacing = titleHeight > .zero && descriptionHeight > .zero ? Constants.labelsSpacing : .zero
            let textHeight = titleHeight + spacing + descriptionHeight

            // Add top/bottom padding, round to a pixel-stable value, and keep the default
            // one-line design height as the minimum for sparse or missing text.
            return max(Constants.minimumRowHeight, ceil(Constants.verticalInsets + textHeight))
        }

        /// Returns the rendered text height for one label, or zero when that label is hidden.
        private static func height(for text: String?, font: UIFont, width: CGFloat) -> CGFloat {
            guard let text, !text.isEmpty, width > .zero else {
                return .zero
            }

            let constraintSize = CGSize(width: width, height: .greatestFiniteMagnitude)
            let boundingRect = (text as NSString).boundingRect(
                with: constraintSize,
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: font],
                context: nil
            )

            return ceil(boundingRect.height)
        }
    }

    private var latestResults: [ExploreFeedsResult] = []
    private var cellViewModels: [CellViewModel] = []
    private var cellSizingWidth: CGFloat = .zero
    private let reuseId = ExploreFeedsResultCell.reuseId

    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
        presenter?.onViewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // The height cache depends on the final table width. Re-check after layout so
        // presentation changes, rotation, or safe-area changes keep wrapping correct.
        refreshCachedHeightsIfNeeded()
    }

    // MARK: - Action
    @objc private func dismissScreen() {
        dismiss(animated: true)
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.row < cellViewModels.count else {
            return Constants.minimumRowHeight
        }

        return cellViewModels[indexPath.row].rowHeight
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.row < cellViewModels.count else {
            return Constants.estimatedRowHeight
        }

        return cellViewModels[indexPath.row].rowHeight
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellViewModels.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseId) as? ExploreFeedsResultCell,
              indexPath.row < cellViewModels.count else {
            return UITableViewCell()
        }

        configure(cell, at: indexPath)

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < cellViewModels.count,
              let url = cellViewModels[indexPath.row].rssURL,
              !url.isEmpty else {
            return
        }

        presenter?.onViewNeedsToAddFeed(from: url)
    }
}

// MARK: - Private
private extension ExploreFeedsResultsViewController {

    func setupTableView() {
        let nibName = String(describing: ExploreFeedsResultCell.self)
        tableView.register(UINib(nibName: nibName, bundle: nil), forCellReuseIdentifier: reuseId)
        // Row heights are calculated from the display strings once per data/width update.
        // This preserves variable-height cells without asking Auto Layout to measure rows while scrolling.
        tableView.rowHeight = Constants.estimatedRowHeight
        tableView.estimatedRowHeight = Constants.estimatedRowHeight
    }

    func configure(_ cell: ExploreFeedsResultCell, at indexPath: IndexPath) {
        let viewModel = cellViewModels[indexPath.row]
        cell.update(title: viewModel.title, description: viewModel.description, isAdded: viewModel.isAdded)
    }

    func effectiveContentWidth() -> CGFloat {
        return max(tableView.bounds.width, view.bounds.width)
    }

    private func makeCellViewModels(from results: [ExploreFeedsResult], contentWidth: CGFloat) -> [CellViewModel] {
        return results.map { result in
            CellViewModel(result: result, contentWidth: contentWidth)
        }
    }

    func refreshCachedHeightsIfNeeded() {
        // Text wrapping depends on available width. If the table width changes after layout
        // (rotation, sheet resizing, safe-area changes), rebuild the cached heights once.
        let contentWidth = effectiveContentWidth()
        guard !latestResults.isEmpty,
              abs(contentWidth - cellSizingWidth) > 0.5 else {
            return
        }

        cellSizingWidth = contentWidth
        cellViewModels = makeCellViewModels(from: latestResults, contentWidth: contentWidth)
        tableView.reloadData()
    }
}

// MARK: - ExploreFeedsViewProtocol
extension ExploreFeedsResultsViewController: @MainActor ExploreFeedsViewProtocol {

    func updateOnDidLoad(with viewState: ExploreFeedsViewState) {
        navigationItem.title = viewState.webPageTitle
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(dismissScreen)
        )
        navigationItem.rightBarButtonItem?.tintColor = .systemBlue

        update(with: viewState)
    }

    /// Applies new presenter state while avoiding unnecessary table view work.
    ///
    /// Full reloads are used only when row count or row heights change. If the geometry is
    /// unchanged, visible cells are patched in place so active scrolling is not interrupted.
    func update(with viewState: ExploreFeedsViewState) {
        // Keep the previous prepared rows so we can decide whether a full table reload is needed.
        let oldCellViewModels = cellViewModels

        // Store raw results for later height recalculation if the table width changes after layout.
        latestResults = viewState.exploreResults

        // Row height depends on text wrapping, and text wrapping depends on the current content width.
        cellSizingWidth = effectiveContentWidth()

        // Build display-ready rows once: normalized strings, saved state, RSS URL, and cached height.
        cellViewModels = makeCellViewModels(from: latestResults, contentWidth: cellSizingWidth)

        // A row count change changes table geometry, so reload the table instead of patching cells.
        guard oldCellViewModels.count == cellViewModels.count else {
            tableView.reloadData()
            return
        }

        // Compare cached heights. Text changes can alter wrapping/height even when row count is stable.
        let didChangeAnyHeight = zip(oldCellViewModels, cellViewModels).contains { oldViewModel, newViewModel in
            oldViewModel.rowHeight != newViewModel.rowHeight
        }

        guard !didChangeAnyHeight else {
            // Height changes require a table reload so UIKit updates its row geometry.
            tableView.reloadData()
            return
        }

        // At this point geometry is stable. Only visible changed cells need to be reconfigured;
        // offscreen cells will be configured normally when UITableView dequeues them later.
        let visibleIndexPaths = tableView.indexPathsForVisibleRows ?? []
        visibleIndexPaths.forEach { indexPath in
            guard indexPath.row < cellViewModels.count,
                  oldCellViewModels[indexPath.row] != cellViewModels[indexPath.row],
                  let cell = tableView.cellForRow(at: indexPath) as? ExploreFeedsResultCell else {
                return
            }

            // Patch status/text on the existing cell without row reload animations or scroll disruption.
            configure(cell, at: indexPath)
        }
    }

    func showFeedIsAlreadySavedError() {
        showAlreadySavedFeedAlert()
    }

    func showFeedParsingError(_ message: String) {
        showErrorAlert(message)
    }

    func showActivityIndicator() {
        showSpinner()
    }

    func hideActivityIndicator() {
        hideSpinner(nil)
    }
}
