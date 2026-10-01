//
//  LMKImage+QRCode.swift
//  LumiKit
//
//  Generates QR code images using CoreImage.
//

import CoreImage.CIFilterBuiltins
import UIKit

/// Generates QR code images from strings using CoreImage.
///
/// ```swift
/// if let qrImage = LMKImage.qrCode(from: "https://example.com", size: 200) {
///     imageView.image = qrImage
/// }
/// ```
public nonisolated extension LMKImage {
    /// QR code error correction level.
    enum QRCorrectionLevel: String, Sendable, Hashable {
        /// ~7% recovery.
        case low = "L"
        /// ~15% recovery.
        case medium = "M"
        /// ~25% recovery.
        case quartile = "Q"
        /// ~30% recovery.
        case high = "H"
    }
}

@MainActor public extension LMKImage {
    /// Generate a QR code image from a string.
    /// - Parameters:
    ///   - string: The content to encode.
    ///   - size: Target point size (rendered at screen scale for sharpness). Defaults to 200.
    ///   - scale: Rendering scale factor. Pass `nil` to use the key window's display scale.
    ///   - correctionLevel: Error correction level. Defaults to `.medium`.
    /// - Returns: A `UIImage` of the QR code, or `nil` if generation fails.
    static func qrCode(
        from string: String,
        size: CGFloat = 200,
        scale: CGFloat? = nil,
        correctionLevel: QRCorrectionLevel = .medium
    ) -> UIImage? {
        guard !string.isEmpty else { return nil }
        guard let data = string.data(using: .utf8) else { return nil }

        let resolvedScale = scale ?? LMKScene.screenScale

        let filter = CIFilter.qrCodeGenerator()
        filter.message = data
        filter.correctionLevel = correctionLevel.rawValue

        guard let ciImage = filter.outputImage else { return nil }

        // Scale to target size at screen scale for sharp rendering
        let pixelSize = size * resolvedScale
        let scaleTransform = pixelSize / ciImage.extent.width
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scaleTransform, y: scaleTransform))

        guard let cgImage = ciContext.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return UIImage(cgImage: cgImage, scale: resolvedScale, orientation: .up)
    }
}
