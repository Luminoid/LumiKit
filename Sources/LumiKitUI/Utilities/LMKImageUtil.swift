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
