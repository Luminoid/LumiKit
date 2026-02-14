//
//  UIImage+LMK.swift
//  LumiKit
//
//  UIImage instance extensions for resizing, rounding, and placeholders.
//

import UIKit

public extension UIImage {
    /// Resize image to fit within the given maximum dimension, preserving aspect ratio.
    ///
    /// ```swift
    /// let thumbnail = photo.lmk_resized(maxDimension: 200)
    /// ```
    func lmk_resized(maxDimension: CGFloat) -> UIImage {
        guard size.width > 0, size.height > 0 else { return self }
        let aspectRatio = size.width / size.height
        let targetSize: CGSize
        if size.width > size.height {
            targetSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            targetSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        return lmk_resized(to: targetSize)
    }

    /// Resize image to an exact size.
    ///
    /// ```swift
    /// let icon = image.lmk_resized(to: CGSize(width: 32, height: 32))
    /// ```
    func lmk_resized(to targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    /// Create a solid color image of the given size. Useful for placeholders.
    ///
    /// ```swift
    /// let placeholder = UIImage.lmk_solidColor(.systemGray5, size: CGSize(width: 100, height: 100))
    /// ```
    static func lmk_solidColor(_ color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    /// Returns image with rounded corners applied.
    ///
    /// ```swift
    /// let rounded = photo.lmk_rounded(cornerRadius: 12)
    /// ```
    func lmk_rounded(cornerRadius: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)
            UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).addClip()
            draw(in: rect)
        }
    }
}
