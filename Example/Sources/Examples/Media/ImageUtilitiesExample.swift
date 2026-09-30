//
//  ImageUtilitiesExample.swift
//  LumiKitExample
//
//  Image Utilities: LMKImage.downsample and sizes; LMKPhotoMetadata read and write.
//

import CoreLocation
import LumiKitCore
import LumiKitPhoto
import LumiKitUI
import SnapKit
import UIKit

// MARK: - Image Utilities

final class ImageUtilitiesDetailViewController: DetailViewController {
    private let resultsStack = UIStackView(lmk_axis: .vertical, spacing: LMKSpacing.small)
    private let thumbnailView = UIImageView()
    private var loadTask: Task<Void, Never>?

    isolated deinit {
        loadTask?.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("LMKImage.downsample")
        stack.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "Decodes straight to the target pixel size through ImageIO thumbnailing, never a full-resolution decode, with the EXIF orientation baked in. "
                + "pixelSize(points:scale:) turns a point size into the pixel cap; the async overload runs on the global executor."
        ))
        thumbnailView.contentMode = .scaleAspectFill
        thumbnailView.clipsToBounds = true
        thumbnailView.lmk_applyCornerRadius(LMKCornerRadius.medium)
        thumbnailView.snp.makeConstraints { make in
            make.width.height.equalTo(120)
        }
        stack.addArrangedSubview(UIStackView(lmk_axis: .horizontal, arrangedSubviews: [thumbnailView, UIView()]))
        stack.addArrangedSubview(resultsStack)

        loadTask = Task { [weak self] in
            await self?.run()
        }
    }

    private func run() async {
        let source = makeSampleJPEG(width: 2400, height: 1600)
        let scale = view.lmk_displayScale
        let cap = LMKImage.pixelSize(points: 120, scale: scale)
        let thumbnail = await LMKImage.downsample(data: source, maxPixelSize: cap, options: LMKImage.DownsampleOptions(scale: scale))
        thumbnailView.image = thumbnail
        let jpeg = LMKImage.downsampledJPEG(data: source, maxPixelSize: 1024)

        let coordinate = CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)
        let stamped = LMKPhotoMetadata.write(date: Date(), coordinate: coordinate, to: source)
        let metadata = stamped.map(LMKPhotoMetadata.read(from:)) ?? .empty

        resultsStack.lmk_removeAllArrangedSubviews()
        let rows: [(String, String)] = [
            ("source bytes", LMKFormat.number(source.count)),
            ("imageSize(of:)", LMKImage.imageSize(of: source).map { "\(Int($0.width)) × \(Int($0.height)) px" } ?? "nil"),
            ("display scale", "\(scale)×"),
            ("pixelSize(points: 120)", "\(Int(cap)) px"),
            ("thumbnail size", thumbnail.map { "\(Int($0.size.width)) × \(Int($0.size.height)) pt @\(Int($0.scale))×" } ?? "nil"),
            ("downsampledJPEG(1024) bytes", jpeg.map { LMKFormat.number($0.count) } ?? "nil"),
            ("metadata.date", metadata.date.map { LMKDateFormat.string($0, date: .medium, time: .short) } ?? "nil"),
            ("metadata.coordinate", metadata.coordinate.map { String(format: "%.4f, %.4f", $0.latitude, $0.longitude) } ?? "nil"),
            ("metadata.pixelSize", metadata.pixelSize.map { "\(Int($0.width)) × \(Int($0.height))" } ?? "nil"),
        ]
        for (api, value) in rows {
            let apiLabel = UILabel.lmk_make(.small, text: api, color: LMKColor.textSecondary)
            let valueLabel = UILabel.lmk_make(.body, text: value)
            valueLabel.textAlignment = .right
            resultsStack.addArrangedSubview(UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.medium, alignment: .firstBaseline, arrangedSubviews: [apiLabel, valueLabel]))
        }
    }

    private func makeSampleJPEG(width: Int, height: Int) -> Data {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let size = CGSize(width: width, height: height)
        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            let colors = [LMKColor.primary.cgColor, LMKColor.info.cgColor] as CFArray
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
                context.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
            }
        }
        return LMKImage.encodeJPEG(image, maxDimension: CGFloat(max(width, height)), quality: 0.9) ?? Data()
    }
}
