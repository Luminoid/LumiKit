//
//  LMKLayout.swift
//  LumiKit
//
//  General layout dimension tokens.
//

import UIKit

/// General layout dimension tokens for the Lumi design system.
public enum LMKLayout {
    /// Minimum touch target size (44pt per HIG).
    public static let minimumTouchTarget: CGFloat = 44
    /// Medium icon size — 24pt.
    public static let iconMedium: CGFloat = 24
    /// Small icon size — 20pt.
    public static let iconSmall: CGFloat = 20
    /// Extra small icon size (chevrons, compact indicators) — 16pt.
    public static let iconExtraSmall: CGFloat = 16
    /// Pull-to-refresh threshold; compact preview height — 80pt.
    public static let pullThreshold: CGFloat = 80
    /// Minimum cell height; name limit — 100pt.
    public static let cellHeightMin: CGFloat = 100
}
