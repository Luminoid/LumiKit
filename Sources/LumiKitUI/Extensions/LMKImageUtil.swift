//
//  LMKImageUtil.swift
//  LumiKit
//
//  Image utility helpers.
//

import UIKit
import UniformTypeIdentifiers

/// Image utility helpers.
public enum LMKImageUtil {
    /// Create an SF Symbol image with a given point size and optional color.
    public static func getSFSymbolImage(_ name: String, pointSize: CGFloat, color: UIColor? = nil) -> UIImage? {
        let image = UIImage(systemName: name, withConfiguration: UIImage.SymbolConfiguration(pointSize: pointSize))
        if let color {
            return image?.withTintColor(color, renderingMode: .alwaysOriginal)
        }
        return image
    }

    /// Convert a `CVPixelBuffer` to JPEG `Data`.
    public static func jpegData(withPixelBuffer pixelBuffer: CVPixelBuffer, attachments: CFDictionary?) -> Data? {
        let ciContext = CIContext()
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
        CGImageDestinationAddImage(cgImageDestination, renderedCGImage, attachments)
        if CGImageDestinationFinalize(cgImageDestination) {
            return data as Data
        }
        return nil
    }
}
