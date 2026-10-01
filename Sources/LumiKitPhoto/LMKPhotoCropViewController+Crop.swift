//
//  LMKPhotoCropViewController+Crop.swift
//  LumiKit
//
//  The crop itself: view-to-image mapping and the off-main render.
//

import UIKit

extension LMKPhotoCropViewController {
    /// The rect of the image under `cropFrame`, in the oriented image's point space (`imageSize`
    /// units), given the image view's `imageFrame` in the same coordinates as the frame. The
    /// origin and the size are rounded to whole units on their own (rounding each edge outward
    /// would grow a square by a unit on one side), and under a locked `ratio` the height comes
    /// from the width, so a 1:1 crop is square to the unit. `nil` when nothing of the image is
    /// inside the frame.
    nonisolated static func cropRect(cropFrame: CGRect, imageFrame: CGRect, imageSize: CGSize, ratio: CGFloat? = nil) -> CGRect? {
        guard imageFrame.width > 0, imageFrame.height > 0, imageSize.width > 0, imageSize.height > 0 else { return nil }
        let scale = imageSize.width / imageFrame.width
        let inImageView = cropFrame.offsetBy(dx: -imageFrame.origin.x, dy: -imageFrame.origin.y)
        var rounded = CGRect(
            x: (inImageView.origin.x * scale).rounded(),
            y: (inImageView.origin.y * scale).rounded(),
            width: (inImageView.width * scale).rounded(),
            height: (inImageView.height * scale).rounded()
        )
        if let ratio, ratio > 0 {
            rounded.size.height = (rounded.width / ratio).rounded()
        }
        let clamped = rounded.intersection(CGRect(origin: .zero, size: imageSize))
        guard !clamped.isEmpty, clamped.width > 0, clamped.height > 0 else { return nil }
        return clamped
    }

    /// Crops `image` to `cropRect` (the oriented image's point space, from
    /// `cropRect(cropFrame:imageFrame:imageSize:ratio:)`) on the global executor, keeping the
    /// image scale and dynamic range. Only the crop is drawn: one bitmap the size of the crop,
    /// with the orientation applied by the draw, and nothing that keeps the full-size pixels
    /// alive once the source image is released.
    @concurrent
    nonisolated static func render(image: UIImage, cropRect: CGRect) async -> UIImage? {
        let pointRect = cropRect.intersection(CGRect(origin: .zero, size: image.size))
        guard !pointRect.isEmpty, pointRect.width > 0, pointRect.height > 0 else { return nil }
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = false
        format.preferredRange = image.imageRendererFormat.preferredRange
        return UIGraphicsImageRenderer(size: pointRect.size, format: format).image { _ in
            image.draw(at: CGPoint(x: -pointRect.minX, y: -pointRect.minY))
        }
    }
}
