//
//  DominantColorExample.swift
//  LumiKitExample
//
//  Dominant Color: Histogram color extraction, with a subject-lifted mode.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Dominant Color

final class DominantColorDetailViewController: DetailViewController {
    override func setupStackContent() {
        // Section 1: all three strategies side by side, across subject types
        addSectionHeader("Strategy comparison")
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "Same image, three strategies. "
                + "Modal = densest bucket (subject identity). "
                + "Average = pixel mean (overall vibe, muddy for subjects). "
                + "Vibrant = most saturated bucket (accent color).",
            color: LMKColor.textSecondary
        ))

        let strategySamples: [(label: String, image: UIImage, ignoringTransparent: Bool)] = [
            (
                "Solid red",
                Self.makeSolidImage(color: .systemRed),
                false
            ),
            (
                "Sunset gradient",
                Self.makeGradientImage(colors: [.systemOrange, .systemPink, .systemPurple]),
                false
            ),
            (
                "Black subject on green (no muddy grey)",
                Self.makeSubjectImage(background: .systemGreen, subject: .black),
                false
            ),
            (
                "Yellow subject on red background",
                Self.makeSubjectImage(background: .systemRed, subject: .systemYellow),
                false
            ),
            (
                "Faux fur on neutral background",
                Self.makeFauxFurImage(furColor: UIColor(red: 0.42, green: 0.27, blue: 0.18, alpha: 1.0), background: .systemGray5),
                false
            ),
            (
                "Grey scene with red accent",
                Self.makeAccentImage(background: .systemGray3, accent: .systemRed, accentFraction: 0.18),
                false
            ),
            (
                "4-color quadrant",
                Self.makeQuadrantImage(colors: [.systemRed, .systemGreen, .systemBlue, .systemYellow]),
                false
            ),
            (
                "Lifted blue subject (transparent bg)",
                Self.makeLiftedSubjectImage(subject: .systemBlue),
                true
            ),
        ]
        for sample in strategySamples {
            stackView.addArrangedSubview(makeAllStrategiesRow(for: sample))
        }

        // Section 2: palette extraction
        addDivider()
        addSectionHeader("Palette (top-N buckets)")
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "Top-5 densest histogram buckets, sorted by frequency. May return fewer for low-variation images.",
            color: LMKColor.textSecondary
        ))

        let paletteSamples: [(label: String, image: UIImage)] = [
            (
                "Sunset gradient",
                Self.makeGradientImage(colors: [.systemYellow, .systemOrange, .systemPink, .systemPurple])
            ),
            (
                "4-color quadrant",
                Self.makeQuadrantImage(colors: [.systemRed, .systemGreen, .systemBlue, .systemYellow])
            ),
            (
                "Symbol-soup canvas",
                Self.makeSymbolSoupImage(
                    background: UIColor(red: 0.95, green: 0.93, blue: 0.86, alpha: 1.0),
                    symbols: [
                        ("heart.fill", .systemRed),
                        ("star.fill", .systemYellow),
                        ("leaf.fill", .systemGreen),
                        ("drop.fill", .systemBlue),
                        ("flame.fill", .systemOrange),
                    ]
                )
            ),
            (
                "Solid (returns one)",
                Self.makeSolidImage(color: .systemTeal)
            ),
        ]
        for sample in paletteSamples {
            stackView.addArrangedSubview(makePaletteRow(for: sample))
        }
    }

    private func makeAllStrategiesRow(for sample: (label: String, image: UIImage, ignoringTransparent: Bool)) -> UIView {
        let imageView = makeThumbnail(image: sample.image)

        let titleLabel = UILabel.lmk_make(.bodyMedium, text: sample.label)

        let strategies: [(name: String, strategy: LMKImage.DominantColorStrategy)] = [
            ("modal", .modal),
            ("average", .average),
            ("vibrant", .vibrant),
        ]
        let swatchesStack = UIStackView()
        swatchesStack.axis = .horizontal
        swatchesStack.spacing = LMKSpacing.small
        swatchesStack.distribution = .fillEqually
        for entry in strategies {
            let color = LMKImage.dominantColor(
                from: sample.image,
                ignoringTransparent: sample.ignoringTransparent,
                strategy: entry.strategy
            )
            swatchesStack.addArrangedSubview(makeLabeledSwatch(label: entry.name, color: color))
        }

        let textStack = UIStackView(arrangedSubviews: [titleLabel, swatchesStack])
        textStack.axis = .vertical
        textStack.spacing = LMKSpacing.xs

        let row = UIStackView(arrangedSubviews: [imageView, textStack])
        row.axis = .horizontal
        row.spacing = LMKSpacing.medium
        row.alignment = .center
        return row
    }

    private func makeLabeledSwatch(label: String, color: UIColor?) -> UIView {
        let swatch = makeSwatch(color: color, side: 28)

        // A name and a hex code under a swatch column: one line each, shrinking rather than
        // clipping at accessibility sizes.
        let labelView = UILabel.lmk_make(.captionMedium, text: label, color: LMKColor.textSecondary, numberOfLines: 1)
        labelView.adjustsFontSizeToFitWidth = true
        labelView.minimumScaleFactor = 0.6
        let hexLabel = UILabel.lmk_make(.caption, text: color?.lmk_hexString ?? "—", color: LMKColor.textSecondary, numberOfLines: 1)
        hexLabel.adjustsFontSizeToFitWidth = true
        hexLabel.minimumScaleFactor = 0.6

        let textStack = UIStackView(arrangedSubviews: [labelView, hexLabel])
        textStack.axis = .vertical
        textStack.spacing = 0

        let row = UIStackView(arrangedSubviews: [swatch, textStack])
        row.axis = .horizontal
        row.spacing = LMKSpacing.xs
        row.alignment = .center
        return row
    }

    private func makePaletteRow(for sample: (label: String, image: UIImage)) -> UIView {
        let palette = LMKImage.dominantColors(from: sample.image, count: 5)

        let imageView = makeThumbnail(image: sample.image)

        let titleLabel = UILabel.lmk_make(.bodyMedium, text: sample.label)
        let countLabel = UILabel.lmk_make(.caption, text: "\(palette.count) color\(palette.count == 1 ? "" : "s")", color: LMKColor.textSecondary)

        let swatchRow = UIStackView()
        swatchRow.axis = .horizontal
        swatchRow.spacing = LMKSpacing.xs
        for color in palette {
            swatchRow.addArrangedSubview(makeSwatch(color: color, side: 28))
        }
        // A trailing spacer keeps the swatches at the leading edge.
        swatchRow.addArrangedSubview(UIView())

        let textStack = UIStackView(arrangedSubviews: [titleLabel, countLabel, swatchRow])
        textStack.axis = .vertical
        textStack.spacing = LMKSpacing.xs

        let row = UIStackView(arrangedSubviews: [imageView, textStack])
        row.axis = .horizontal
        row.spacing = LMKSpacing.medium
        row.alignment = .center
        return row
    }

    // MARK: - View builders

    private func makeThumbnail(image: UIImage) -> UIImageView {
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = LMKColor.backgroundSecondary
        imageView.lmk_applyCornerRadius(LMKCornerRadius.medium)
        imageView.snp.makeConstraints { $0.size.equalTo(80) }
        return imageView
    }

    private func makeSwatch(color: UIColor?, side: CGFloat) -> UIView {
        let swatch = UIView()
        swatch.backgroundColor = color ?? .clear
        swatch.lmk_applyCornerRadius(LMKCornerRadius.small)
        swatch.lmk_applyBorder(color: LMKColor.outline, width: 1)
        swatch.snp.makeConstraints { $0.size.equalTo(side) }
        return swatch
    }

    // MARK: - Sample image generation

    private static let defaultSize = CGSize(width: 200, height: 200)

    private static func makeSolidImage(color: UIColor, size: CGSize = defaultSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            color.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))
        }
    }

    private static func makeGradientImage(colors: [UIColor], size: CGSize = defaultSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let cgColors = colors.map(\.cgColor) as CFArray
            let space = CGColorSpaceCreateDeviceRGB()
            guard let gradient = CGGradient(colorsSpace: space, colors: cgColors, locations: nil) else { return }
            ctx.cgContext.drawLinearGradient(
                gradient,
                start: .zero,
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )
        }
    }

    private static func makeSubjectImage(background: UIColor, subject: UIColor, size: CGSize = defaultSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            background.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))
            subject.setFill()
            let inset = size.width * 0.2
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: inset, dy: inset)
            UIBezierPath(ovalIn: rect).fill()
        }
    }

    private static func makeLiftedSubjectImage(subject: UIColor, size: CGSize = defaultSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            ctx.cgContext.clear(CGRect(origin: .zero, size: size))
            subject.setFill()
            let inset = size.width * 0.2
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: inset, dy: inset)
            UIBezierPath(ovalIn: rect).fill()
        }
    }

    /// Centered square accent on a flat background — the canonical "vibrant
    /// strategy wins" case (small saturated region against a dominant neutral).
    private static func makeAccentImage(
        background: UIColor,
        accent: UIColor,
        accentFraction: CGFloat,
        size: CGSize = defaultSize
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            background.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))
            accent.setFill()
            let side = sqrt(size.width * size.height * accentFraction)
            let origin = CGPoint(x: (size.width - side) / 2, y: (size.height - side) / 2)
            UIRectFill(CGRect(origin: origin, size: CGSize(width: side, height: side)))
        }
    }

    private static func makeQuadrantImage(colors: [UIColor], size: CGSize = defaultSize) -> UIImage {
        precondition(colors.count == 4)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            let halfW = size.width / 2
            let halfH = size.height / 2
            let rects = [
                CGRect(x: 0, y: 0, width: halfW, height: halfH),
                CGRect(x: halfW, y: 0, width: halfW, height: halfH),
                CGRect(x: 0, y: halfH, width: halfW, height: halfH),
                CGRect(x: halfW, y: halfH, width: halfW, height: halfH),
            ]
            for (color, rect) in zip(colors, rects) {
                color.setFill()
                UIRectFill(rect)
            }
        }
    }

    /// Renders a center-anchored "subject" with a fur-like noise texture over a
    /// flat background — closer to a real photo than a flat oval. The noise is
    /// deterministic (seeded sequence) so the demo looks the same every launch.
    private static func makeFauxFurImage(furColor: UIColor, background: UIColor, size: CGSize = defaultSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            background.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))

            let cg = ctx.cgContext
            let inset = size.width * 0.18
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: inset, dy: inset)
            cg.saveGState()
            cg.addPath(UIBezierPath(ovalIn: rect).cgPath)
            cg.clip()

            var furR: CGFloat = 0
            var furG: CGFloat = 0
            var furB: CGFloat = 0
            furColor.getRed(&furR, green: &furG, blue: &furB, alpha: nil)

            // Deterministic LCG seeded constant so the texture is stable.
            var seed: UInt64 = 123_456_789
            func next() -> CGFloat {
                seed = seed &* 6_364_136_223_846_793_005 &+ 1
                return CGFloat((seed >> 33) & 0x7FFF) / CGFloat(0x7FFF)
            }

            let dotCount = 1500
            for _ in 0 ..< dotCount {
                let x = next() * size.width
                let y = next() * size.height
                let jitter = (next() - 0.5) * 0.18
                let r = max(0, min(1, furR + jitter))
                let g = max(0, min(1, furG + jitter))
                let b = max(0, min(1, furB + jitter))
                let radius = 1.5 + next() * 1.5
                cg.setFillColor(UIColor(red: r, green: g, blue: b, alpha: 1.0).cgColor)
                cg.fillEllipse(in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
            }
            cg.restoreGState()
        }
    }

    /// Composites several SF Symbols at random-but-stable positions on a tinted
    /// canvas — yields a reasonable palette of distinct hues.
    private static func makeSymbolSoupImage(
        background: UIColor,
        symbols: [(name: String, color: UIColor)],
        size: CGSize = defaultSize
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            background.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))
            let positions: [CGPoint] = [
                CGPoint(x: 0.20, y: 0.25),
                CGPoint(x: 0.70, y: 0.20),
                CGPoint(x: 0.50, y: 0.55),
                CGPoint(x: 0.18, y: 0.78),
                CGPoint(x: 0.80, y: 0.72),
            ]
            let symbolPointSize: CGFloat = size.width * 0.18
            let config = UIImage.SymbolConfiguration(pointSize: symbolPointSize, weight: .bold)
            for (idx, entry) in symbols.enumerated() where idx < positions.count {
                guard let raw = UIImage(systemName: entry.name, withConfiguration: config) else { continue }
                let tinted = raw.withTintColor(entry.color, renderingMode: .alwaysOriginal)
                let pos = positions[idx]
                let origin = CGPoint(
                    x: size.width * pos.x - tinted.size.width / 2,
                    y: size.height * pos.y - tinted.size.height / 2
                )
                tinted.draw(at: origin)
            }
        }
    }
}
