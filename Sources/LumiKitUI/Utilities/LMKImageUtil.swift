//
//  LMKImageUtil.swift
//  LumiKit
//
//  Image utility helpers.
//

import UIKit
import UniformTypeIdentifiers

/// Image utility helpers.
public nonisolated enum LMKImageUtil {
    /// Create an SF Symbol image with a given point size and optional color.
    public static func getSFSymbolImage(_ name: String, pointSize: CGFloat, color: UIColor? = nil) -> UIImage? {
        let image = UIImage(systemName: name, withConfiguration: UIImage.SymbolConfiguration(pointSize: pointSize))
        if let color {
            return image?.withTintColor(color, renderingMode: .alwaysOriginal)
        }
        return image
    }

    // MARK: - Composite Image

    /// Create a composite image with an optional background fill and a centered SF Symbol.
    /// - Parameters:
    ///   - name: SF Symbol name.
    ///   - size: Output image canvas size in points.
    ///   - symbolPointSize: Point size for the SF Symbol.
    ///   - tintColor: Color applied to the symbol.
    ///   - backgroundColor: Optional fill color for the background. Defaults to `nil` (transparent).
    /// - Returns: Rendered `UIImage`, or `nil` if the symbol name is invalid.
    @MainActor
    public static func makeSymbolImage(
        _ name: String,
        size: CGSize,
        symbolPointSize: CGFloat,
        tintColor: UIColor,
        backgroundColor: UIColor? = nil
    ) -> UIImage? {
        guard let symbolImage = UIImage(
            systemName: name,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: symbolPointSize)
        )?.withTintColor(tintColor, renderingMode: .alwaysOriginal) else {
            return nil
        }

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            if let backgroundColor {
                backgroundColor.setFill()
                UIBezierPath(rect: CGRect(origin: .zero, size: size)).fill()
            }
            let symbolSize = symbolImage.size
            let origin = CGPoint(
                x: (size.width - symbolSize.width) / 2,
                y: (size.height - symbolSize.height) / 2
            )
            symbolImage.draw(at: origin)
        }
    }

    // MARK: - JPEG Encoding

    /// Downsample and encode an image as an opaque JPEG.
    ///
    /// Redraws into an opaque RGBX `CGContext` (`.noneSkipLast`) so the encode stays
    /// 3-channel. Required because images produced by
    /// `CGImageSourceCreateThumbnailAtIndex` (and many picker paths) carry
    /// `AlphaPremulLast` even for opaque sources; piping that directly into
    /// `UIImage.jpegData` makes ImageIO log "trying to save an opaque image with
    /// 'AlphaPremulLast' ... will double the required memory when decoding the image".
    /// Drawing via UIKit normalizes EXIF orientation in the same pass.
    /// `nonisolated` so encodes can run on background queues without MainActor hops.
    ///
    /// - Parameters:
    ///   - image: The image to encode.
    ///   - maxDimension: Longest edge of the output in points; larger images are downsampled (never upscaled).
    ///   - quality: JPEG compression quality (0.0--1.0). Default 0.8.
    /// - Returns: Opaque JPEG data, or `nil` if the image is empty or the encode fails.
    public static func encodeJPEG(_ image: UIImage, maxDimension: CGFloat, quality: CGFloat = 0.8) -> Data? {
        let size = image.size
        guard size.width > 0, size.height > 0, maxDimension > 0 else { return nil }
        let scale = min(1, maxDimension / max(size.width, size.height))
        let pixelWidth = Int((size.width * scale).rounded())
        let pixelHeight = Int((size.height * scale).rounded())
        guard pixelWidth > 0, pixelHeight > 0 else { return nil }

        guard let context = CGContext(
            data: nil,
            width: pixelWidth,
            height: pixelHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else { return nil }

        // Draw through UIKit so the image's EXIF orientation is applied. Flip the
        // context first: CoreGraphics origins are bottom-left, UIKit's top-left.
        UIGraphicsPushContext(context)
        context.translateBy(x: 0, y: CGFloat(pixelHeight))
        context.scaleBy(x: 1, y: -1)
        image.draw(in: CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight))
        UIGraphicsPopContext()
        guard let opaqueImage = context.makeImage() else { return nil }

        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else { return nil }
        let options: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: quality]
        CGImageDestinationAddImage(destination, opaqueImage, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }

    // MARK: - Pixel Buffer

    private static let ciContext = CIContext()

    /// Convert a `CVPixelBuffer` to JPEG `Data`.
    /// - Parameters:
    ///   - pixelBuffer: The pixel buffer to convert.
    ///   - attachments: Optional metadata attachments.
    ///   - compressionQuality: JPEG compression quality (0.0--1.0). Default 0.9.
    public static func jpegData(withPixelBuffer pixelBuffer: CVPixelBuffer, attachments: CFDictionary?, compressionQuality: CGFloat = 0.9) -> Data? {
        let renderedCIImage = CIImage(cvImageBuffer: pixelBuffer)
        guard let renderedCGImage = ciContext.createCGImage(renderedCIImage, from: renderedCIImage.extent) else {
            return nil
        }
        guard let data = CFDataCreateMutable(kCFAllocatorDefault, 0) else {
            return nil
        }
        guard let cgImageDestination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else {
            return nil
        }
        var imageProperties: [String: Any] = (attachments as? [String: Any]) ?? [:]
        imageProperties[kCGImageDestinationLossyCompressionQuality as String] = compressionQuality
        CGImageDestinationAddImage(cgImageDestination, renderedCGImage, imageProperties as CFDictionary)
        if CGImageDestinationFinalize(cgImageDestination) {
            return data as Data
        }
        return nil
    }
}
