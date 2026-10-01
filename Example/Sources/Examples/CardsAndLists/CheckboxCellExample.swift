//
//  CheckboxCellExample.swift
//  LumiKitExample
//
//  Checkbox Cell: Check-off row with a struck-through title.
//

import LumiKitUI
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

    override func setupStackContent() {
        addSectionHeader("LMKCheckboxCell")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "Check-off row for to-dos and checklists: checkbox + strike-through title. "
                + "The checkbox hit area expands to the minimum touch target and reports onValueChange; the host "
                + "also toggles from didSelectRowAt with setDone(_:animated:), so the whole row is a target."))
        stackView.addArrangedSubview(tableView)
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
        // A tap on the checkbox has already flipped the cell; the host only records the value.
        cell.onValueChange = { [weak self] isDone in
            self?.items[indexPath.row].isDone = isDone
        }
        return cell
    }

    // MARK: - UITableViewDelegate

    /// A tap anywhere else on the row: the host flips the value and tells the cell, which animates silently.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        items[indexPath.row].isDone.toggle()
        (tableView.cellForRow(at: indexPath) as? LMKCheckboxCell)?.setDone(items[indexPath.row].isDone, animated: true)
    }
}
