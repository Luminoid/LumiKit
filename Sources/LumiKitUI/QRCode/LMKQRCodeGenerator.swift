//
//  LMKQRCodeGenerator.swift
//  LumiKit
//
//  Generates QR code images using CoreImage.
//

import CoreImage.CIFilterBuiltins
import UIKit

/// Generates QR code images from strings using CoreImage.
///
/// ```swift
/// if let qrImage = LMKQRCodeGenerator.generateQRCode(from: "https://example.com", size: 200) {
///     imageView.image = qrImage
/// }
/// ```
public enum LMKQRCodeGenerator {
    /// QR code error correction level.
    public enum CorrectionLevel: String, Sendable {
        /// ~7% recovery.
        case low = "L"
        /// ~15% recovery.
        case medium = "M"
        /// ~25% recovery.
        case quartile = "Q"
        /// ~30% recovery.
        case high = "H"
    }

    /// Generate a QR code image from a string.
    /// - Parameters:
    ///   - string: The content to encode.
    ///   - size: Target point size (rendered at screen scale for sharpness). Defaults to 200.
    ///   - correctionLevel: Error correction level. Defaults to `.medium`.
    /// - Returns: A `UIImage` of the QR code, or `nil` if generation fails.
    public static func generateQRCode(
        from string: String,
        size: CGFloat = 200,
        correctionLevel: CorrectionLevel = .medium
    ) -> UIImage? {
        guard let data = string.data(using: .utf8) else { return nil }

        let filter = CIFilter.qrCodeGenerator()
        filter.message = data
        filter.correctionLevel = correctionLevel.rawValue

        guard let ciImage = filter.outputImage else { return nil }

        // Scale to target size at screen resolution for sharp rendering
        let screenScale = UIScreen.main.scale
        let pixelSize = size * screenScale
        let scale = pixelSize / ciImage.extent.width
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return UIImage(cgImage: cgImage, scale: screenScale, orientation: .up)
    }
}
