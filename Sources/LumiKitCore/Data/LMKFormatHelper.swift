//
//  LMKFormatHelper.swift
//  LumiKit
//
//  Shared formatting utilities for consistent display.
//

import Foundation

/// Shared formatting helpers for progress, percentages, and similar values.
public enum LMKFormatHelper {
    /// Format string for progress percentage display (e.g. "75%").
    public static let progressPercentFormat = "%.0f%%"

    /// Formats a progress value (0.0–1.0) as a percentage string (e.g. "75%").
    public static func progressPercent(_ progress: Float) -> String {
        String(format: progressPercentFormat, progress * 100)
    }
}
