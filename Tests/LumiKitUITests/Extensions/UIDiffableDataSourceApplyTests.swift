//
//  UIDiffableDataSourceApplyTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - UIDiffableDataSource+LMKApply

@MainActor
struct UIDiffableDataSourceApplyTests {
    private static let frame = CGRect(x: 0, y: 0, width: 320, height: 480)

    private func makeTable() -> (UITableView, UITableViewDiffableDataSource<Int, Int>) {
        let table = UITableView(frame: Self.frame)
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        let dataSource = UITableViewDiffableDataSource<Int, Int>(tableView: table) { table, indexPath, _ in
            table.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        }
        return (table, dataSource)
    }

    private func makeCollection() -> (UICollectionView, UICollectionViewDiffableDataSource<Int, Int>) {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 100, height: 44)
        let collection = UICollectionView(frame: Self.frame, collectionViewLayout: layout)
        collection.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        let dataSource = UICollectionViewDiffableDataSource<Int, Int>(collectionView: collection) { collection, indexPath, _ in
            collection.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        }
        return (collection, dataSource)
    }

    private func snapshot(_ items: [Int]) -> NSDiffableDataSourceSnapshot<Int, Int> {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Int>()
        snapshot.appendSections([0])
        snapshot.appendItems(items)
        return snapshot
    }

    /// Whether any cell has been created. Reads `subviews`, which never triggers
    /// layout; `visibleCells` on a table view does, and would create the cells
    /// this checks for.
    private func hasCells(_ view: UIView) -> Bool {
        view.subviews.contains { $0 is UITableViewCell || $0 is UICollectionViewCell }
    }

    private func makeWindow(hosting view: UIView) -> UIWindow {
        let window = UIWindow(frame: Self.frame)
        window.addSubview(view)
        window.isHidden = false
        return window
    }

    @Test
    func `off-window table apply lands the snapshot without laying out cells`() {
        let (table, dataSource) = makeTable()
        dataSource.lmk_apply(snapshot([1, 2, 3]), animatingDifferences: true, in: table)
        #expect(table.window == nil)
        #expect(dataSource.snapshot().itemIdentifiers == [1, 2, 3])
        #expect(!hasCells(table))
    }

    @Test
    func `on-window table apply diffs into the existing rows`() {
        let (table, dataSource) = makeTable()
        let window = makeWindow(hosting: table)
        dataSource.lmk_apply(snapshot([1, 2]), animatingDifferences: false, in: table)
        table.layoutIfNeeded()
        #expect(table.visibleCells.count == 2)

        dataSource.lmk_apply(snapshot([1, 2, 3]), animatingDifferences: false, in: table)
        table.layoutIfNeeded()
        #expect(dataSource.snapshot().itemIdentifiers == [1, 2, 3])
        #expect(table.numberOfRows(inSection: 0) == 3)
        _ = window
    }

    @Test
    func `off-window collection apply lands the snapshot without laying out cells`() {
        let (collection, dataSource) = makeCollection()
        dataSource.lmk_apply(snapshot([1, 2, 3]), animatingDifferences: true, in: collection)
        #expect(collection.window == nil)
        #expect(dataSource.snapshot().itemIdentifiers == [1, 2, 3])
        #expect(!hasCells(collection))
    }

    @Test
    func `on-window collection apply diffs into the existing items`() {
        let (collection, dataSource) = makeCollection()
        let window = makeWindow(hosting: collection)
        dataSource.lmk_apply(snapshot([1, 2]), animatingDifferences: false, in: collection)
        collection.layoutIfNeeded()
        #expect(collection.visibleCells.count == 2)

        dataSource.lmk_apply(snapshot([1, 2, 3]), animatingDifferences: false, in: collection)
        collection.layoutIfNeeded()
        #expect(collection.numberOfItems(inSection: 0) == 3)
        _ = window
    }
}
