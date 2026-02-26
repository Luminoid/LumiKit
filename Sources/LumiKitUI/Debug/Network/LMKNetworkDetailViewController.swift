//
//  LMKNetworkDetailViewController.swift
//  LumiKit
//
//  Detail view showing full request/response including headers and bodies.
//  DEBUG builds only — zero footprint in release.
//

#if DEBUG

    import LumiKitCore
    import SnapKit
    import UIKit

    public final class LMKNetworkDetailViewController: LMKCardPageController {
        // MARK: - Properties

        private let record: LMKNetworkRequestRecord
        private let maxBodyCharacters = 50_000 // Increased limit with better rendering

        private lazy var textView: UITextView = {
            let text = UITextView()
            text.font = UIFont.monospacedSystemFont(ofSize: 11, weight: .regular)
            text.textColor = LMKColor.textPrimary
            text.backgroundColor = LMKColor.backgroundPrimary
            text.isEditable = false
            text.isSelectable = true
            text.isScrollEnabled = true // UITextView handles scrolling efficiently
            text.textContainerInset = UIEdgeInsets(
                top: LMKSpacing.medium,
                left: LMKSpacing.medium,
                bottom: LMKSpacing.medium,
                right: LMKSpacing.medium
            )
            return text
        }()

        // MARK: - Initialization

        public init(record: LMKNetworkRequestRecord) {
            self.record = record
            super.init(title: "Request Detail")
        }

        // MARK: - Configuration

        override public var headerHeight: CGFloat { LMKCardPageLayout.headerHeight }
        override public var showsLeadingButton: Bool { true }
        override public var leadingButtonSymbol: String { "arrow.left" }

        // MARK: - Template Overrides

        override public func setupContent() {
            contentContainerView.addSubview(textView)
            textView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            // Set text - UITextView handles large content efficiently with its own scrolling
            textView.text = formatRecord()
        }

        override public func leadingButtonTapped() {
            navigationController?.popViewController(animated: true)
        }

        // MARK: - Formatting

        private func formatRecord() -> String {
            var sections: [String] = []

            // Summary
            sections.append("""
            ═══════════════════════════════════════
            REQUEST SUMMARY
            ═══════════════════════════════════════
            Method: \(record.displayMethod)
            Status: \(record.displayStatus)
            Duration: \(record.displayDuration)
            Timestamp: \(formatTimestamp(record.timestamp))
            """)

            // Request URL
            sections.append("""

            ═══════════════════════════════════════
            REQUEST URL
            ═══════════════════════════════════════
            \(record.displayURL)
            """)

            // Request Headers
            let requestHeaders = record.formattedRequestHeaders()
            if !requestHeaders.isEmpty {
                sections.append("""

                ═══════════════════════════════════════
                REQUEST HEADERS
                ═══════════════════════════════════════
                \(requestHeaders)
                """)
            }

            // Request Body
            if let body = record.requestBodyText {
                let truncatedBody = truncateIfNeeded(body)
                sections.append("""

                ═══════════════════════════════════════
                REQUEST BODY
                ═══════════════════════════════════════
                \(truncatedBody)
                """)
            }

            // Response Headers
            if let responseHeaders = record.formattedResponseHeaders(), !responseHeaders.isEmpty {
                sections.append("""

                ═══════════════════════════════════════
                RESPONSE HEADERS
                ═══════════════════════════════════════
                \(responseHeaders)
                """)
            }

            // Response Body
            if let body = record.responseBodyText {
                let truncatedBody = truncateIfNeeded(body)
                sections.append("""

                ═══════════════════════════════════════
                RESPONSE BODY
                ═══════════════════════════════════════
                \(truncatedBody)
                """)
            }

            // Error
            if let error = record.error {
                sections.append("""

                ═══════════════════════════════════════
                ERROR
                ═══════════════════════════════════════
                \(error.localizedDescription)
                """)
            }

            return sections.joined(separator: "\n")
        }

        private func formatTimestamp(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            return formatter.string(from: date)
        }

        private func truncateIfNeeded(_ text: String) -> String {
            guard text.count > maxBodyCharacters else { return text }
            let truncated = String(text.prefix(maxBodyCharacters))
            let remaining = text.count - maxBodyCharacters
            return "\(truncated)\n\n... (truncated \(remaining.formatted()) more characters)"
        }
    }

#endif
