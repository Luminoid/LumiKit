//
//  PhotoButtonCopyableLabelExample.swift
//  LumiKitExample
//
//  Photo Button & Copyable Label: LMKPhotoButton photo well, LMKCopyableLabel long-press copy.
//

import LumiKitUI
import UIKit

// MARK: - Photo Button & Copyable Label

final class PhotoButtonCopyableLabelDetailViewController: DetailViewController {
    private lazy var samplePhoto: UIImage = {
        let size = CGSize(width: 320, height: 320)
        return UIGraphicsImageRenderer(size: size).image { context in
            let colors = [LMKColor.primary.cgColor, LMKColor.secondary.cgColor] as CFArray
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
                context.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
            }
        }
    }()

    override func setupStackContent() {
        addSectionHeader("LMKPhotoButton")
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "A photo well: placeholder symbol until image is set, then the image clipped to the shape. Tap to toggle a sample photo here; in an app the tap opens the picker."
        ))
        let hero = LMKPhotoButton(size: 160)
        hero.onTap = { [weak self, weak hero] in
            guard let self, let hero else { return }
            hero.image = hero.image == nil ? samplePhoto : nil
        }
        let rounded = LMKPhotoButton(size: 96, style: LMKPhotoButton.Style(shape: .rounded()))
        rounded.image = samplePhoto
        rounded.onTap = { [weak self, weak rounded] in
            guard let self, let rounded else { return }
            rounded.image = rounded.image == nil ? samplePhoto : nil
        }
        let disabled = LMKPhotoButton(size: 64, style: LMKPhotoButton.Style(placeholderPointSize: LMKLayout.symbolLarge))
        disabled.isEnabled = false
        let row = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.xl, alignment: .center, arrangedSubviews: [hero, rounded, disabled, UIView()])
        stackView.addArrangedSubview(row)

        addDivider()
        addSectionHeader("LMKCopyableLabel")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "Long-press a value to copy it; VoiceOver gets a Copy action. copyTextProvider copies a raw value behind a formatted display."))
        stackView.addArrangedSubview(makeRow("Phone", value: "+1 (555) 010-0100", copyText: "+15550100100"))
        stackView.addArrangedSubview(makeRow("Microchip", value: "985 112 003 456 789", copyText: "985112003456789"))
        stackView.addArrangedSubview(makeRow("Brand", value: "Harbor Pet Foods", copyText: nil))
    }

    private func makeRow(_ title: String, value: String, copyText: String?) -> UIStackView {
        let label = LMKCopyableLabel()
        label.lmk_apply(.body)
        label.lmk_setText(value)
        label.numberOfLines = 0
        if let copyText {
            label.copyTextProvider = { copyText }
        }
        label.onCopy = { [weak self] text in
            guard let self else { return }
            LMKToast.show(.success, "Copied \(text)", in: self)
        }
        return UIStackView(
            lmk_axis: .horizontal,
            spacing: LMKSpacing.medium,
            alignment: .center,
            arrangedSubviews: [UILabel.lmk_make(.captionMedium, text: title, color: LMKColor.textSecondary), UIView(), label]
        )
    }
}
