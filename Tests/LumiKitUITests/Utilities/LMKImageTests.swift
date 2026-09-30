//
//  LMKImageTests.swift
//  LumiKit
//

import ImageIO
import Testing
import UIKit
import UniformTypeIdentifiers
@testable import LumiKitUI

// MARK: - LMKImage

@MainActor
struct LMKImageTests {
    @Test
    func `getSFSymbolImage returns image for valid symbol name`() {
        let image = LMKImage.symbol("heart.fill", pointSize: 24)
        #expect(image != nil)
    }

    @Test
    func `getSFSymbolImage returns nil for invalid symbol name`() {
        let image = LMKImage.symbol("nonexistent.symbol.xyz", pointSize: 24)
        #expect(image == nil)
    }

    @Test
    func `getSFSymbolImage with color returns tinted image`() {
        let image = LMKImage.symbol("star.fill", pointSize: 20, color: .red)
        #expect(image != nil)
        #expect(image?.renderingMode == .alwaysOriginal)
    }

    @Test
    func `getSFSymbolImage without color uses template rendering`() {
        let image = LMKImage.symbol("star.fill", pointSize: 20)
        #expect(image != nil)
        #expect(image?.renderingMode != .alwaysOriginal)
    }
}

// MARK: - LMKImage (makeSymbolImage)

@MainActor
struct LMKImageMakeSymbolImageTests {
    @Test
    func `returns non-nil for valid symbol`() {
        let image = LMKImage.makeSymbolImage("heart.fill", size: CGSize(width: 44, height: 44), symbolPointSize: 20, tintColor: .red)
        #expect(image != nil)
    }

    @Test
    func `returns nil for invalid symbol`() {
        let image = LMKImage.makeSymbolImage("nonexistent.xyz.abc", size: CGSize(width: 44, height: 44), symbolPointSize: 20, tintColor: .red)
        #expect(image == nil)
    }

    @Test
    func `returns image of correct size`() {
        let size = CGSize(width: 60, height: 60)
        let image = LMKImage.makeSymbolImage("star.fill", size: size, symbolPointSize: 24, tintColor: .blue)
        #expect(image?.size == size)
    }

    @Test
    func `without backgroundColor produces image`() {
        let image = LMKImage.makeSymbolImage("checkmark", size: CGSize(width: 32, height: 32), symbolPointSize: 16, tintColor: .green, backgroundColor: nil)
        #expect(image != nil)
    }

    @Test
    func `with backgroundColor produces image`() {
        let image = LMKImage.makeSymbolImage("checkmark", size: CGSize(width: 32, height: 32), symbolPointSize: 16, tintColor: .white, backgroundColor: .blue)
        #expect(image != nil)
    }
}

// MARK: - LMKImage (encodeJPEG)

@MainActor
struct LMKImageEncodeJPEGTests {
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
        let data = LMKImage.encodeJPEG(image, maxDimension: 2048)
        #expect(data != nil)
        // JPEG magic bytes.
        #expect(data?.prefix(2) == Data([0xFF, 0xD8]))
    }

    @Test
    func `Downsamples the longest edge to maxDimension`() {
        let image = makeImage(width: 400, height: 200)
        let data = LMKImage.encodeJPEG(image, maxDimension: 100)
        let decoded = data.flatMap(UIImage.init(data:))
        #expect(decoded?.size.width == 100)
        #expect(decoded?.size.height == 50)
    }

    @Test
    func `Never upscales a smaller image`() {
        let image = makeImage(width: 80, height: 40)
        let data = LMKImage.encodeJPEG(image, maxDimension: 2048)
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
        let data = LMKImage.encodeJPEG(oriented, maxDimension: 2048)
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
        let data = LMKImage.encodeJPEG(translucent, maxDimension: 2048)
        let decodedAlphaInfo = data.flatMap(UIImage.init(data:))?.cgImage?.alphaInfo
        #expect(decodedAlphaInfo == CGImageAlphaInfo.none || decodedAlphaInfo == .noneSkipLast || decodedAlphaInfo == .noneSkipFirst)
    }

    @Test
    func `Returns nil for an empty image`() {
        #expect(LMKImage.encodeJPEG(UIImage(), maxDimension: 2048) == nil)
    }

    @Test
    func `Lower quality produces no larger data`() {
        let image = makeImage(width: 300, height: 300)
        let high = LMKImage.encodeJPEG(image, maxDimension: 2048, quality: 1.0)
        let low = LMKImage.encodeJPEG(image, maxDimension: 2048, quality: 0.1)
        guard let high, let low else {
            Issue.record("Encode failed")
            return
        }
        #expect(low.count <= high.count)
    }
}

// MARK: - Downsampling

