//
//  DesignSystemExamples.swift
//  LumiKitExample
//
//  Typography, color token, and markdown rendering examples.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Typography

final class TypographyDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Headings")
        stack.addArrangedSubview(LMKLabelFactory.heading(text: "Heading 1", level: 1))
        stack.addArrangedSubview(LMKLabelFactory.heading(text: "Heading 2", level: 2))
        stack.addArrangedSubview(LMKLabelFactory.heading(text: "Heading 3", level: 3))
        stack.addArrangedSubview(LMKLabelFactory.heading(text: "Heading 4", level: 4))

        addDivider()
        addSectionHeader("Body Styles")
        stack.addArrangedSubview(LMKLabelFactory.body(text: "Body — the quick brown fox jumps over the lazy dog. This is the default paragraph style used for content."))
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Caption — used for secondary information and metadata"))
        stack.addArrangedSubview(LMKLabelFactory.small(text: "Small — fine print and tertiary details"))

        addDivider()
        addSectionHeader("Special")
        stack.addArrangedSubview(LMKLabelFactory.scientificName(text: "Monstera deliciosa"))
        stack.addArrangedSubview(LMKLabelFactory.scientificName(text: "Epipremnum aureum"))
    }
}

// MARK: - Colors

final class ColorsDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addColorRow("Primary", [
            ("Primary", LMKColor.primary),
            ("Secondary", LMKColor.secondary),
        ])

        addDivider()
        addColorRow("Semantic", [
            ("Success", LMKColor.success),
            ("Warning", LMKColor.warning),
            ("Error", LMKColor.error),
            ("Info", LMKColor.info),
        ])

        addDivider()
        addColorRow("Text", [
            ("Primary", LMKColor.textPrimary),
            ("Secondary", LMKColor.textSecondary),
            ("Tertiary", LMKColor.textTertiary),
        ])

        addDivider()
        addColorRow("Backgrounds", [
            ("Primary", LMKColor.backgroundPrimary),
            ("Secondary", LMKColor.backgroundSecondary),
            ("Tertiary", LMKColor.backgroundTertiary),
        ])
    }

    private func addColorRow(_ title: String, _ colors: [(String, UIColor)]) {
        addSectionHeader(title)
        let row = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        row.distribution = .fillEqually

        for (name, color) in colors {
            let swatch = UIView()
            swatch.backgroundColor = color
            swatch.layer.cornerRadius = LMKCornerRadius.small
            swatch.layer.borderWidth = 0.5
            swatch.layer.borderColor = LMKColor.divider.cgColor

            let label = LMKLabelFactory.small(text: name)
            label.textAlignment = .center

            let col = UIStackView(lmk_axis: .vertical, spacing: LMKSpacing.xs)
            col.addArrangedSubview(swatch)
            col.addArrangedSubview(label)
            swatch.snp.makeConstraints { $0.height.equalTo(52) }
            row.addArrangedSubview(col)
        }
        stack.addArrangedSubview(row)
    }
}

// MARK: - Markdown

