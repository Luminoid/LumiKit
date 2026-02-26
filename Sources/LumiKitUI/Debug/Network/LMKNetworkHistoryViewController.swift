//
//  LMKNetworkHistoryViewController.swift
//  LumiKit
//
//  List view showing captured network requests. Tap to see request/response details.
//  DEBUG builds only — zero footprint in release.
//

#if DEBUG

    import LumiKitCore
    import LumiKitNetwork
    import SnapKit
    import UIKit

    public final class LMKNetworkHistoryViewController: LMKCardPageController, UITableViewDataSource, UITableViewDelegate {
        // MARK: - Properties

        private lazy var tableView: UITableView = {
            let table = UITableView(frame: .zero, style: .plain)
            table.dataSource = self
            table.delegate = self
            table.register(LMKNetworkRequestCell.self, forCellReuseIdentifier: "Cell")
            table.backgroundColor = LMKColor.backgroundPrimary
            table.separatorStyle = .singleLine
            table.separatorColor = LMKColor.textSecondary.withAlphaComponent(0.2)
            table.rowHeight = UITableView.automaticDimension
            table.estimatedRowHeight = 80
            return table
        }()

        private var records: [LMKNetworkRequestRecord] = []
        private var refreshTimer: Timer?

        // MARK: - Initialization

        public init() {
            super.init(title: "Network History")
        }

        // MARK: - Configuration

        override public var headerHeight: CGFloat { LMKCardPageLayout.headerHeight }
        override public var showsLeadingButton: Bool { true }
        override public var leadingButtonSymbol: String { "arrow.left" }
        override public var trailingButtonSymbol: String { "trash" }

        // MARK: - Template Overrides

        override public func setupContent() {
            contentContainerView.addSubview(tableView)
            tableView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            loadRecords()

            // Auto-refresh to capture new requests
            refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.loadRecords()
                }
            }
        }

        override public func leadingButtonTapped() {
            navigationController?.popViewController(animated: true)
        }

        override public func trailingButtonTapped() {
            LMKNetworkLogger.clearRecords()
            loadRecords()
        }

        // MARK: - Data

        private func loadRecords() {
            records = LMKNetworkLogger.records
            tableView.reloadData()
        }

        // MARK: - UITableViewDataSource

        public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            if records.isEmpty {
                return 1 // Show "No requests" cell
            }
            return records.count
        }

        public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! LMKNetworkRequestCell

            if records.isEmpty {
                cell.configureEmpty()
            } else {
                cell.configure(with: records[indexPath.row])
            }

            return cell
        }

        // MARK: - UITableViewDelegate

        public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
            guard !records.isEmpty else { return }
            let record = records[indexPath.row]
            let detailVC = LMKNetworkDetailViewController(record: record)
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }

    // MARK: - LMKNetworkRequestCell

    private final class LMKNetworkRequestCell: UITableViewCell {
        private lazy var methodLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.monospacedSystemFont(ofSize: 11, weight: .bold)
            label.textAlignment = .center
            return label
        }()

        private lazy var statusLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.monospacedSystemFont(ofSize: 11, weight: .semibold)
            label.textAlignment = .center
            return label
        }()

        private lazy var urlLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
            label.numberOfLines = 3
            label.textColor = LMKColor.textPrimary
            return label
        }()

        private lazy var timeLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.monospacedSystemFont(ofSize: 11, weight: .regular)
            label.textColor = LMKColor.textSecondary
            return label
        }()

        private lazy var durationLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.monospacedSystemFont(ofSize: 11, weight: .regular)
            label.textColor = LMKColor.textSecondary
            label.textAlignment = .right
            return label
        }()

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setupUI()
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        private func setupUI() {
            backgroundColor = LMKColor.backgroundSecondary

            contentView.addSubview(methodLabel)
            contentView.addSubview(statusLabel)
            contentView.addSubview(urlLabel)
            contentView.addSubview(timeLabel)
            contentView.addSubview(durationLabel)

            methodLabel.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(LMKSpacing.small)
                make.leading.equalToSuperview().offset(LMKSpacing.small)
                make.width.equalTo(40)
            }

            statusLabel.snp.makeConstraints { make in
                make.top.equalTo(methodLabel.snp.bottom).offset(2)
                make.leading.equalTo(methodLabel)
                make.width.equalTo(40)
            }

            urlLabel.snp.makeConstraints { make in
                make.top.equalTo(methodLabel)
                make.leading.equalTo(methodLabel.snp.trailing).offset(LMKSpacing.xs)
                make.trailing.equalToSuperview().offset(-LMKSpacing.small)
            }

            timeLabel.snp.makeConstraints { make in
                make.top.equalTo(urlLabel.snp.bottom).offset(2)
                make.leading.equalTo(urlLabel)
                make.bottom.equalToSuperview().offset(-LMKSpacing.small)
            }

            durationLabel.snp.makeConstraints { make in
                make.top.equalTo(timeLabel)
                make.trailing.equalToSuperview().offset(-LMKSpacing.medium)
            }
        }

        func configure(with record: LMKNetworkRequestRecord) {
            methodLabel.text = record.displayMethod
            methodLabel.textColor = LMKColor.textPrimary

            statusLabel.text = record.displayStatus
            if record.isSuccess {
                statusLabel.textColor = LMKColor.success
            } else if record.isError {
                statusLabel.textColor = LMKColor.error
            } else {
                statusLabel.textColor = LMKColor.textSecondary
            }

            urlLabel.text = record.displayURL

            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            timeLabel.text = formatter.string(from: record.timestamp)

            durationLabel.text = record.displayDuration
        }

        func configureEmpty() {
            methodLabel.text = ""
            statusLabel.text = ""
            urlLabel.text = "No network requests captured yet"
            urlLabel.textColor = LMKColor.textSecondary
            timeLabel.text = ""
            durationLabel.text = ""
        }
    }

#endif
