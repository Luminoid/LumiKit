//
//  LMKDominantColorExtractorTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKDominantColorExtractorTests {
    @Test
    func `Solid red image extracts red`() {
        let image = makeSolidImage(color: .red, size: CGSize(width: 80, height: 80))
        let color = LMKDominantColorExtractor.dominantColor(from: image)
        #expect(color != nil)
        let (r, g, b) = rgb(color)
        #expect(r > 0.85)
        #expect(g < 0.2)
        #expect(b < 0.2)
    }

    @Test
    func `Solid blue image extracts blue`() {
        let image = makeSolidImage(color: .blue, size: CGSize(width: 80, height: 80))
        let color = LMKDominantColorExtractor.dominantColor(from: image)
        let (r, g, b) = rgb(color)
        #expect(b > 0.85)
        #expect(r < 0.2)
        #expect(g < 0.2)
    }

    @Test
    func `Solid black image extracts black not muddy grey`() {
        let image = makeSolidImage(color: .black, size: CGSize(width: 80, height: 80))
        let color = LMKDominantColorExtractor.dominantColor(from: image)
        let (r, g, b) = rgb(color)
        #expect(r < 0.1)
        #expect(g < 0.1)
        #expect(b < 0.1)
    }

    @Test
    func `Mostly red with small green corner returns red bucket`() {
        // Histogram should pick the dominant red bucket, not the average
        // (which would be desaturated brown).
        let image = makeBicolorImage(
            primary: .red,
            secondary: .green,
            secondaryFraction: 0.15,
            size: CGSize(width: 80, height: 80)
        )
        let color = LMKDominantColorExtractor.dominantColor(from: image)
        let (r, g, b) = rgb(color)
        #expect(r > 0.7)
        #expect(g < 0.3)
        #expect(b < 0.3)
    }

    @Test
    func `ignoringTransparent returns nil when fully transparent`() {
        let image = makeSolidImage(color: .clear, size: CGSize(width: 80, height: 80))
        let color = LMKDominantColorExtractor.dominantColor(from: image, ignoringTransparent: true)
        #expect(color == nil)
    }

    @Test
    func `ignoringTransparent samples only opaque pixels`() {
        // Transparent border, opaque blue center — should return blue.
        let image = makeSubjectLiftedImage(
            subjectColor: .blue,
            subjectFraction: 0.4,
            size: CGSize(width: 80, height: 80)
        )
        let color = LMKDominantColorExtractor.dominantColor(from: image, ignoringTransparent: true)
        let (r, g, b) = rgb(color)
        #expect(b > 0.85)
        #expect(r < 0.2)
        #expect(g < 0.2)
    }

    @Test
    func `Image without cgImage returns nil`() {
        // CIImage-backed UIImage has no cgImage by default.
        let ci = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 10, height: 10))
        let image = UIImage(ciImage: ci)
        let color = LMKDominantColorExtractor.dominantColor(from: image)
        #expect(color == nil)
    }

    // MARK: - Strategy

    @Test
    func `Average strategy on bicolor image returns mixed color not modal`() {
        // 50/50 red/blue should average toward purple, not the modal red.
        let image = makeBicolorImage(
            primary: .red,
            secondary: .blue,
            secondaryFraction: 0.5,
            size: CGSize(width: 80, height: 80)
        )
        let modal = LMKDominantColorExtractor.dominantColor(from: image, strategy: .modal)
        let average = LMKDominantColorExtractor.dominantColor(from: image, strategy: .average)
        let (mr, mg, mb) = rgb(modal)
        let (ar, ag, ab) = rgb(average)
        // Modal picks one cluster (either red-ish or blue-ish dominates a single bucket)
        let modalIsRedOrBlue = (mr > 0.7 && mb < 0.3) || (mb > 0.7 && mr < 0.3)
        #expect(modalIsRedOrBlue)
        // Average mixes both — RGB channels are intermediate, not pegged to 0 or 1
        #expect(ar > 0.2 && ar < 0.8)
        #expect(ab > 0.2 && ab < 0.8)
        #expect(ag < 0.3) // no green in either input
    }

    @Test
    func `Modal is the default strategy`() {
        let image = makeSolidImage(color: .systemTeal, size: CGSize(width: 80, height: 80))
        let implicit = LMKDominantColorExtractor.dominantColor(from: image)
        let explicit = LMKDominantColorExtractor.dominantColor(from: image, strategy: .modal)
        let (ir, ig, ib) = rgb(implicit)
        let (er, eg, eb) = rgb(explicit)
        // Same strategy, same image, same result (within bucket-rounding tolerance)
        #expect(abs(ir - er) < 0.01)
        #expect(abs(ig - eg) < 0.01)
        #expect(abs(ib - eb) < 0.01)
    }

    @Test
    func `Vibrant picks saturated accent over neutral background`() {
        // Neutral grey background dominating ~85% of the image, with a small
        // bright red region (~15%). Modal picks grey; vibrant should pick red.
        let image = makeAccentImage(
            background: .systemGray3,
            accent: .systemRed,
            accentFraction: 0.15,
            size: CGSize(width: 80, height: 80)
        )
        let modal = LMKDominantColorExtractor.dominantColor(from: image, strategy: .modal)
        let vibrant = LMKDominantColorExtractor.dominantColor(from: image, strategy: .vibrant)

        let (mr, mg, mb) = rgb(modal)
        // Modal lands somewhere in grey territory: r ≈ g ≈ b
        let modalIsGrey = abs(mr - mg) < 0.15 && abs(mg - mb) < 0.15
        #expect(modalIsGrey, "modal should land in grey territory")

        let (vr, vg, vb) = rgb(vibrant)
        #expect(vr > 0.7, "vibrant should be red-dominant: r=\(vr) g=\(vg) b=\(vb)")
        #expect(vg < 0.4)
        #expect(vb < 0.4)
    }

    @Test
    func `Vibrant on grayscale image falls through to modal`() {
        // Pure greys → every bucket has saturation 0 → vibrant should pick the
        // densest bucket, matching modal.
        let image = makeSolidImage(color: .systemGray2, size: CGSize(width: 80, height: 80))
        let modal = LMKDominantColorExtractor.dominantColor(from: image, strategy: .modal)
        let vibrant = LMKDominantColorExtractor.dominantColor(from: image, strategy: .vibrant)
        let (mr, mg, mb) = rgb(modal)
        let (vr, vg, vb) = rgb(vibrant)
        #expect(abs(mr - vr) < 0.05)
        #expect(abs(mg - vg) < 0.05)
        #expect(abs(mb - vb) < 0.05)
    }

    // MARK: - Palette

    @Test
    func `Palette extraction returns multiple colors for multi-color image`() {
        let image = makeQuadrantImage(
            colors: [.red, .green, .blue, .yellow],
            size: CGSize(width: 80, height: 80)
        )
        let palette = LMKDominantColorExtractor.dominantColors(from: image, count: 4)
        #expect(palette.count == 4)
        // The four returned colors should each be close to one of the four inputs.
        let inputs: [(CGFloat, CGFloat, CGFloat)] = [
            (1, 0, 0), (0, 1, 0), (0, 0, 1), (1, 1, 0),
        ]
        for color in palette {
            let (r, g, b) = rgb(color)
            let matches = inputs.contains { input in
                abs(r - input.0) < 0.2 && abs(g - input.1) < 0.2 && abs(b - input.2) < 0.2
            }
            #expect(matches, "palette color (\(r), \(g), \(b)) doesn't match any input")
        }
    }

    @Test
    func `Palette is ordered by frequency descending`() {
        // Red top 70%, blue bottom 30% — full-width bands so the 20% border
        // crop doesn't trim the minority color away.
        let image = makeHorizontalBandsImage(
            top: .red,
            bottom: .blue,
            topFraction: 0.7,
            size: CGSize(width: 80, height: 80)
        )
        let palette = LMKDominantColorExtractor.dominantColors(from: image, count: 2)
        #expect(palette.count == 2)
        let (r0, _, b0) = rgb(palette[0])
        let (r1, _, b1) = rgb(palette[1])
        #expect(r0 > 0.7 && b0 < 0.3, "first color should be red-dominant")
        #expect(b1 > 0.7 && r1 < 0.3, "second color should be blue-dominant")
    }

    @Test
    func `Palette returns fewer than count for solid image`() {
        let image = makeSolidImage(color: .systemPink, size: CGSize(width: 80, height: 80))
        let palette = LMKDominantColorExtractor.dominantColors(from: image, count: 5)
        #expect(palette.count == 1)
    }

    @Test
    func `Palette with count zero returns empty`() {
        let image = makeSolidImage(color: .red, size: CGSize(width: 80, height: 80))
        let palette = LMKDominantColorExtractor.dominantColors(from: image, count: 0)
        #expect(palette.isEmpty)
    }

    @Test
    func `Palette with fully transparent and ignoringTransparent returns empty`() {
        let image = makeSolidImage(color: .clear, size: CGSize(width: 80, height: 80))
        let palette = LMKDominantColorExtractor.dominantColors(from: image, count: 3, ignoringTransparent: true)
        #expect(palette.isEmpty)
    }

    // MARK: - Helpers

    private func makeSolidImage(color: UIColor, size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        defer { UIGraphicsEndImageContext() }
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }

    private func makeBicolorImage(
        primary: UIColor,
        secondary: UIColor,
        secondaryFraction: CGFloat,
        size: CGSize
    ) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        defer { UIGraphicsEndImageContext() }
        primary.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        secondary.setFill()
        let side = sqrt(size.width * size.height * secondaryFraction)
        UIRectFill(CGRect(x: 0, y: 0, width: side, height: side))
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }

    private func makeHorizontalBandsImage(
        top: UIColor,
        bottom: UIColor,
        topFraction: CGFloat,
        size: CGSize
    ) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, true, 1)
        defer { UIGraphicsEndImageContext() }
        let topHeight = size.height * topFraction
        top.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: size.width, height: topHeight))
        bottom.setFill()
        UIRectFill(CGRect(x: 0, y: topHeight, width: size.width, height: size.height - topHeight))
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }

    private func makeAccentImage(
        background: UIColor,
        accent: UIColor,
        accentFraction: CGFloat,
        size: CGSize
    ) -> UIImage {
        // Centered square accent so the 20% border-crop preserves its area.
        UIGraphicsBeginImageContextWithOptions(size, true, 1)
        defer { UIGraphicsEndImageContext() }
        background.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        accent.setFill()
        let side = sqrt(size.width * size.height * accentFraction)
        let origin = CGPoint(x: (size.width - side) / 2, y: (size.height - side) / 2)
        UIRectFill(CGRect(origin: origin, size: CGSize(width: side, height: side)))
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }

    private func makeQuadrantImage(colors: [UIColor], size: CGSize) -> UIImage {
        precondition(colors.count == 4)
        UIGraphicsBeginImageContextWithOptions(size, true, 1)
        defer { UIGraphicsEndImageContext() }
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
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }

    private func makeSubjectLiftedImage(
        subjectColor: UIColor,
        subjectFraction: CGFloat,
        size: CGSize
    ) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            ctx.cgContext.clear(CGRect(origin: .zero, size: size))
            subjectColor.setFill()
            let side = sqrt(size.width * size.height * subjectFraction)
            let origin = CGPoint(x: (size.width - side) / 2, y: (size.height - side) / 2)
            UIRectFill(CGRect(origin: origin, size: CGSize(width: side, height: side)))
        }
    }

    private func rgb(_ color: UIColor?) -> (CGFloat, CGFloat, CGFloat) {
        guard let color else { return (-1, -1, -1) }
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b)
    }
}