final class MarkdownDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Bold & Italic")
        addMarkdownLabel("This is **bold**, this is *italic*, and this is ***both***.")

        addDivider()
        addSectionHeader("Strikethrough")
        addMarkdownLabel("This is ~~removed~~ updated text.")

        addDivider()
        addSectionHeader("Links (UITextView)")
        addMarkdownTextView("Visit [Apple](https://apple.com) and [GitHub](https://github.com) — links are tappable in UITextView.")

        addDivider()
        addSectionHeader("Inline Code")
        addMarkdownLabel("Use `LMKMarkdownRenderer.render()` to convert markdown to attributed strings.")

        addDivider()
        addSectionHeader("Mixed Formatting")
        addMarkdownLabel("**Important**: The `config` value *must* be set **before** calling `setup()`. See the ~~old~~ new docs.")

        addDivider()
        addSectionHeader("Custom Font — H3")
        addMarkdownLabel(
            "Heading with **emphasis** rendered at a larger size.",
            font: LMKTypography.h3
        )

        addDivider()
        addSectionHeader("Custom Font — Caption")
        addMarkdownLabel(
            "Small print with *italic* and **bold** at caption size.",
            font: LMKTypography.caption
        )

        addDivider()
        addSectionHeader("Custom Color — Success")
        addMarkdownLabel(
            "Operation **completed** successfully. All *checks* passed.",
            color: LMKColor.success
        )

        addDivider()
        addSectionHeader("Custom Color — Warning")
        addMarkdownLabel(
            "**Warning**: This action is *irreversible*. Proceed with caution.",
            color: LMKColor.warning
        )

        addDivider()
        addSectionHeader("Custom Color — Error")
        addMarkdownLabel(
            "**Error**: Failed to connect. Check your *network settings*.",
            color: LMKColor.error
        )

        addDivider()
        addSectionHeader("Font + Color Combined")
        addMarkdownLabel(
            "**Tip**: Use `LMKColor.info` with `LMKTypography.caption` for *subtle hints*.",
            font: LMKTypography.caption,
            color: LMKColor.info
        )

        addDivider()
        addSectionHeader("Multi-Line Paragraph")
        addMarkdownLabel("""
        **SwiftData** makes it easy to persist data using *declarative models*. \
        Define your schema with `@Model`, add relationships with `@Relationship`, \
        and query with `@Query`. No more ~~Core Data boilerplate~~ manual migrations.
        """)

        addDivider()
        addSectionHeader("Plain Text Fallback")
        addMarkdownLabel("No markdown here — just plain text with the base font and color applied.")

        addDivider()
        addSectionHeader("Full Markdown — Report")
        addFullMarkdownTextView("""
        ## Q1 Performance Review

        **Period:** January – March 2026
        **Author:** Engineering Team

        ---

        ### 1. Summary

        Overall system reliability improved to **99.7% uptime**, up from *98.9%* last quarter. Two major incidents occurred, both resolved within SLA.

        ### 2. Key Metrics

        *   **API Latency (p95):** 142ms → 98ms
        *   **Error Rate:** 0.8% → 0.3%
        *   **Deploy Frequency:** 2x/week → daily

        ### 3. Incidents

        1.  **Database failover (Jan 15):** Primary replica went unresponsive during peak traffic.
            *   Root cause: connection pool exhaustion
            *   Resolution: increased pool size, added circuit breaker
        2.  **Auth service outage (Feb 22):** Token refresh loop caused cascading failures.
            *   Root cause: clock skew between nodes
            *   Resolution: switched to *monotonic timestamps*

        ### 4. Next Steps

        - Migrate to **regional failover** by end of Q2
        - Add *structured logging* across all services
        - Complete load testing for the new payment flow
        - Hire two additional SREs

        ### 5. Conclusion

        The team made **significant progress** on reliability and performance. The remaining gaps in observability and regional redundancy are the top priorities for Q2.
        """)

        addDivider()
        addSectionHeader("Full Markdown — Code & Tables")
        addFullMarkdownTextView("""
        Here's how to **debounce** a Swift `Task` so only the *final* call runs:

        ```swift
        func schedule() {
            task?.cancel()
            task = Task {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                await refresh()
            }
        }
        ```

        The three rate-limiting strategies at a glance:

        | Strategy  | Latency | Use case  |
        |-----------|---------|-----------|
        | Debounce  | Medium  | Typeahead |
        | Throttle  | Low     | Scrolling |
        | Immediate | None    | Live taps |

        Columns are aligned with tab stops, so even CJK and uneven cells stay lined up. Fenced \
        code blocks and GFM tables render in a **monospaced** font, so an AI chat response that \
        emits them stays readable instead of collapsing to a run-on line.
        """)
    }

    private func addMarkdownLabel(
        _ markdown: String,
        font: UIFont = LMKTypography.body,
        color: UIColor = LMKColor.textPrimary
    ) {
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = LMKMarkdownRenderer.render(markdown, font: font, color: color)
        stack.addArrangedSubview(label)
    }

    private func addMarkdownTextView(_ markdown: String) {
        stack.addArrangedSubview(LMKMarkdownRenderer.makeInlineTextView(markdown: markdown))
    }

    private func addFullMarkdownTextView(_ markdown: String) {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(
            top: LMKSpacing.small,
            left: LMKSpacing.small,
            bottom: LMKSpacing.small,
            right: LMKSpacing.small
        )
        textView.attributedText = LMKMarkdownRenderer.renderFull(markdown)
        stack.addArrangedSubview(textView)
    }
}

// MARK: - Device & Display

