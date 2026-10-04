//
//  LMKNetworkHistoryViewController.swift
//  LumiKit
//
//  List of captured network requests, kept current from the store's change
//  notification. Tap a row for the request and response details.
//  Debug builds only (`LMK_ENABLE_NETWORK_LOGGING`) — zero footprint in release.
//

#if LMK_ENABLE_NETWORK_LOGGING && canImport(UIKit)

    import LumiKitCore
    import LumiKitUI
    import SnapKit
    import UIKit

    /// Card page listing the requests `LMKNetworkLogger` captured, newest first, with a Clear
    /// action; rows push `LMKNetworkDetailViewController`.
    public final class LMKNetworkHistoryViewController: LMKCardPageViewController {
        // MARK: - Configurable Strings

        /// Strings of the history screen (named apart from the inherited card-page `strings`).
        public nonisolated struct HistoryStrings: Sendable, Equatable {
            /// Screen title.
            public var title: String
            /// Empty state shown while no request has been captured.
            public var empty: String
            /// Accessibility label of the trash item.
            public var clearAccessibilityLabel: String

            public init(
                title: String = LMKLocalized("networkHistory.title"),
                empty: String = LMKLocalized("networkHistory.empty"),
                clearAccessibilityLabel: String = LMKLocalized("networkHistory.clear.accessibilityLabel")
            ) {
                self.title = title
                self.empty = empty
                self.clearAccessibilityLabel = clearAccessibilityLabel
            }
        }

        /// Process-wide strings, read when the screen is created.
        public nonisolated(unsafe) static var historyStrings = HistoryStrings()

        // MARK: - Properties

        private static let cellIdentifier = "LMKNetworkRequestRow"

        public private(set) lazy var tableView: UITableView = {
            let table = UITableView(frame: .zero, style: .plain)
            table.delegate = self
            table.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellIdentifier)
            table.backgroundColor = LMKColor.backgroundPrimary
            table.separatorStyle = .singleLine
            table.separatorColor = LMKColor.divider
            table.rowHeight = UITableView.automaticDimension
            return table
        }()

        private lazy var dataSource = UITableViewDiffableDataSource<Int, UUID>(tableView: tableView) { [weak self] tableView, indexPath, id in
            let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellIdentifier, for: indexPath)
            if let self, let record = recordsByID[id] {
                cell.lmk_applyListRow(Self.rowConfiguration(for: record), backgroundColor: LMKColor.backgroundPrimary)
            }
            return cell
        }

        private let emptyStateView = LMKEmptyStateView(style: .card)
        private var recordsByID: [UUID: LMKNetworkRequestRecord] = [:]
        /// Reloads once per burst of store changes; released with the screen.
        private var changeObserver: LMKNetworkLogger.ChangeObserver?

        /// The records currently listed (newest first).
        public private(set) var records: [LMKNetworkRequestRecord] = []

        // MARK: - Initialization

        public init() {
            super.init(title: Self.historyStrings.title)
            trailingItem = LMKNavigationBarItem(systemName: "trash", accessibilityLabel: Self.historyStrings.clearAccessibilityLabel) { [weak self] in
                self?.clearTapped()
            }
        }

        // MARK: - Template Overrides

        override public func setupContent() {
            contentContainerView.addSubview(tableView)
            tableView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            emptyStateView.configure(LMKEmptyStateView.Content(message: Self.historyStrings.empty, icon: .system("network")))
            tableView.backgroundView = emptyStateView.wrappedForTableBackground(backgroundColor: LMKColor.backgroundPrimary)
            _ = dataSource
            reload()
            changeObserver = LMKNetworkLogger.ChangeObserver { [weak self] in
                self?.reload()
            }
        }

        private func clearTapped() {
            LMKNetworkLogger.clearRecords()
            reload()
        }

        // MARK: - Theme

        override public func applyTheme(_ theme: LMKTheme) {
            tableView.estimatedRowHeight = theme.layout.rowHeightEstimated
            super.applyTheme(theme)
        }

        // MARK: - Data

        /// Reads the store and applies a diffable snapshot; rows whose record changed (a
        /// response landed) are reconfigured in place.
        public func reload() {
            let latest = LMKNetworkLogger.records
            var snapshot = NSDiffableDataSourceSnapshot<Int, UUID>()
            snapshot.appendSections([0])
            snapshot.appendItems(latest.map(\.id))
            let changed = latest.filter { record in
                guard let previous = recordsByID[record.id] else { return false }
                return !previous.hasSameResult(as: record)
            }.map(\.id)
            recordsByID = Dictionary(uniqueKeysWithValues: latest.map { ($0.id, $0) })
            records = latest
            if !changed.isEmpty {
                snapshot.reconfigureItems(changed)
            }
            dataSource.lmk_apply(snapshot, animatingDifferences: false, in: tableView)
            emptyStateView.isHidden = !latest.isEmpty
        }

        /// The row for a record: outcome glyph, URL, and a method / status / duration / time line.
        static func rowConfiguration(for record: LMKNetworkRequestRecord) -> LMKListRowConfiguration {
            let (symbol, tint) = outcomeSymbol(for: record.outcome)
            let subtitle = [record.displayMethod, record.displayStatus, record.displayDuration, Self.timeFormatter.string(from: record.timestamp)]
                .joined(separator: " · ")
            return LMKListRowConfiguration(
                title: record.displayURL,
                subtitle: subtitle,
                leading: .symbol(symbol, tint: tint),
                trailing: .disclosure,
                style: LMKListRowConfiguration.Style(titleTextStyle: .caption, subtitleTextStyle: .smallMedium, titleLines: 3)
            )
        }

        /// The glyph and tint that mark an outcome; a redirect is a turn, never an error.
        static func outcomeSymbol(for outcome: LMKNetworkRequestRecord.Outcome) -> (name: String, tint: UIColor) {
            switch outcome {
            case .success: ("checkmark.circle", LMKColor.success)
            case .redirect: ("arrow.triangle.turn.up.right.circle", LMKColor.info)
            case .error: ("exclamationmark.triangle", LMKColor.error)
            case .pending: ("clock", LMKColor.textSecondary)
            }
        }

        private static let timeFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "HH:mm:ss"
            return formatter
        }()
    }

    // MARK: - UITableViewDelegate

    extension LMKNetworkHistoryViewController: UITableViewDelegate {
        public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
            guard let id = dataSource.itemIdentifier(for: indexPath), let record = recordsByID[id] else { return }
            navigationController?.pushViewController(LMKNetworkDetailViewController(record: record), animated: true)
        }
    }

#endif
