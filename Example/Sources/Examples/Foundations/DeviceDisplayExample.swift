//
//  DeviceDisplayExample.swift
//  LumiKitExample
//
//  Device & Display: LMKDevice tiers, size classes, safe areas, live on resize.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Device & Display

final class DeviceDisplayDetailViewController: DetailViewController {
    private var valueLabels: [String: UILabel] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("LMKDevice")
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "Tiers come from the window's size classes and bounds, never the device model. "
                + "Rotate, resize the window (iPad multitasking, Stage Manager), or fold an iPhone Duo: every row updates live."))
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
            stack.addArrangedSubview(UILabel.lmk_make(.caption, text: line))
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
        let titleLabel = UILabel.lmk_make(.body, text: title, color: LMKColor.textSecondary)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        let valueLabel = UILabel.lmk_make(.bodyMedium, text: "…")
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
        setValue("deviceType", "\(LMKDevice.deviceType)")
        setValue("screenSize", "\(LMKDevice.screenSize)")
        setValue("screenSizeForView", "\(LMKDevice.screenSize(for: view))")
        setValue("hasTopNotch", LMKDevice.hasTopNotch ? "true" : "false")
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