@MainActor
struct LMKImageDownsampleTests {
    private func makeJPEG(width: Int, height: Int, orientation: CGImagePropertyOrientation = .up) -> Data {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format).image { context in
            UIColor.systemTeal.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
        guard let cgImage = image.cgImage else { return Data() }
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else { return Data() }
        let properties: [CFString: Any] = [kCGImagePropertyOrientation: orientation.rawValue]
        CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)
        CGImageDestinationFinalize(destination)
        return data as Data
    }

    @Test
    func `downsample decodes to the longest edge and never upscales`() {
        let data = makeJPEG(width: 400, height: 200)
        let small = LMKImage.downsample(data: data, maxPixelSize: 100)
        #expect(small?.size == CGSize(width: 100, height: 50))
        #expect(small?.scale == 1)
        let large = LMKImage.downsample(data: data, maxPixelSize: 4000)
        #expect(large?.size == CGSize(width: 400, height: 200))
        #expect(LMKImage.downsample(data: data, maxPixelSize: 0) == nil)
        #expect(LMKImage.downsample(data: Data([0, 1, 2]), maxPixelSize: 100) == nil)
    }

    @Test
    func `downsample applies the orientation and honours the scale option`() {
        let data = makeJPEG(width: 300, height: 100, orientation: .right)
        let image = LMKImage.downsample(data: data, maxPixelSize: 150)
        #expect(image?.size == CGSize(width: 50, height: 150), "a .right-oriented landscape decodes as portrait")
        #expect(image?.imageOrientation == .up)

        let scaled = LMKImage.downsample(data: makeJPEG(width: 300, height: 100), maxPixelSize: 300, options: LMKImage.DownsampleOptions(scale: 3))
        #expect(scaled?.scale == 3)
        #expect(scaled?.size.width == 100)
        #expect(abs((scaled?.size.height ?? 0) - 100.0 / 3) < 0.01)
    }

    @Test
    func `downsample reads files and runs off the main actor`() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("lmk-downsample-\(UUID().uuidString).jpg")
        try makeJPEG(width: 640, height: 480).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        // In an async context the async overload wins; the sync one is exercised from the sync tests.
        let fromFile = await LMKImage.downsample(fileURL: url, maxPixelSize: 64)
        #expect(fromFile?.size == CGSize(width: 64, height: 48))
        let async = await LMKImage.downsample(fileURL: url, maxPixelSize: 32)
        #expect(async?.size == CGSize(width: 32, height: 24))
        let fromData = await LMKImage.downsample(data: makeJPEG(width: 640, height: 480), maxPixelSize: 16)
        #expect(fromData?.size == CGSize(width: 16, height: 12))
    }

    @Test
    func `downsample reads a file synchronously`() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("lmk-downsample-sync-\(UUID().uuidString).jpg")
        try makeJPEG(width: 640, height: 480).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        #expect(LMKImage.downsample(fileURL: url, maxPixelSize: 64)?.size == CGSize(width: 64, height: 48))
        #expect(LMKImage.downsample(fileURL: URL(fileURLWithPath: "/nonexistent.jpg"), maxPixelSize: 64) == nil)
    }

    @Test
    func `pixelSize rounds points up at the scale`() {
        #expect(LMKImage.pixelSize(points: 44, scale: 3) == 132)
        #expect(LMKImage.pixelSize(points: 10.4, scale: 2) == 21)
        #expect(LMKImage.pixelSize(points: 10, scale: 0.5) == 10, "scale floors at 1")
        #expect(LMKImage.pixelSize(CGSize(width: 10, height: 20), scale: 2) == CGSize(width: 20, height: 40))
    }

    @Test
    func `downsampledJPEG yields an opaque JPEG at the requested size`() {
        let data = makeJPEG(width: 800, height: 400)
        let jpeg = LMKImage.downsampledJPEG(data: data, maxPixelSize: 200, quality: 0.7)
        #expect(jpeg?.prefix(2) == Data([0xFF, 0xD8]))
        #expect(LMKImage.imageSize(of: jpeg ?? Data()) == CGSize(width: 200, height: 100))
        #expect(LMKImage.downsampledJPEG(data: Data([1, 2]), maxPixelSize: 200) == nil)
    }

    @Test
    func `imageSize reads the header with the orientation applied`() throws {
        #expect(LMKImage.imageSize(of: makeJPEG(width: 320, height: 240)) == CGSize(width: 320, height: 240))
        #expect(LMKImage.imageSize(of: makeJPEG(width: 320, height: 240, orientation: .left)) == CGSize(width: 240, height: 320))
        #expect(LMKImage.imageSize(of: Data([0, 1])) == nil)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("lmk-size-\(UUID().uuidString).jpg")
        try makeJPEG(width: 12, height: 34).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        #expect(LMKImage.imageSize(of: url) == CGSize(width: 12, height: 34))
    }
}
