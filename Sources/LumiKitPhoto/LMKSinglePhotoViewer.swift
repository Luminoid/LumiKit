//
//  LMKSinglePhotoViewer.swift
//  LumiKit
//
//  Full-screen viewer for a single image.
//

import LumiKitUI
import UIKit

/// Presents one image full-screen in `LMKPhotoBrowserViewController`. Retain it while the
/// browser is up (the browser's data source and delegate are weak). The optional `onAction`
/// backs the browser's action button (replace, remove).
///
/// ```swift
/// viewer = LMKSinglePhotoViewer(image: cover, onAction: { [weak self] in self?.presentCoverActions() })
/// viewer?.zoomSourceView = { [weak self] in self?.coverImageView }
/// viewer?.present(from: self)
/// ```
public final class LMKSinglePhotoViewer: NSObject {
    // MARK: - Properties

    private let image: UIImage
    private let subtitle: String?
    private let actionIconSystemName: String
    private let onAction: (() -> Void)?
    private var browser: LMKPhotoBrowserViewController?

    /// Strings forwarded to the browser.
    public var browserStrings = LMKPhotoBrowserViewController.Strings()
    /// Style forwarded to the browser; `nil` leaves `theme.photoBrowser`.
    public var browserStyle: LMKPhotoBrowserViewController.Style?
    /// The thumbnail the photo zooms out of and back into.
    public var zoomSourceView: (() -> UIView?)?
    /// Called when the browser is dismissed.
    public var onDismiss: (() -> Void)?

    // MARK: - Init

    /// - Parameters:
    ///   - image: The image to display.
    ///   - subtitle: Optional subtitle under the browser's counter.
    ///   - actionIconSystemName: SF Symbol for the action button. The default "…" suits a menu;
    ///     pass e.g. "trash" when the sole action is removal.
    ///   - onAction: Backs the browser's action button; the button is hidden when `nil`.
    public init(
        image: UIImage,
        subtitle: String? = nil,
        actionIconSystemName: String = "ellipsis",
        onAction: (() -> Void)? = nil
    ) {
        self.image = image
        self.subtitle = subtitle
        self.actionIconSystemName = actionIconSystemName
        self.onAction = onAction
        super.init()
    }

    // MARK: - Presentation

    /// Presents the full-screen browser from the host.
    public func present(from host: UIViewController) {
        let browser = LMKPhotoBrowserViewController(initialIndex: 0, style: browserStyle ?? LMKPhotoBrowserViewController.Style())
        browser.dataSource = self
        browser.delegate = self
        browser.strings = browserStrings
        browser.showsActionButton = onAction != nil
        browser.actionButtonSystemImageName = actionIconSystemName
        if let zoomSourceView {
            browser.zoomSourceView = { _ in zoomSourceView() }
        }
        self.browser = browser
        host.present(browser, animated: true)
    }

    /// Dismisses the browser if it is up.
    public func dismiss(animated: Bool) {
        browser?.dismiss(animated: animated)
        browser = nil
    }
}

// MARK: - LMKPhotoBrowserDataSource

extension LMKSinglePhotoViewer: LMKPhotoBrowserDataSource {
    public var numberOfPhotos: Int { 1 }

    /// The image is held decoded in memory, so the async requirement is satisfied by returning
    /// immediately.
    public func photo(at _: Int) async -> UIImage? {
        image
    }

    public func photoDate(at _: Int) -> Date? {
        nil
    }

    public func photoSubtitle(at _: Int) -> String? {
        subtitle
    }
}

// MARK: - LMKPhotoBrowserDelegate

extension LMKSinglePhotoViewer: LMKPhotoBrowserDelegate {
    public func photoBrowser(_: LMKPhotoBrowserViewController, didRequestActionAt _: Int) {
        onAction?()
    }

    public func photoBrowserDidDismiss(_: LMKPhotoBrowserViewController) {
        browser = nil
        onDismiss?()
    }
}
