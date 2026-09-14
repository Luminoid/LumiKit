//
//  LMKSceneUtil.swift
//  LumiKit
//
//  Scene utility for key window access.
//

import UIKit

/// Scene utility for key window access.
public enum LMKSceneUtil {
    /// Get the key window from the active foreground scene.
    public static func getKeyWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first
    }

    /// Display scale of the key window (e.g., 2.0 on iPad, 3.0 on iPhone).
    ///
    /// Read from the window's trait collection (`displayScale`), the value
    /// Apple recommends over `UIScreen.scale` now that a scene can sit on a
    /// display other than the main one (iPhone Mirroring, external displays).
    /// Falls back to `3.0` when no window is available or the trait is
    /// unspecified.
    public static var screenScale: CGFloat {
        displayScale(of: getKeyWindow()) ?? 3.0
    }

    /// Display scale from a view's trait collection, `nil` when the view is
    /// missing or the trait is unspecified (`0`).
    public static func displayScale(of view: UIView?) -> CGFloat? {
        guard let scale = view?.traitCollection.displayScale, scale > 0 else { return nil }
        return scale
    }
}
