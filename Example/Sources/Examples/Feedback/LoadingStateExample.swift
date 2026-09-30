//
//  LoadingStateExample.swift
//  LumiKitExample
//
//  Loading State: Inline, overlay, and skeleton loading.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Loading State

final class LoadingStateDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Inline Style")
        let inlineLoading = LMKLoadingStateView()
        inlineLoading.startLoading(message: "Loading data...")
        inlineLoading.snp.makeConstraints { $0.height.equalTo(120) }
        stack.addArrangedSubview(inlineLoading)

        addDivider()
        addSectionHeader("Overlay Style")
        let overlayContainer = UIView()
        overlayContainer.backgroundColor = LMKColor.backgroundSecondary
        overlayContainer.layer.cornerRadius = LMKCornerRadius.medium
        overlayContainer.clipsToBounds = true
        overlayContainer.snp.makeConstraints { $0.height.equalTo(160) }

        let overlayLoading = LMKLoadingStateView(style: .overlay)
        overlayLoading.startLoading(message: "Saving changes...")
        overlayContainer.addSubview(overlayLoading)
        overlayLoading.snp.makeConstraints { $0.edges.equalToSuperview() }
        stack.addArrangedSubview(overlayContainer)

        addDivider()
        addSectionHeader("Skeleton Cell")
        let skeletonTable = SkeletonTableView()
        skeletonTable.snp.makeConstraints { $0.height.equalTo(280) }
        stack.addArrangedSubview(skeletonTable)
    }
}

/// Embedded table view that displays skeleton cells with shimmer animation.
private final class SkeletonTableView: UIView, UITableViewDataSource {
    private static let cellID = "skeleton"
    private static let rowCount = 3

    private let tableView = UITableView(frame: .zero, style: .plain)

    override init(frame: CGRect) {
        super.init(frame: frame)
        tableView.dataSource = self
        tableView.register(LMKSkeletonCell.self, forCellReuseIdentifier: Self.cellID)
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.backgroundColor = .clear
        tableView.allowsSelection = false

        addSubview(tableView)
        tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Self.rowCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellID, for: indexPath) as? LMKSkeletonCell else {
            return UITableViewCell()
        }
        // Cells shimmer on their own once on screen; the index only staggers the sweep.
        cell.staggerIndex = indexPath.row
        return cell
    }
}
