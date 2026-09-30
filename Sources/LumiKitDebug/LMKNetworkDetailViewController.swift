//
//  LMKNetworkDetailViewController.swift
//  LumiKit
//
//  Detail view showing full request/response including headers and bodies.
//  DEBUG builds only — zero footprint in release.
//

#if DEBUG && canImport(UIKit)

    import LumiKitCore
    import LumiKitUI
    import SnapKit
    import UIKit
    import UniformTypeIdentifiers

    final class LMKNetworkDetailViewController: LMKCardPageViewController {
        // MARK: - Configurable Strings

        /// Strings of the request detail screen (named apart from the inherited card-page `strings`).
        nonisolated struct DetailStrings: Equatable {
            /// Screen title.
            var title: String
            /// Toast shown after the request text is copied to the pasteboard.
            var copied: String
            /// Accessibility label of the copy item.
            var copyAccessibilityLabel: String

            init(
                title: String = LMKLocalized("networkDetail.title"),
                copied: String = LMKLocalized("networkDetail.copied"),
                copyAccessibilityLabel: String = LMKLocalized("networkDetail.copy.accessibilityLabel")
            ) {
                self.title = title
                self.copied = copied
                self.copyAccessibilityLabel = copyAccessibilityLabel
            }
        }

        /// Process-wide strings, read when the screen is created.
        nonisolated(unsafe) static var detailStrings = DetailStrings()

        // MARK: - Properties

        private let record: LMKNetworkRequestRecord
        private nonisolated static let maxBodyCharacters = 50000
        private static let monospacedPointSize: CGFloat = 11
        /// Copied request text leaves the pasteboard after this long (it may hold tokens).
        private static let pasteboardLifetime: TimeInterval = 60

        private lazy var textView: UITextView = {
            let text = UITextView()
            // Monospaced developer output, scaled with Dynamic Type.
            text.font = UIFontMetrics(forTextStyle: .caption2).scaledFont(for: .monospacedSystemFont(ofSize: Self.monospacedPointSize, weight: .regular))
            text.adjustsFontForContentSizeCategory = true
            text.textColor = LMKColor.textPrimary
            text.backgroundColor = LMKColor.backgroundPrimary
            text.isEditable = false
            text.isSelectable = true
            text.isScrollEnabled = true
            text.textContainerInset = UIEdgeInsets(top: LMKSpacing.medium, left: LMKSpacing.medium, bottom: LMKSpacing.medium, right: LMKSpacing.medium)
            return text
        }()

        // MARK: - Initialization

        init(record: LMKNetworkRequestRecord) {
            self.record = record
            super.init(title: Self.detailStrings.title)
            leadingItem = LMKNavigationBarItem(systemName: "arrow.left")
            trailingItem = LMKNavigationBarItem(systemName: "doc.on.doc", accessibilityLabel: Self.detailStrings.copyAccessibilityLabel) { [weak self] in
                self?.copyTapped()
            }
        }

        // MARK: - Template Overrides

        override func setupContent() {
            contentContainerView.addSubview(textView)
            textView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            textView.text = Self.formatRecord(record)
        }

        override func leadingButtonTapped() {
            navigationController?.popViewController(animated: true)
        }

        private func copyTapped() {
            UIPasteboard.general.setItems(
                [[UTType.plainText.identifier: textView.text ?? ""]],
                options: [.expirationDate: Date().addingTimeInterval(Self.pasteboardLifetime)]
            )
            LMKToast.show(.success, Self.detailStrings.copied, in: self)
        }

        // MARK: - Formatting

        /// The record as sectioned plain text (summary, URL, headers, bodies, error).
        nonisolated static func formatRecord(_ record: LMKNetworkRequestRecord) -> String {
            var sections: [String] = []
            sections.append(section("REQUEST SUMMARY", """
            Method: \(record.displayMethod)
            Status: \(record.displayStatus)
            Duration: \(record.displayDuration)
            Timestamp: \(timestampFormatter.string(from: record.timestamp))
            """))
            sections.append(section("REQUEST URL", record.displayURL))

            let requestHeaders = record.formattedRequestHeaders()
            if !requestHeaders.isEmpty {
                sections.append(section("REQUEST HEADERS", requestHeaders))
            }
            if let body = record.requestBodyText {
                sections.append(section("REQUEST BODY", truncateIfNeeded(body)))
            }
            if let responseHeaders = record.formattedResponseHeaders(), !responseHeaders.isEmpty {
                sections.append(section("RESPONSE HEADERS", responseHeaders))
            }
            if let body = record.responseBodyText {
                sections.append(section("RESPONSE BODY", truncateIfNeeded(body)))
            }
            if let errorDescription = record.errorDescription {
                sections.append(section("ERROR", errorDescription))
            }
            return sections.joined(separator: "\n\n")
        }

        private nonisolated static let rule = String(repeating: "═", count: 39)

        private nonisolated static func section(_ title: String, _ body: String) -> String {
            "\(rule)\n\(title)\n\(rule)\n\(body)"
        }

        private nonisolated static let timestampFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            return formatter
        }()

        private nonisolated static func truncateIfNeeded(_ text: String) -> String {
            guard text.count > maxBodyCharacters else { return text }
            let truncated = String(text.prefix(maxBodyCharacters))
            let remaining = text.count - maxBodyCharacters
            return "\(truncated)\n\n... (truncated \(remaining.formatted()) more characters)"
        }
    }

#endif
