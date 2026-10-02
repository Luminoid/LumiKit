//
//  LMKNetworkDetailViewController.swift
//  LumiKit
//
//  Detail view showing full request/response including headers and bodies.
//  Debug builds only (`LMK_ENABLE_NETWORK_LOGGING`) — zero footprint in release.
//

#if LMK_ENABLE_NETWORK_LOGGING && canImport(UIKit)

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
            /// Section headings of the record dump.
            var summarySection: String
            var urlSection: String
            var requestHeadersSection: String
            var requestBodySection: String
            var responseHeadersSection: String
            var responseBodySection: String
            var errorSection: String
            /// Summary lines; `%@` is the value.
            var methodFormat: String
            var statusFormat: String
            var durationFormat: String
            var timestampFormat: String
            /// Note under a body the screen cut; `%@` is the count of characters not shown.
            var truncatedFormat: String
            /// Note under a body the logger cut at capture; `%@` is the size kept.
            var captureLimitFormat: String

            init(
                title: String = LMKLocalized("networkDetail.title"),
                copied: String = LMKLocalized("networkDetail.copied"),
                copyAccessibilityLabel: String = LMKLocalized("networkDetail.copy.accessibilityLabel"),
                summarySection: String = LMKLocalized("networkDetail.section.summary"),
                urlSection: String = LMKLocalized("networkDetail.section.url"),
                requestHeadersSection: String = LMKLocalized("networkDetail.section.requestHeaders"),
                requestBodySection: String = LMKLocalized("networkDetail.section.requestBody"),
                responseHeadersSection: String = LMKLocalized("networkDetail.section.responseHeaders"),
                responseBodySection: String = LMKLocalized("networkDetail.section.responseBody"),
                errorSection: String = LMKLocalized("networkDetail.section.error"),
                methodFormat: String = LMKLocalized("networkDetail.summary.method"),
                statusFormat: String = LMKLocalized("networkDetail.summary.status"),
                durationFormat: String = LMKLocalized("networkDetail.summary.duration"),
                timestampFormat: String = LMKLocalized("networkDetail.summary.timestamp"),
                truncatedFormat: String = LMKLocalized("networkDetail.truncated"),
                captureLimitFormat: String = LMKLocalized("networkDetail.captureLimit")
            ) {
                self.title = title
                self.copied = copied
                self.copyAccessibilityLabel = copyAccessibilityLabel
                self.summarySection = summarySection
                self.urlSection = urlSection
                self.requestHeadersSection = requestHeadersSection
                self.requestBodySection = requestBodySection
                self.responseHeadersSection = responseHeadersSection
                self.responseBodySection = responseBodySection
                self.errorSection = errorSection
                self.methodFormat = methodFormat
                self.statusFormat = statusFormat
                self.durationFormat = durationFormat
                self.timestampFormat = timestampFormat
                self.truncatedFormat = truncatedFormat
                self.captureLimitFormat = captureLimitFormat
            }
        }

        /// Process-wide strings, read when the screen is created.
        nonisolated(unsafe) static var detailStrings = DetailStrings()

        // MARK: - Properties

        /// The record shown; refreshed from the store when its response or error lands.
        private(set) var record: LMKNetworkRequestRecord
        private nonisolated static let maxBodyCharacters = 50000
        private static let monospacedPointSize: CGFloat = 11
        /// Copied request text leaves the pasteboard after this long (it may hold tokens).
        private static let pasteboardLifetime: TimeInterval = 60
        /// Re-reads the record once per burst of store changes; released with the screen.
        private var changeObserver: LMKNetworkLogger.ChangeObserver?

        private(set) lazy var textView: UITextView = {
            let text = UITextView()
            // Monospaced developer output, scaled with Dynamic Type.
            text.font = UIFontMetrics(forTextStyle: .caption2).scaledFont(for: .monospacedSystemFont(ofSize: Self.monospacedPointSize, weight: .regular))
            text.adjustsFontForContentSizeCategory = true
            text.textColor = LMKColor.textPrimary
            text.backgroundColor = LMKColor.backgroundPrimary
            text.isEditable = false
            text.isSelectable = true
            text.isScrollEnabled = true
            return text
        }()

        // MARK: - Initialization

        init(record: LMKNetworkRequestRecord) {
            self.record = record
            super.init(title: Self.detailStrings.title)
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
            changeObserver = LMKNetworkLogger.ChangeObserver { [weak self] in
                self?.refreshRecord()
            }
        }

        private func copyTapped() {
            UIPasteboard.general.setItems(
                [[UTType.plainText.identifier: textView.text ?? ""]],
                options: [.expirationDate: Date().addingTimeInterval(Self.pasteboardLifetime)]
            )
            LMKToast.show(.success, Self.detailStrings.copied, in: self)
        }

        // MARK: - Theme

        override func applyTheme(_ theme: LMKTheme) {
            let inset = theme.spacing.medium
            textView.textContainerInset = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
            super.applyTheme(theme)
        }

        // MARK: - Data

        /// Re-reads the record from the store; a pending row that has since completed re-renders.
        func refreshRecord() {
            guard let latest = LMKNetworkLogger.record(id: record.id), !latest.hasSameOutcome(as: record) else { return }
            record = latest
            textView.text = Self.formatRecord(latest)
        }

        // MARK: - Formatting

        /// The record as sectioned plain text (summary, URL, headers, bodies, error).
        nonisolated static func formatRecord(_ record: LMKNetworkRequestRecord, strings: DetailStrings = detailStrings) -> String {
            var sections: [String] = []
            let summary = [
                String(format: strings.methodFormat, record.displayMethod),
                String(format: strings.statusFormat, record.displayStatus),
                String(format: strings.durationFormat, record.displayDuration),
                String(format: strings.timestampFormat, timestampFormatter.string(from: record.timestamp)),
            ].joined(separator: "\n")
            sections.append(section(strings.summarySection, summary))
            sections.append(section(strings.urlSection, record.displayURL))

            let requestHeaders = record.formattedRequestHeaders()
            if !requestHeaders.isEmpty {
                sections.append(section(strings.requestHeadersSection, requestHeaders))
            }
            if let body = record.requestBodyText {
                sections.append(section(strings.requestBodySection, bodyText(body, capturedBytes: record.request.body?.count, isTruncated: record.request.isBodyTruncated, strings: strings)))
            }
            if let responseHeaders = record.formattedResponseHeaders(), !responseHeaders.isEmpty {
                sections.append(section(strings.responseHeadersSection, responseHeaders))
            }
            if let body = record.responseBodyText {
                sections.append(section(
                    strings.responseBodySection,
                    bodyText(body, capturedBytes: record.response?.body?.count, isTruncated: record.response?.isBodyTruncated ?? false, strings: strings)
                ))
            }
            if let errorDescription = record.errorDescription {
                sections.append(section(strings.errorSection, errorDescription))
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

        /// The body cut to `maxBodyCharacters`, with a note for a cut made here or at capture.
        private nonisolated static func bodyText(_ text: String, capturedBytes: Int?, isTruncated: Bool, strings: DetailStrings) -> String {
            var shown = text
            var notes: [String] = []
            if text.count > maxBodyCharacters {
                shown = String(text.prefix(maxBodyCharacters))
                notes.append(String(format: strings.truncatedFormat, LMKFormat.number(text.count - maxBodyCharacters)))
            }
            if isTruncated {
                let kept = ByteCountFormatter.string(fromByteCount: Int64(capturedBytes ?? 0), countStyle: .binary)
                notes.append(String(format: strings.captureLimitFormat, kept))
            }
            guard !notes.isEmpty else { return shown }
            return ([shown] + notes).joined(separator: "\n\n")
        }
    }

#endif
