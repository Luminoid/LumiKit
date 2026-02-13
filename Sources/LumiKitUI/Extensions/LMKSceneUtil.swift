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
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first
    }
}
