//
//  LMKPhotoBrowserConfig.swift
//  LumiKit
//
//  Shared configuration constants for the photo browser and crop view controller.
//

import UIKit

/// Shared configuration for the photo browser.
public enum LMKPhotoBrowserConfig {
    /// Inter-page gap between photos. The spacing is included within each cell
    /// (cell width = screen width + this value) rather than as layout-level
    /// `minimumLineSpacing`, because `UICollectionViewFlowLayout` doesn't add
    /// spacing after the last cell — causing an accumulated offset bug on the
    /// final page.
    public static var interPageSpacing: CGFloat { LMKSpacing.large }
    /// Button size for Mac Catalyst controls.
    public static let macButtonSize: CGFloat = 48
    /// Maximum zoom scale for photo preview.
    public static let maximumZoomScale: CGFloat = 3.0
    /// Minimum zoom scale for photo preview.
    public static let minimumZoomScale: CGFloat = 1.0
    /// Minimum vertical velocity (pt/s) to trigger dismiss.
    public static let dismissVelocityThreshold: CGFloat = 700

    /// Platform-aware button size for overlay controls (dismiss, action, confirm).
    public static var overlayButtonSize: CGFloat {
        #if targetEnvironment(macCatalyst)
            macButtonSize
        #else
            LMKLayout.minimumTouchTarget
        #endif
    }

    /// Create a circular overlay button for photo browser/crop controls.
    /// - Parameters:
    ///   - systemName: SF Symbol name for the button icon.
    ///   - target: Target for the button action.
    ///   - action: Selector to invoke on tap.
    /// - Returns: A configured `UIButton` with photo overlay styling.
    public static func makeOverlayButton(systemName: String, target: Any?, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: systemName), for: .normal)
        button.tintColor = LMKColor.white
        button.backgroundColor = LMKColor.photoBrowserBackground.withAlphaComponent(LMKAlpha.overlay)
        button.layer.cornerRadius = LMKCornerRadius.xl
        button.addTarget(target, action: action, for: .touchUpInside)
        return button
    }
}
