//
//  LMKShare.swift
//  LumiKit
//
//  The system share sheet for images, files, text, and links, with popover anchoring
//  and a completion on every path.
//

import LumiKitCore
import UIKit

/// Result of a share operation.
public enum LMKShareResult: Sendable {
    /// The user completed the share via the given activity type.
    case completed(UIActivity.ActivityType?)
    /// The user cancelled without sharing.
    case cancelled
    /// The share failed with an error.
    case failed(any Error)
}

/// Presents the system share sheet.
///
/// ```swift
/// LMKShare.image(image, from: self, sourceView: button)
/// LMKShare.text("Hello", from: self)
/// LMKShare.present([.text(caption), .image(photo)], from: self, anchor: .barButtonItem(item)) { result in }
/// ```
public enum LMKShare {
    // MARK: - Types

    /// Something to share.
    public enum Item {
        case image(UIImage)
        /// A file URL; `deletesAfterShare` removes it once the sheet is dismissed (temporary exports).
        case file(URL, deletesAfterShare: Bool = false)
        case text(String)
        case url(URL)

        var activityItem: Any {
            switch self {
            case let .image(image): image
            case let .file(url, _): url
            case let .text(text): text
            case let .url(url): url
            }
        }

        var deletableURL: URL? {
            if case let .file(url, deletesAfterShare) = self, deletesAfterShare { return url }
            return nil
        }
    }

    /// Where the sheet's popover points on iPad and Mac.
    public enum Anchor {
        /// Centered over the host with no arrow.
        case centered
        case view(UIView)
        case barButtonItem(UIBarButtonItem)
    }

    // MARK: - Present

    /// Presents the share sheet for `items`.
    /// - Parameters:
    ///   - items: What to share, in order.
    ///   - host: The presenting view controller.
    ///   - anchor: Popover anchor on iPad and Mac.
    ///   - applicationActivities: App-provided activities appended to the system ones.
    ///   - completion: Called once the sheet is dismissed, with the outcome.
    /// - Returns: The presented controller, or `nil` when a `.file` item does not exist.
    @discardableResult
    public static func present(
        _ items: [Item],
        from host: UIViewController,
        anchor: Anchor = .centered,
        applicationActivities: [UIActivity]? = nil,
        completion: ((LMKShareResult) -> Void)? = nil
    ) -> UIActivityViewController? {
        for case let .file(url, _) in items where !FileManager.default.fileExists(atPath: url.path) {
            LMKLogger.error("LMKShare: file does not exist at \(url.path)", category: .general)
            completion?(.failed(CocoaError(.fileNoSuchFile, userInfo: [NSFilePathErrorKey: url.path])))
            return nil
        }
        let controller = UIActivityViewController(activityItems: items.map(\.activityItem), applicationActivities: applicationActivities)
        configurePopover(controller, host: host, anchor: anchor)

        let deletableURLs = items.compactMap(\.deletableURL)
        controller.completionWithItemsHandler = { activityType, completed, _, error in
            for url in deletableURLs {
                try? FileManager.default.removeItem(at: url)
            }
            if let error {
                LMKLogger.error("LMKShare: share failed", error: error, category: .general)
                completion?(.failed(error))
            } else if completed {
                LMKLogger.info("LMKShare: shared via \(activityType?.rawValue ?? "unknown")", category: .general)
                completion?(.completed(activityType))
            } else {
                completion?(.cancelled)
            }
        }

        host.present(controller, animated: true)
        return controller
    }

    // MARK: - Conveniences

    /// Shares an image.
    public static func image(
        _ image: UIImage,
        from host: UIViewController,
        sourceView: UIView? = nil,
        sourceBarButtonItem: UIBarButtonItem? = nil,
        completion: ((LMKShareResult) -> Void)? = nil
    ) {
        present([.image(image)], from: host, anchor: anchor(sourceView: sourceView, sourceBarButtonItem: sourceBarButtonItem), completion: completion)
    }

    /// Shares a file. The file is deleted after the sheet is dismissed unless `deletesAfterShare` is `false`.
    public static func file(
        at url: URL,
        from host: UIViewController,
        sourceView: UIView? = nil,
        sourceBarButtonItem: UIBarButtonItem? = nil,
        deletesAfterShare: Bool = true,
        completion: ((LMKShareResult) -> Void)? = nil
    ) {
        present(
            [.file(url, deletesAfterShare: deletesAfterShare)],
            from: host,
            anchor: anchor(sourceView: sourceView, sourceBarButtonItem: sourceBarButtonItem),
            completion: completion
        )
    }

    /// Shares plain text.
    public static func text(
        _ text: String,
        from host: UIViewController,
        sourceView: UIView? = nil,
        sourceBarButtonItem: UIBarButtonItem? = nil,
        completion: ((LMKShareResult) -> Void)? = nil
    ) {
        present([.text(text)], from: host, anchor: anchor(sourceView: sourceView, sourceBarButtonItem: sourceBarButtonItem), completion: completion)
    }

    /// Shares a link.
    public static func url(
        _ url: URL,
        from host: UIViewController,
        sourceView: UIView? = nil,
        sourceBarButtonItem: UIBarButtonItem? = nil,
        completion: ((LMKShareResult) -> Void)? = nil
    ) {
        present([.url(url)], from: host, anchor: anchor(sourceView: sourceView, sourceBarButtonItem: sourceBarButtonItem), completion: completion)
    }

    // MARK: - Helpers

    private static func anchor(sourceView: UIView?, sourceBarButtonItem: UIBarButtonItem?) -> Anchor {
        if let sourceBarButtonItem { return .barButtonItem(sourceBarButtonItem) }
        if let sourceView { return .view(sourceView) }
        return .centered
    }

    private static func configurePopover(_ controller: UIActivityViewController, host: UIViewController, anchor: Anchor) {
        guard let popover = controller.popoverPresentationController else { return }
        switch anchor {
        case let .barButtonItem(item):
            popover.barButtonItem = item
        case let .view(view):
            popover.sourceView = view
            popover.sourceRect = view.bounds
        case .centered:
            popover.sourceView = host.view
            popover.sourceRect = host.lmk_centeredPopoverSourceRect
            popover.permittedArrowDirections = []
        }
    }
}
