//
//  LMKShareService.swift
//  LumiKit
//
//  Thin wrapper around UIActivityViewController for sharing images and files.
//

import LumiKitCore
import UIKit

/// Wrapper for presenting the system share sheet.
///
/// Share images:
/// ```swift
/// LMKShareService.shareImage(image, from: self, sourceView: button)
/// ```
///
/// Share files (temp file is cleaned up after sharing):
/// ```swift
/// LMKShareService.shareFile(at: fileURL, from: self)
/// ```
public enum LMKShareService {
    // MARK: - Share Image

    /// Share an image via the system activity controller.
    /// - Parameters:
    ///   - image: Image to share.
    ///   - viewController: Presenting view controller.
    ///   - sourceView: Optional source view for iPad popover positioning.
    ///   - sourceBarButtonItem: Optional bar button item for popover anchor.
    public static func shareImage(
        _ image: UIImage,
        from viewController: UIViewController,
        sourceView: UIView? = nil,
        sourceBarButtonItem: UIBarButtonItem? = nil
    ) {
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        configurePopover(activityVC, viewController: viewController, sourceView: sourceView, sourceBarButtonItem: sourceBarButtonItem)

        activityVC.completionWithItemsHandler = { activityType, completed, _, error in
            if let error {
                LMKLogger.error("Error sharing image", error: error, category: .general)
            } else if completed {
                LMKLogger.info("Image shared successfully via \(activityType?.rawValue ?? "unknown")", category: .general)
            }
        }

        viewController.present(activityVC, animated: true)
    }

    // MARK: - Share File

    /// Share a file via the system activity controller. The file at `url` is deleted after sharing completes.
    /// - Parameters:
    ///   - url: File URL to share.
    ///   - viewController: Presenting view controller.
    ///   - sourceView: Optional source view for iPad popover positioning.
    ///   - sourceBarButtonItem: Optional bar button item for popover anchor.
    public static func shareFile(
        at url: URL,
        from viewController: UIViewController,
        sourceView: UIView? = nil,
        sourceBarButtonItem: UIBarButtonItem? = nil
    ) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        configurePopover(activityVC, viewController: viewController, sourceView: sourceView, sourceBarButtonItem: sourceBarButtonItem)

        activityVC.completionWithItemsHandler = { activityType, completed, _, error in
            // Clean up temp file after sharing
            try? FileManager.default.removeItem(at: url)

            if let error {
                LMKLogger.error("Error sharing file", error: error, category: .general)
            } else if completed {
                LMKLogger.info("File shared successfully via \(activityType?.rawValue ?? "unknown")", category: .general)
            }
        }

        viewController.present(activityVC, animated: true)
    }

    // MARK: - Helpers

    private static func configurePopover(
        _ activityVC: UIActivityViewController,
        viewController: UIViewController,
        sourceView: UIView?,
        sourceBarButtonItem: UIBarButtonItem?
    ) {
        guard let popover = activityVC.popoverPresentationController else { return }

        if let sourceBarButtonItem {
            popover.barButtonItem = sourceBarButtonItem
        } else if let sourceView {
            popover.sourceView = sourceView
            popover.sourceRect = sourceView.bounds
        } else {
            popover.sourceView = viewController.view
            popover.sourceRect = viewController.lmk_centeredPopoverSourceRect
            popover.permittedArrowDirections = []
        }
    }
}
