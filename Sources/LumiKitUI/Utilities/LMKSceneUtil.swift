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

    /// Current screen scale factor (e.g., 2.0 on iPad, 3.0 on iPhone).
    /// Falls back to `3.0` when no window is available.
    public static var screenScale: CGFloat {
        getKeyWindow()?.screen.scale ?? 3.0
    }
}
