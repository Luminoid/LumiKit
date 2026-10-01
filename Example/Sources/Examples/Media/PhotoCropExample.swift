//
//  PhotoCropExample.swift
//  LumiKitExample
//
//  Photo Crop: Crop frame with aspect ratios and zoom.
//

import LumiKitPhoto
import LumiKitUI
import SnapKit
import UIKit

// MARK: - Photo Crop

final class PhotoCropDetailViewController: DetailViewController {
    private var sampleImage: UIImage?

    override func setupStackContent() {
        sampleImage = createSampleImage()

        addSectionHeader("Photo Crop")
        stackView.addArrangedSubview(UILabel.lmk_make(.body, text: "Resizable crop frame with aspect ratio presets, pinch-to-zoom, and rule-of-thirds grid."))

        if let sampleImage {
            let preview = UIImageView(image: sampleImage)
            preview.contentMode = .scaleAspectFill
            preview.lmk_applyCornerRadius(LMKCornerRadius.medium)
            preview.snp.makeConstraints { $0.height.equalTo(200) }
            stackView.addArrangedSubview(preview)
        }

        let cropButton = LMKButton(title: "Open Photo Crop", style: .filled(.primary), target: self, action: #selector(openCrop))
        stackView.addArrangedSubview(cropButton)
        let widescreenButton = LMKButton(title: "Open 16:9 Crop (custom style)", style: .outlined(.primary), target: self, action: #selector(openWidescreenCrop))
        stackView.addArrangedSubview(widescreenButton)

        addDivider()
        addSectionHeader("Aspect Ratios")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "The standard six presets; 16:9 and 9:16 are opt-in through aspectRatios."))
        let ratioRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        for ratio in LMKCropAspectRatio.standard {
            let chip = LMKChipView(text: ratio.displayName, style: .outlined)
            ratioRow.addArrangedSubview(chip)
        }
        ratioRow.addArrangedSubview(UIView())
        stackView.addArrangedSubview(makeScrollingRow(ratioRow))

        addDivider()
        addSectionHeader("Features")
        let features = [
            "Drag corners and edges to resize",
            "Pinch to zoom the image",
            "Aspect ratio presets (1:1, 4:3, 3:2, etc.)",
            "Free-form cropping",
            "Rule-of-thirds grid overlay",
            "Command-Return crops, Escape cancels on a hardware keyboard",
        ]
        for feature in features {
            let label = UILabel.lmk_make(.caption, text: "\u{2022} \(feature)")
            stackView.addArrangedSubview(label)
        }
    }

    @objc private func openCrop() {
        guard let sampleImage else { return }
        presentCrop(LMKPhotoCropViewController(image: sampleImage))
    }

    @objc private func openWidescreenCrop() {
        guard let sampleImage else { return }
        let style = LMKPhotoCropViewController.Style(chromeTint: LMKColor.warning, handleSize: 24, gridLineCount: 3)
        presentCrop(LMKPhotoCropViewController(image: sampleImage, aspectRatios: [.sixteenNine, .nineSixteen, .free], initialAspectRatio: .sixteenNine, style: style))
    }

    private func presentCrop(_ cropVC: LMKPhotoCropViewController) {
        cropVC.onCrop = { [weak self, weak cropVC] image in
            cropVC?.dismiss(animated: true) {
                guard let self else { return }
                LMKToast.show(.success, "Image cropped (\(Int(image.size.width))\u{00D7}\(Int(image.size.height)))", in: self)
            }
        }
        cropVC.onCancel = { [weak cropVC] in
            cropVC?.dismiss(animated: true)
        }
        present(cropVC, animated: true)
    }

    private func createSampleImage() -> UIImage? {
        let size = CGSize(width: 600, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let colors = [LMKColor.primary.cgColor, LMKColor.secondary.cgColor]
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1]) else { return }

            ctx.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])

            let config = UIImage.SymbolConfiguration(pointSize: 80, weight: .regular)
            if let symbol = UIImage(systemName: "leaf.fill", withConfiguration: config) {
                let symbolSize = symbol.size
                let origin = CGPoint(
                    x: (size.width - symbolSize.width) / 2,
                    y: (size.height - symbolSize.height) / 2
                )
                symbol.withTintColor(.white.withAlphaComponent(0.8), renderingMode: .alwaysOriginal)
                    .draw(at: origin)
            }
        }
    }
}
