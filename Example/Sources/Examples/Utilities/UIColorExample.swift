//
//  UIColorExample.swift
//  LumiKitExample
//
//  UIColor: Hex initializers, dynamic colors, brightness, contrast.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - UIColor

final class UIColorDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("init(lmk_hex: UInt32)")
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "Integer-literal initializer: no string parsing, type-checker friendly. "
                + "0x000000…0xFFFFFF, optional alpha."))
        let hexLiterals: [(String, UIColor)] = [
            ("0x7C5CFF", UIColor(lmk_hex: 0x7C5CFF)),
            ("0xFF5733", UIColor(lmk_hex: 0xFF5733)),
            ("0x00B894", UIColor(lmk_hex: 0x00B894)),
            ("0xFDCB6E, α=0.5", UIColor(lmk_hex: 0xFDCB6E, alpha: 0.5)),
        ]
        stack.addArrangedSubview(makeSwatchRow(entries: hexLiterals))

        addDivider()
        addSectionHeader("init(lmk_hex: String)")
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "String initializer: accepts \"#RRGGBB\" / \"RRGGBB\" / \"#RRGGBBAA\". "
                + "Returns nil on bad input."))
        let stringHexes = ["#FF5733", "00B894", "#7C5CFF80"]
        let stringEntries: [(String, UIColor)] = stringHexes.compactMap { hex in
            guard let color = UIColor(lmk_hex: hex) else { return nil }
            return (hex, color)
        }
        stack.addArrangedSubview(makeSwatchRow(entries: stringEntries))

        addDivider()
        addSectionHeader("lmk_dynamic(lightHex:darkHex:)")
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "Adaptive color that switches with the interface style. Toggle the system "
                + "appearance (Settings → Developer → Dark Appearance) to see the swap live."))
        let dynamicPairs: [(String, UIColor)] = [
            ("Brand", UIColor.lmk_dynamic(lightHex: 0x694ED9, darkHex: 0x9785F0)),
            ("Surface", UIColor.lmk_dynamic(lightHex: 0xF5F5F7, darkHex: 0x1C1C1E)),
            ("Accent", UIColor.lmk_dynamic(lightHex: 0xFF5733, darkHex: 0xFF8A65)),
        ]
        stack.addArrangedSubview(makeSwatchRow(entries: dynamicPairs))

        addDivider()
        addSectionHeader("lmk_hexString")
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "Round-trips a UIColor back to a hex string. Includes alpha when < 1.0."))
        let roundTripSamples: [UIColor] = [
            .systemRed,
            .systemBlue,
            UIColor(lmk_hex: 0xFDCB6E),
            UIColor(lmk_hex: 0x694ED9).withAlphaComponent(0.5),
        ]
        for color in roundTripSamples {
            stack.addArrangedSubview(makeHexStringRow(color: color))
        }

        addDivider()
        addSectionHeader("lmk_isLight + lmk_contrastingTextColor")
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "lmk_isLight returns true for luminance > 0.5. lmk_contrastingTextColor "
                + "picks black or white accordingly, useful for text on dynamic backgrounds."))
        let isLightSamples: [(String, UIColor)] = [
            ("White (#FFFFFF)", UIColor(lmk_hex: 0xFFFFFF)),
            ("Pale yellow (#FDCB6E)", UIColor(lmk_hex: 0xFDCB6E)),
            ("Brand violet (#694ED9)", UIColor(lmk_hex: 0x694ED9)),
            ("Black (#000000)", UIColor(lmk_hex: 0x000000)),
        ]
        for (name, color) in isLightSamples {
            stack.addArrangedSubview(makeContrastRow(name: name, color: color))
        }

        addDivider()
        addSectionHeader("lmk_adjustedBrightness(by:)")
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "Multiplies HSB brightness by a factor. > 1.0 lightens, < 1.0 darkens, "
                + "clamped to 0…1."))
        let brightnessBase = UIColor(lmk_hex: 0x4A7FE0)
        let brightnessFactors: [CGFloat] = [0.5, 0.75, 1.0, 1.25, 1.5]
        let brightnessEntries: [(String, UIColor)] = brightnessFactors.map { factor in
            (String(format: "%.2fx", Double(factor)), brightnessBase.lmk_adjustedBrightness(by: factor))
        }
        stack.addArrangedSubview(makeSwatchRow(entries: brightnessEntries))
    }

    // MARK: - Row builders

    private func makeSwatchRow(entries: [(String, UIColor)]) -> UIView {
        let row = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        row.distribution = .fillEqually
        for (label, color) in entries {
            row.addArrangedSubview(makeSwatch(color: color, caption: label))
        }
        return row
    }

    private func makeSwatch(color: UIColor, caption: String) -> UIView {
        let column = UIStackView(lmk_axis: .vertical, spacing: LMKSpacing.xs, alignment: .center)
        let swatch = UIView()
        swatch.backgroundColor = color
        swatch.lmk_applyCornerRadius(LMKCornerRadius.small)
        swatch.snp.makeConstraints { make in
            make.height.equalTo(60)
            make.width.greaterThanOrEqualTo(60)
        }
        let label = UILabel.lmk_make(.small, text: caption)
        label.textAlignment = .center
        label.numberOfLines = 2
        column.addArrangedSubview(swatch)
        column.addArrangedSubview(label)
        return column
    }

    private func makeHexStringRow(color: UIColor) -> UIView {
        let swatch = UIView()
        swatch.backgroundColor = color
        swatch.lmk_applyCornerRadius(LMKCornerRadius.small)
        swatch.snp.makeConstraints { make in
            make.width.equalTo(44)
            make.height.equalTo(28)
        }
        let label = UILabel.lmk_make(.body, text: "#\(color.lmk_hexString)")
        return UIStackView(
            lmk_axis: .horizontal,
            spacing: LMKSpacing.medium,
            alignment: .center,
            arrangedSubviews: [swatch, label, UIView()]
        )
    }

    private func makeContrastRow(name: String, color: UIColor) -> UIView {
        let container = UIView()
        container.backgroundColor = color
        container.lmk_applyCornerRadius(LMKCornerRadius.small)
        // A floor, not a fixed height: the body line is 24pt at the default size and grows with Dynamic Type.
        container.snp.makeConstraints { $0.height.greaterThanOrEqualTo(LMKLayout.minimumTouchTarget) }

        let label = UILabel.lmk_make(.body, text: "\(name): \(color.lmk_isLight ? "light" : "dark")")
        label.textColor = color.lmk_contrastingTextColor
        container.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: LMKSpacing.small, left: LMKSpacing.medium, bottom: LMKSpacing.small, right: LMKSpacing.medium))
        }
        return container
    }
}
