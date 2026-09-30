//
//  RefreshControlExample.swift
//  LumiKitExample
//
//  Pull to Refresh: LMKLottieRefreshControl with the bundled ring.
//

import LumiKitCore
import LumiKitLottie
import LumiKitUI
import SnapKit
import UIKit

// MARK: - Pull to Refresh

final class RefreshControlDetailViewController: UIViewController, UITableViewDataSource {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var refreshControl: LMKLottieRefreshControl?
    private var refreshTask: Task<Void, Never>?
    private var rows = (1 ... 8).map { "Row \($0)" }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Pull to Refresh"
        view.backgroundColor = LMKColor.backgroundPrimary

        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "row")
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // `install` returns nil under the Mac idiom (UIRefreshControl is unsupported there);
        // the Command-R key command below covers that case.
        refreshControl = LMKLottieRefreshControl.install(on: tableView, style: LMKLottieRefreshControl.Style(tintColor: LMKColor.primary)) { [weak self] in
            self?.refresh()
        }
        if refreshControl == nil {
            tableView.tableHeaderView = makeMacHeader()
        }
    }

    deinit {
        refreshTask?.cancel()
    }

    override var canBecomeFirstResponder: Bool { true }

    override var keyCommands: [UIKeyCommand]? {
        [LMKLottieRefreshControl.makeRefreshKeyCommand(action: #selector(refreshFromKeyCommand))]
    }

    @objc private func refreshFromKeyCommand() {
        refreshControl?.beginRefreshing()
        refresh()
    }

    private func refresh() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.5))
            guard let self, !Task.isCancelled else { return }
            rows.insert("Refreshed at \(LMKDateFormat.string(Date(), date: .none, time: .short))", at: 0)
            tableView.reloadData()
            refreshControl?.endRefreshing()
        }
    }

    private func makeMacHeader() -> UIView {
        let label = UILabel.lmk_make(.caption, text: "Pull to refresh is unavailable under the Mac idiom; press Command-R instead.")
        label.textAlignment = .center
        let container = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: LMKLayout.rowHeight))
        container.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(LMKSpacing.large)
        }
        return container
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "row", for: indexPath)
        cell.lmk_applyListRow(LMKListRowConfiguration(title: rows[indexPath.row], trailing: .none))
        return cell
    }
}
