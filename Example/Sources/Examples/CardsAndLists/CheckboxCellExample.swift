//
//  CheckboxCellExample.swift
//  LumiKitExample
//
//  Checkbox Cell: Check-off row with a struck-through title.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Checkbox Cell

final class CheckboxCellDetailViewController: DetailViewController, UITableViewDataSource, UITableViewDelegate {
    private static let rowHeight: CGFloat = 52

    private var items: [(title: String, isDone: Bool)] = [
        ("Water the monstera", true),
        ("Book the vet appointment", false),
        ("Pack chargers and adapters", false),
        ("Renew the passport", false),
    ]

    private lazy var tableView: UITableView = {
        let table = ExampleSelfSizingTableView(frame: .zero, style: .plain)
        table.dataSource = self
        table.delegate = self
        table.isScrollEnabled = false
        table.separatorStyle = .none
        table.backgroundColor = .clear
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = Self.rowHeight
        table.register(LMKCheckboxCell.self, forCellReuseIdentifier: LMKCheckboxCell.reuseIdentifier)
        return table
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("LMKCheckboxCell")
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "Check-off row for to-dos and checklists: checkbox + strike-through title. "
                + "The checkbox hit area expands to the minimum touch target, and the host "
                + "also toggles from didSelectRowAt so the whole row is a target."))
        stack.addArrangedSubview(tableView)
    }

    private func toggleItem(at index: Int) {
        items[index].isDone.toggle()
        // Reload the whole table — the cell sets its checkbox image directly
        // (never via cross-dissolve), so recycled cells can't flash a checkmark.
        tableView.reloadData()
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: LMKCheckboxCell.reuseIdentifier,
            for: indexPath
        ) as? LMKCheckboxCell else {
            return UITableViewCell()
        }
        let item = items[indexPath.row]
        cell.configure(title: item.title, isDone: item.isDone)
        cell.onToggle = { [weak self] in
            self?.toggleItem(at: indexPath.row)
        }
        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        toggleItem(at: indexPath.row)
    }
}
