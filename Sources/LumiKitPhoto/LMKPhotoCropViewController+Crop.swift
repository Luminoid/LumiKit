//
//  LMKPhotoCropViewController+Crop.swift
//  LumiKit
//
//  The crop itself: view-to-pixel mapping and the off-main render.
//

import UIKit

extension LMKPhotoCropViewController {
    /// The rect of the image under `cropFrame`, in the oriented image's point space (`imageSize`
    /// units), given the image view's `imageFrame` in the same coordinates as the frame. Snapped
    /// to whole units so no fractional edge anti-aliases into a hairline; `nil` when nothing of
    /// the image is inside the frame.
    nonisolated static func cropRect(cropFrame: CGRect, imageFrame: CGRect, imageSize: CGSize) -> CGRect? {
        guard imageFrame.width > 0, imageFrame.height > 0, imageSize.width > 0, imageSize.height > 0 else { return nil }
        let scale = imageSize.width / imageFrame.width
        let inImageView = cropFrame.offsetBy(dx: -imageFrame.origin.x, dy: -imageFrame.origin.y)
        let pixelRect = CGRect(
            x: inImageView.origin.x * scale,
            y: inImageView.origin.y * scale,
            width: inImageView.width * scale,
            height: inImageView.height * scale
        )
        let clamped = pixelRect.intersection(CGRect(origin: .zero, size: imageSize)).integral
        guard !clamped.isEmpty, clamped.width > 0, clamped.height > 0 else { return nil }
        return clamped
    }

    /// Crops `image` to `cropRect` (the oriented image's point space, from `cropRect(cropFrame:imageFrame:imageSize:)`)
    /// on the global executor, keeping the image scale. A non-`.up` orientation is baked in
    /// first, since `CGImage.cropping(to:)` works in raw pixel space.
    @concurrent
    nonisolated static func render(image: UIImage, cropRect: CGRect) async -> UIImage? {
        let normalized: UIImage = if image.imageOrientation != .up, image.cgImage != nil {
            UIGraphicsImageRenderer(size: image.size, format: rendererFormat(for: image)).image { _ in
                image.draw(in: CGRect(origin: .zero, size: image.size))
            }
        } else {
            image
        }
        let scale = normalized.scale
        let pointRect = cropRect.intersection(CGRect(origin: .zero, size: normalized.size))
        let pixelRect = CGRect(
            x: pointRect.origin.x * scale,
            y: pointRect.origin.y * scale,
            width: pointRect.width * scale,
            height: pointRect.height * scale
        ).integral
        guard !pointRect.isEmpty, !pixelRect.isEmpty, let cgImage = normalized.cgImage?.cropping(to: pixelRect) else { return nil }
        return UIImage(cgImage: cgImage, scale: scale, orientation: .up)
    }

    private nonisolated static func rendererFormat(for image: UIImage) -> UIGraphicsImageRendererFormat {
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = false
        return format
    }
}
