//
//  LMKLayoutTheme.swift
//  LumiKit
//
//  Layout dimension configuration: touch targets, icon frames, SF Symbol
//  point sizes, row heights, readable width. Proxied by `LMKLayout`.
//

import UIKit

/// Layout dimension configuration. Negative values are clamped to 0.
public nonisolated struct LMKLayoutTheme: Sendable, Equatable {
    // MARK: Touch targets and icon frames

    /// HIG minimum hit target (default 44).
    public var minimumTouchTarget: CGFloat
    /// Icon frame sizes (image view side), not glyph point sizes.
    public var iconMedium: CGFloat
    public var iconLarge: CGFloat
    public var iconSmall: CGFloat
    public var iconExtraSmall: CGFloat
    /// Tinted circle behind a list-row symbol (default 36).
    public var iconCircle: CGFloat

    // MARK: SF Symbol point sizes (glyph scale, distinct from icon frames)

    /// Sub-node glyphs, grid badge fallbacks (default 9).
    public var symbolMicro: CGFloat
    /// Pill glyphs, month chevrons (default 11).
    public var symbolBadge: CGFloat
    /// Chevrons, timeline nodes (default 13).
    public var symbolAccessory: CGFloat
    /// Inline row glyphs, map pins (default 14).
    public var symbolInline: CGFloat
    /// Standard row icon (default 16).
    public var symbolRow: CGFloat
    /// Section headers, thumbnail placeholders (default 18).
    public var symbolProminent: CGFloat
    /// Selection checkmarks (default 20).
    public var symbolAction: CGFloat
    /// Composer glyphs, large placeholders (default 24).
    public var symbolLarge: CGFloat
    /// List-cell placeholders (default 26).
    public var symbolPlaceholder: CGFloat
    /// Grid tile and resource card placeholders (default 40).
    public var symbolIllustration: CGFloat
    /// Photo button placeholders (default 48).
    public var symbolHero: CGFloat

    // MARK: Row heights

    /// Single-line rows (default 44).
    public var rowHeightCompact: CGFloat
    /// Standard two-line rows (default 60).
    public var rowHeight: CGFloat
    /// Rows with a thumbnail or three lines (default 72).
    public var rowHeightComfortable: CGFloat
    /// `estimatedRowHeight` for self-sizing lists (default 64).
    public var rowHeightEstimated: CGFloat
    /// Minimum height of a content cell (default 100).
    public var cellHeightMin: CGFloat

    // MARK: Readable width

    /// Maximum content width on wide canvases (iPad, Mac); default 700.
    public var readableContentMaxWidth: CGFloat

    // MARK: Component metrics

    /// Pull distance that triggers a refresh control (default 80).
    public var pullThreshold: CGFloat

    public init(
        minimumTouchTarget: CGFloat = 44,
        iconMedium: CGFloat = 24,
        iconLarge: CGFloat = 28,
        iconSmall: CGFloat = 20,
        iconExtraSmall: CGFloat = 16,
        iconCircle: CGFloat = 36,
        symbolMicro: CGFloat = 9,
        symbolBadge: CGFloat = 11,
        symbolAccessory: CGFloat = 13,
        symbolInline: CGFloat = 14,
        symbolRow: CGFloat = 16,
        symbolProminent: CGFloat = 18,
        symbolAction: CGFloat = 20,
        symbolLarge: CGFloat = 24,
        symbolPlaceholder: CGFloat = 26,
        symbolIllustration: CGFloat = 40,
        symbolHero: CGFloat = 48,
        rowHeightCompact: CGFloat = 44,
        rowHeight: CGFloat = 60,
        rowHeightComfortable: CGFloat = 72,
        rowHeightEstimated: CGFloat = 64,
        cellHeightMin: CGFloat = 100,
        readableContentMaxWidth: CGFloat = 700,
        pullThreshold: CGFloat = 80
    ) {
        self.minimumTouchTarget = max(0, minimumTouchTarget)
        self.iconMedium = max(0, iconMedium)
        self.iconLarge = max(0, iconLarge)
        self.iconSmall = max(0, iconSmall)
        self.iconExtraSmall = max(0, iconExtraSmall)
        self.iconCircle = max(0, iconCircle)
        self.symbolMicro = max(0, symbolMicro)
        self.symbolBadge = max(0, symbolBadge)
        self.symbolAccessory = max(0, symbolAccessory)
        self.symbolInline = max(0, symbolInline)
        self.symbolRow = max(0, symbolRow)
        self.symbolProminent = max(0, symbolProminent)
        self.symbolAction = max(0, symbolAction)
        self.symbolLarge = max(0, symbolLarge)
        self.symbolPlaceholder = max(0, symbolPlaceholder)
        self.symbolIllustration = max(0, symbolIllustration)
        self.symbolHero = max(0, symbolHero)
        self.rowHeightCompact = max(0, rowHeightCompact)
        self.rowHeight = max(0, rowHeight)
        self.rowHeightComfortable = max(0, rowHeightComfortable)
        self.rowHeightEstimated = max(0, rowHeightEstimated)
        self.cellHeightMin = max(0, cellHeightMin)
        self.readableContentMaxWidth = max(0, readableContentMaxWidth)
        self.pullThreshold = max(0, pullThreshold)
    }
}
