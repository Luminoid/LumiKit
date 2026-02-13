//
//  LMKAlpha.swift
//  LumiKit
//
//  Alpha/opacity tokens.
//

import UIKit

/// Alpha/opacity tokens for the Lumi design system.
public nonisolated enum LMKAlpha {
    /// Semi-transparent overlay (0.5).
    public static let overlay: CGFloat = 0.5
    /// Dimming overlay for modal bottom sheets (0.4).
    public static let dimmingOverlay: CGFloat = 0.4
    /// Disabled state alpha (0.5).
    public static let disabled: CGFloat = 0.5
    /// Semi-transparent background (0.5).
    public static let semiTransparent: CGFloat = 0.5
    /// Strong overlay for dark backgrounds (e.g. photo overlay buttons) (0.7).
    public static let overlayStrong: CGFloat = 0.7
    /// Light mode highlight overlay (0.1).
    public static let overlayLight: CGFloat = 0.1
    /// Dark mode highlight overlay (0.2).
    public static let overlayDark: CGFloat = 0.2
    /// Medium overlay for selection highlight (0.15).
    public static let overlayMedium: CGFloat = 0.15
    /// Opaque overlay for loading/shimmer backgrounds (0.8).
    public static let overlayOpaque: CGFloat = 0.8
}
