//
//  LMKImageUtilTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKImageUtil

@MainActor
struct LMKImageUtilTests {
    @Test
    func `getSFSymbolImage returns image for valid symbol name`() {
        let image = LMKImageUtil.getSFSymbolImage("heart.fill", pointSize: 24)
        #expect(image != nil)
    }

    @Test
    func `getSFSymbolImage returns nil for invalid symbol name`() {
        let image = LMKImageUtil.getSFSymbolImage("nonexistent.symbol.xyz", pointSize: 24)
        #expect(image == nil)
    }

    @Test
    func `getSFSymbolImage with color returns tinted image`() {
        let image = LMKImageUtil.getSFSymbolImage("star.fill", pointSize: 20, color: .red)
        #expect(image != nil)
        #expect(image?.renderingMode == .alwaysOriginal)
    }

    @Test
    func `getSFSymbolImage without color uses template rendering`() {
        let image = LMKImageUtil.getSFSymbolImage("star.fill", pointSize: 20)
        #expect(image != nil)
        #expect(image?.renderingMode != .alwaysOriginal)
    }
}

// MARK: - LMKImageUtil (makeSymbolImage)

@MainActor
struct LMKImageUtilMakeSymbolImageTests {
    @Test
    func `returns non-nil for valid symbol`() {
        let image = LMKImageUtil.makeSymbolImage("heart.fill", size: CGSize(width: 44, height: 44), symbolPointSize: 20, tintColor: .red)
        #expect(image != nil)
    }

    @Test
    func `returns nil for invalid symbol`() {
        let image = LMKImageUtil.makeSymbolImage("nonexistent.xyz.abc", size: CGSize(width: 44, height: 44), symbolPointSize: 20, tintColor: .red)
        #expect(image == nil)
    }

    @Test
    func `returns image of correct size`() {
        let size = CGSize(width: 60, height: 60)
        let image = LMKImageUtil.makeSymbolImage("star.fill", size: size, symbolPointSize: 24, tintColor: .blue)
        #expect(image?.size == size)
    }

    @Test
    func `without backgroundColor produces image`() {
        let image = LMKImageUtil.makeSymbolImage("checkmark", size: CGSize(width: 32, height: 32), symbolPointSize: 16, tintColor: .green, backgroundColor: nil)
        #expect(image != nil)
    }

    @Test
    func `with backgroundColor produces image`() {
        let image = LMKImageUtil.makeSymbolImage("checkmark", size: CGSize(width: 32, height: 32), symbolPointSize: 16, tintColor: .white, backgroundColor: .blue)
        #expect(image != nil)
    }
}

// MARK: - LMKImageUtil (encodeJPEG)

@MainActor
struct LMKImageUtilEncodeJPEGTests {
    private func makeImage(width: CGFloat, height: CGFloat, color: UIColor = .systemRed) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }

    @Test
    func `Encodes valid JPEG data`() {
        let image = makeImage(width: 100, height: 50)
        let data = LMKImageUtil.encodeJPEG(image, maxDimension: 2048)
        #expect(data != nil)
        // JPEG magic bytes.
        #expect(data?.prefix(2) == Data([0xFF, 0xD8]))
    }

    @Test
    func `Downsamples the longest edge to maxDimension`() {
        let image = makeImage(width: 400, height: 200)
        let data = LMKImageUtil.encodeJPEG(image, maxDimension: 100)
        let decoded = data.flatMap(UIImage.init(data:))
        #expect(decoded?.size.width == 100)
        #expect(decoded?.size.height == 50)
    }

    @Test
    func `Never upscales a smaller image`() {
        let image = makeImage(width: 80, height: 40)
        let data = LMKImageUtil.encodeJPEG(image, maxDimension: 2048)
        let decoded = data.flatMap(UIImage.init(data:))
        #expect(decoded?.size.width == 80)
        #expect(decoded?.size.height == 40)
    }

    @Test
    func `Normalizes EXIF orientation into the pixels`() {
        let base = makeImage(width: 100, height: 60)
        guard let cgImage = base.cgImage else {
            Issue.record("Missing cgImage")
            return
        }
        // A .left-oriented image reports a swapped (60x100) display size.
        let oriented = UIImage(cgImage: cgImage, scale: 1, orientation: .left)
        let data = LMKImageUtil.encodeJPEG(oriented, maxDimension: 2048)
        let decoded = data.flatMap(UIImage.init(data:))
        #expect(decoded?.imageOrientation == .up)
        #expect(decoded?.size.width == 60)
        #expect(decoded?.size.height == 100)
    }

    @Test
    func `Strips alpha into an opaque encode`() {
        // Draw a semi-transparent image; the JPEG must still decode as fully opaque.
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 40), format: format)
        let translucent = renderer.image { context in
            UIColor.systemBlue.withAlphaComponent(0.5).setFill()
            context.fill(CGRect(x: 0, y: 0, width: 40, height: 40))
        }
        let data = LMKImageUtil.encodeJPEG(translucent, maxDimension: 2048)
        let decodedAlphaInfo = data.flatMap(UIImage.init(data:))?.cgImage?.alphaInfo
        #expect(decodedAlphaInfo == CGImageAlphaInfo.none || decodedAlphaInfo == .noneSkipLast || decodedAlphaInfo == .noneSkipFirst)
    }

    @Test
    func `Returns nil for an empty image`() {
        #expect(LMKImageUtil.encodeJPEG(UIImage(), maxDimension: 2048) == nil)
    }

    @Test
    func `Lower quality produces no larger data`() {
        let image = makeImage(width: 300, height: 300)
        let high = LMKImageUtil.encodeJPEG(image, maxDimension: 2048, quality: 1.0)
        let low = LMKImageUtil.encodeJPEG(image, maxDimension: 2048, quality: 0.1)
        guard let high, let low else {
            Issue.record("Encode failed")
            return
        }
        #expect(low.count <= high.count)
    }
}
