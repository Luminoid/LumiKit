//
//  LMKStatus.swift
//  LumiKit
//
//  The semantic status shared by toasts, banners, status labels, and validation.
//

import UIKit

/// A semantic status: the symbol, color, and haptic that toasts, banners, and
/// status readouts derive from it. `.neutral` carries no symbol.
public nonisolated enum LMKStatus: Sendable, Hashable, CaseIterable {
    case success
    case warning
    case error
    case info
    case neutral

    /// The SF Symbol for the status; `nil` for `.neutral`.
    public var systemImageName: String? {
        switch self {
        case .error: "exclamationmark.circle.fill"
        case .success: "checkmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .info: "info.circle.fill"
        case .neutral: nil
        }
    }

    /// The status color token (`.neutral` uses `textSecondary`).
    public var color: UIColor {
        switch self {
        case .error: LMKColor.error
        case .success: LMKColor.success
        case .warning: LMKColor.warning
        case .info: LMKColor.info
        case .neutral: LMKColor.textSecondary
        }
    }

    /// The notification haptic for the status (a light tap for `.info`, none for `.neutral`).
    @MainActor
    public func playHaptic() {
        switch self {
        case .error: LMKHaptics.error()
        case .success: LMKHaptics.success()
        case .warning: LMKHaptics.warning()
        case .info: LMKHaptics.light()
        case .neutral: break
        }
    }
}