final class DeviceDisplayDetailViewController: DetailViewController {
    private var valueLabels: [String: UILabel] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("LMKDeviceHelper")
        stack.addArrangedSubview(LMKLabelFactory.caption(
            text: "Tiers come from the window's size classes and bounds, never the device model. "
                + "Rotate, resize the window (iPad multitasking, Stage Manager), or fold an iPhone Duo: every row updates live."
        ))
        addInfoRow(key: "deviceType", title: "deviceType")
        addInfoRow(key: "screenSize", title: "screenSize (key window)")
        addInfoRow(key: "screenSizeForView", title: "screenSize(for: view)")
        addInfoRow(key: "hasTopNotch", title: "hasTopNotch")

        addDivider()
        addSectionHeader("Canvas")
        addInfoRow(key: "windowSize", title: "Window bounds")
        addInfoRow(key: "viewSize", title: "Root view bounds")
        addInfoRow(key: "sizeClasses", title: "Size classes (h × v)")
        addInfoRow(key: "safeArea", title: "Safe area (top left bottom right)")
        addInfoRow(key: "displayScale", title: "displayScale trait")
        addInfoRow(key: "hairline", title: "LMKLayout.hairline(for: view)")
        addInfoRow(key: "cardPadding", title: "LMKSpacing.cardPadding")
        addInfoRow(key: "cellPadding", title: "LMKSpacing.cellPaddingVertical")

        addDivider()
        addSectionHeader("Tiers by portrait width")
        let tierLines = [
            "compact ≤ 375: iPhone SE, 13 mini, XS / 11 Pro, iPad Slide Over",
            "regular ≤ 402: iPhone 16e / 17e, 15 / 16, 16 Pro / 17 / 17 Pro / 18 Pro",
            "large > 402: iPhone 11, Air, Plus, Pro Max, iPhone Duo cover display",
            "extraLarge: regular × regular (iPad, Mac, iPhone Duo inner display)",
        ]
        for line in tierLines {
            stack.addArrangedSubview(LMKLabelFactory.caption(text: line))
        }
        refreshValues()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        refreshValues()
    }

    // MARK: - Rows

    private func addInfoRow(key: String, title: String) {
        let row = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        row.alignment = .firstBaseline
        let titleLabel = LMKLabelFactory.body(text: title, color: LMKColor.textSecondary)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let valueLabel = LMKLabelFactory.bodyMedium(text: "…")
        valueLabel.textAlignment = .right
        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        row.addArrangedSubview(titleLabel)
        row.addArrangedSubview(valueLabel)
        stack.addArrangedSubview(row)
        valueLabels[key] = valueLabel
    }

    private func refreshValues() {
        let traits = view.traitCollection
        let insets = view.safeAreaInsets
        setValue("deviceType", "\(LMKDeviceHelper.deviceType)")
        setValue("screenSize", "\(LMKDeviceHelper.screenSize)")
        setValue("screenSizeForView", "\(LMKDeviceHelper.screenSize(for: view))")
        setValue("hasTopNotch", LMKDeviceHelper.hasTopNotch ? "true" : "false")
        setValue("windowSize", Self.format(view.window?.bounds.size ?? .zero))
        setValue("viewSize", Self.format(view.bounds.size))
        setValue("sizeClasses", "\(Self.name(traits.horizontalSizeClass)) × \(Self.name(traits.verticalSizeClass))")
        setValue("safeArea", String(format: "%.0f  %.0f  %.0f  %.0f", insets.top, insets.left, insets.bottom, insets.right))
        setValue("displayScale", String(format: "%.1fx", traits.displayScale))
        setValue("hairline", String(format: "%.3fpt", LMKLayout.hairline(for: view)))
        setValue("cardPadding", String(format: "%.0fpt", LMKSpacing.cardPadding))
        setValue("cellPadding", String(format: "%.0fpt", LMKSpacing.cellPaddingVertical))
    }

    private func setValue(_ key: String, _ value: String) {
        valueLabels[key]?.text = value
    }

    private static func format(_ size: CGSize) -> String {
        String(format: "%.0f × %.0f pt", size.width, size.height)
    }

    private static func name(_ sizeClass: UIUserInterfaceSizeClass) -> String {
        switch sizeClass {
        case .compact: "compact"
        case .regular: "regular"
        default: "unspecified"
        }
    }
}
