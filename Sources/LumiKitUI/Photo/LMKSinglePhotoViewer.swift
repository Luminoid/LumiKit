//
//  LMKSinglePhotoViewer.swift
//  LumiKit
//
//  Full-screen viewer for a single image.
//

import UIKit

/// Presents one image full-screen in `LMKPhotoBrowserViewController`. Retain it
/// while the browser is up (the browser's data source / delegate are weak). The
/// optional `onAction` backs the browser's "…" action button (e.g. replace/remove).
///
/// ```swift
/// viewer = LMKSinglePhotoViewer(image: cover, onAction: { [weak self] in self?.presentCoverActions() })
/// viewer?.present(from: self)
/// ```
public final class LMKSinglePhotoViewer: NSObject {
    // MARK: - Properties

    private let image: UIImage
    private let subtitle: String?
    private let onAction: (() -> Void)?
    private var browser: LMKPhotoBrowserViewController?

    // MARK: - Init

    /// - Parameters:
    ///   - image: The image to display.
    ///   - subtitle: Optional subtitle under the browser's counter.
    ///   - onAction: Backs the browser's action ("…") button; the button is inert when `nil`.
    public init(image: UIImage, subtitle: String? = nil, onAction: (() -> Void)? = nil) {
        self.image = image
        self.subtitle = subtitle
        self.onAction = onAction
        super.init()
    }

    // MARK: - Presentation

    /// Presents the full-screen browser from the host.
    public func present(from host: UIViewController) {
        let browser = LMKPhotoBrowserViewController(initialIndex: 0)
        browser.dataSource = self
        browser.delegate = self
        browser.modalPresentationStyle = .fullScreen
        self.browser = browser
        host.present(browser, animated: true)
    }
}

// MARK: - LMKPhotoBrowserDataSource

extension LMKSinglePhotoViewer: LMKPhotoBrowserDataSource {
    public var numberOfPhotos: Int { 1 }

    public func photo(at _: Int) -> UIImage? {
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
    }
}
