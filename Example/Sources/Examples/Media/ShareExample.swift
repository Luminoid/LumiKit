//
//  ShareExample.swift
//  LumiKitExample
//
//  Share: Share preview sheet and LMKShare.
//

import LumiKitPhoto
import LumiKitUI
import SnapKit
import UIKit

// MARK: - Share Preview

final class ShareDetailViewController: DetailViewController {
    private var sampleImage: UIImage?

    override func setupStackContent() {
        sampleImage = createSampleImage()

        addSectionHeader("LMKSharePreviewViewController")
        stackView.addArrangedSubview(UILabel.lmk_make(
            .body,
            text: "Image preview sheet with Share and Save to Photos actions (LMKButtons styled from theme.sharePreview). Saving needs NSPhotoLibraryAddUsageDescription in the host's Info.plist."
        ))

        if let sampleImage {
            let preview = UIImageView(image: sampleImage)
            preview.contentMode = .scaleAspectFit
            preview.lmk_applyCornerRadius(LMKCornerRadius.medium)
            preview.snp.makeConstraints { $0.height.equalTo(200) }
            stackView.addArrangedSubview(preview)
        }

        let previewButton = LMKButton(title: "Show Share Preview", style: .filled(.primary), target: self, action: #selector(showSharePreview))
        stackView.addArrangedSubview(previewButton)

        addDivider()
        addSectionHeader("LMKShare")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "Direct share sheet for images and files with iPad popover support."))

        let shareImageButton = LMKButton(title: "Share Image Directly", style: .outlined(.secondary), target: self, action: #selector(shareImageDirectly(_:)))
        stackView.addArrangedSubview(shareImageButton)
    }

    @objc private func showSharePreview() {
        guard let sampleImage else { return }
        let previewVC = LMKSharePreviewViewController(image: sampleImage, detents: [.medium(), .large()])
        previewVC.onShare = { [weak self] activity in
            guard let self else { return }
            LMKToast.show(.success, "Shared via \(activity?.rawValue ?? "unknown")", in: self)
        }
        previewVC.onSave = { [weak self] in
            guard let self else { return }
            LMKToast.show(.success, "Saved to Photos", in: self)
        }
        previewVC.onFailure = { [weak self] failure in
            guard let self else { return }
            switch failure {
            case .share: LMKToast.show(.error, "Share failed", in: self)
            case .save: LMKToast.show(.error, "Failed to save image", in: self)
            case .photoLibraryAccessDenied: LMKToast.show(.warning, "Photo library access denied", in: self)
            }
        }
        present(previewVC, animated: true)
    }

    /// Takes the tapped button so the share sheet anchors to it as a popover on iPad and Mac.
    @objc private func shareImageDirectly(_ sender: UIView) {
        guard let sampleImage else { return }
        LMKShare.image(sampleImage, from: self, sourceView: sender) { [weak self] result in
            guard let self else { return }
            switch result {
            case let .completed(activityType):
                LMKToast.show(.success, "Shared via \(activityType?.rawValue ?? "unknown")", in: self)
            case .failed:
                LMKToast.show(.error, "Share failed", in: self)
            case .cancelled:
                break
            }
        }
    }

    private func createSampleImage() -> UIImage? {
        let size = CGSize(width: 400, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let colors = [LMKColor.info.cgColor, LMKColor.primary.cgColor]
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1]) else { return }
            ctx.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])

            let config = UIImage.SymbolConfiguration(pointSize: 64, weight: .regular)
            if let symbol = UIImage(systemName: "square.and.arrow.up", withConfiguration: config) {
                let symbolSize = symbol.size
                let origin = CGPoint(x: (size.width - symbolSize.width) / 2, y: (size.height - symbolSize.height) / 2)
                symbol.withTintColor(.white.withAlphaComponent(0.8), renderingMode: .alwaysOriginal).draw(at: origin)
            }
        }
    }
}
