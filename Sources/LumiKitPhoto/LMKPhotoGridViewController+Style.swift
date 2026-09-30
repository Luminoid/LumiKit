//
//  LMKPhotoGridViewController+Style.swift
//  LumiKit
//
//  Style, strings, and theme slot of the photo grid.
//

import LumiKitUI
import UIKit

public extension LMKPhotoGridViewController {
    /// Appearance of the grid: cell spacing and corners, the placeholder, the floating toolbar,
    /// the LIVE badge, and the multi-selection checkmark. Every field is optional; `nil`
    /// resolves from `theme.photoGrid`, then the built-in defaults.
    nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// Behind the grid; `nil` = `backgroundPrimary`.
        public var backgroundColor: UIColor?
        /// Gap between cells; `nil` = 2.
        public var spacing: CGFloat?
        /// Smallest cell side the pinch may reach; `nil` = 36.
        public var minimumCellSize: CGFloat?
        /// Most columns the pinch may reach; `nil` = 10.
        public var maximumColumnCount: Int?
        /// Shown while a cell's image loads; `nil` = `backgroundSecondary`.
        public var placeholderColor: UIColor?
        /// Cell corners; `nil` = square.
        public var cellCorners: LMKCornerStyle?
        /// Floating toolbar (glass on iOS 26, chrome material before; `large` corners).
        public var toolbar: LMKSurfaceStyle
        /// Layered on the sort and content-mode buttons (ghost, `textPrimary`).
        public var toolbarButton: LMKButton.Style
        /// Gap between the toolbar buttons; `nil` = `spacing.medium`.
        public var toolbarSpacing: CGFloat?
        /// Toolbar distance from the bottom safe area; `nil` = `spacing.medium`.
        public var toolbarBottomMargin: CGFloat?
        /// Whether the toolbar is installed; `nil` = true.
        public var showsToolbar: Bool?
        /// LIVE badge on Live Photo cells (black at `alpha.xl`, circle).
        public var liveBadge: LMKSurfaceStyle
        /// Side of the LIVE badge and the selection checkmark; `nil` = 22.
        public var badgeSize: CGFloat?
        /// Glyph color of the LIVE badge and the checkmark; `nil` = white.
        public var badgeTint: UIColor?
        /// Selected cells: checkmark fill and overlay tint; `nil` = `primary`.
        public var selectionTint: UIColor?
        /// Overlay alpha on selected cells; `nil` = `alpha.small`.
        public var selectionOverlayAlpha: CGFloat?
        /// Pinch scale change that moves the column count by one; `nil` = 0.3.
        public var pinchThreshold: CGFloat?
        /// Impact haptics on column, sort, and mode changes; `nil` = enabled.
        public var haptics: Bool?
        /// The iOS 26 scroll edge effect at the grid's top, under the navigation bar; `nil` = shown.
        /// No effect before 26.
        public var showsScrollEdgeEffects: Bool?
        /// The iOS 26 scroll edge effect at the grid's bottom: a band that fades the last row
        /// behind the toolbar; `nil` = hidden, so photos run to the edge under the floating
        /// toolbar. No effect before 26.
        public var showsBottomEdgeEffect: Bool?
        /// How far the grid leans into a pinch before the column count steps, as a fraction of
        /// the pinch (0 turns the feedback off); `nil` = 0.12.
        public var pinchFeedback: CGFloat?
        /// Brightness of a photo while it is pressed; `nil` = `alpha.xl`.
        public var pressedAlpha: CGFloat?

        public init(
            backgroundColor: UIColor? = nil,
            spacing: CGFloat? = nil,
            minimumCellSize: CGFloat? = nil,
            maximumColumnCount: Int? = nil,
            placeholderColor: UIColor? = nil,
            cellCorners: LMKCornerStyle? = nil,
            toolbar: LMKSurfaceStyle = LMKSurfaceStyle(),
            toolbarButton: LMKButton.Style = LMKButton.Style(),
            toolbarSpacing: CGFloat? = nil,
            toolbarBottomMargin: CGFloat? = nil,
            showsToolbar: Bool? = nil,
            liveBadge: LMKSurfaceStyle = LMKSurfaceStyle(),
            badgeSize: CGFloat? = nil,
            badgeTint: UIColor? = nil,
            selectionTint: UIColor? = nil,
            selectionOverlayAlpha: CGFloat? = nil,
            pinchThreshold: CGFloat? = nil,
            haptics: Bool? = nil,
            showsScrollEdgeEffects: Bool? = nil,
            showsBottomEdgeEffect: Bool? = nil,
            pinchFeedback: CGFloat? = nil,
            pressedAlpha: CGFloat? = nil
        ) {
            self.backgroundColor = backgroundColor
            self.spacing = spacing
            self.minimumCellSize = minimumCellSize
            self.maximumColumnCount = maximumColumnCount
            self.placeholderColor = placeholderColor
            self.cellCorners = cellCorners
            self.toolbar = toolbar
            self.toolbarButton = toolbarButton
            self.toolbarSpacing = toolbarSpacing
            self.toolbarBottomMargin = toolbarBottomMargin
            self.showsToolbar = showsToolbar
            self.liveBadge = liveBadge
            self.badgeSize = badgeSize
            self.badgeTint = badgeTint
            self.selectionTint = selectionTint
            self.selectionOverlayAlpha = selectionOverlayAlpha
            self.pinchThreshold = pinchThreshold
            self.haptics = haptics
            self.showsScrollEdgeEffects = showsScrollEdgeEffects
            self.showsBottomEdgeEffect = showsBottomEdgeEffect
            self.pinchFeedback = pinchFeedback
            self.pressedAlpha = pressedAlpha
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                backgroundColor: other.backgroundColor ?? backgroundColor,
                spacing: other.spacing ?? spacing,
                minimumCellSize: other.minimumCellSize ?? minimumCellSize,
                maximumColumnCount: other.maximumColumnCount ?? maximumColumnCount,
                placeholderColor: other.placeholderColor ?? placeholderColor,
                cellCorners: other.cellCorners ?? cellCorners,
                toolbar: toolbar.merging(other.toolbar),
                toolbarButton: toolbarButton.merging(other.toolbarButton),
                toolbarSpacing: other.toolbarSpacing ?? toolbarSpacing,
                toolbarBottomMargin: other.toolbarBottomMargin ?? toolbarBottomMargin,
                showsToolbar: other.showsToolbar ?? showsToolbar,
                liveBadge: liveBadge.merging(other.liveBadge),
                badgeSize: other.badgeSize ?? badgeSize,
                badgeTint: other.badgeTint ?? badgeTint,
                selectionTint: other.selectionTint ?? selectionTint,
                selectionOverlayAlpha: other.selectionOverlayAlpha ?? selectionOverlayAlpha,
                pinchThreshold: other.pinchThreshold ?? pinchThreshold,
                haptics: other.haptics ?? haptics,
                showsScrollEdgeEffects: other.showsScrollEdgeEffects ?? showsScrollEdgeEffects,
                showsBottomEdgeEffect: other.showsBottomEdgeEffect ?? showsBottomEdgeEffect,
                pinchFeedback: other.pinchFeedback ?? pinchFeedback,
                pressedAlpha: other.pressedAlpha ?? pressedAlpha
            )
        }
    }

    // MARK: - Strings

    /// User-visible strings of the grid, defaulting to the package's localized values.
    nonisolated struct Strings: Sendable, Equatable {
        public var emptyText: String
        public var emptyIcon: String?
        public var sortAscendingLabel: String
        public var sortDescendingLabel: String
        public var aspectFitLabel: String
        public var aspectFillLabel: String
        /// Accessibility label of a Live Photo badge.
        public var livePhotoAccessibilityLabel: String
        /// Accessibility label of a cell, with two `%lld` slots (position, count).
        public var photoAccessibilityLabelFormat: String

        public init(
            emptyText: String = LMKLocalized("photoGrid.empty"),
            emptyIcon: String? = "photo.on.rectangle.angled",
            sortAscendingLabel: String = LMKLocalized("photoGrid.sortAscending"),
            sortDescendingLabel: String = LMKLocalized("photoGrid.sortDescending"),
            aspectFitLabel: String = LMKLocalized("photoGrid.aspectFit"),
            aspectFillLabel: String = LMKLocalized("photoGrid.aspectFill"),
            livePhotoAccessibilityLabel: String = LMKLocalized("photoGrid.livePhoto.accessibilityLabel"),
            photoAccessibilityLabelFormat: String = LMKLocalized("photoGrid.photo.accessibilityLabel")
        ) {
            self.emptyText = emptyText
            self.emptyIcon = emptyIcon
            self.sortAscendingLabel = sortAscendingLabel
            self.sortDescendingLabel = sortDescendingLabel
            self.aspectFitLabel = aspectFitLabel
            self.aspectFillLabel = aspectFillLabel
            self.livePhotoAccessibilityLabel = livePhotoAccessibilityLabel
            self.photoAccessibilityLabelFormat = photoAccessibilityLabelFormat
        }
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKPhotoGridViewController`.
    var photoGrid: LMKPhotoGridViewController.Style {
        get { self[LMKPhotoGridViewController.Style.self] }
        set { self[LMKPhotoGridViewController.Style.self] = newValue }
    }
}

// MARK: - Resolution

extension LMKPhotoGridViewController.Style {
    static let defaultSpacing: CGFloat = 2
    static let defaultMinimumCellSize: CGFloat = 36
    static let defaultMaximumColumnCount = 10
    static let defaultBadgeSize: CGFloat = 22
    static let defaultPinchThreshold: CGFloat = 0.3
    static let defaultPinchFeedback: CGFloat = 0.12

    var cellSpacing: CGFloat { max(0, spacing ?? Self.defaultSpacing) }
    var minimumCell: CGFloat { max(1, minimumCellSize ?? Self.defaultMinimumCellSize) }
    var columnCap: Int { max(1, maximumColumnCount ?? Self.defaultMaximumColumnCount) }
    var badgeSide: CGFloat { max(1, badgeSize ?? Self.defaultBadgeSize) }
    var pinchStep: CGFloat { max(0.05, pinchThreshold ?? Self.defaultPinchThreshold) }
    var pinchLean: CGFloat { min(max(0, pinchFeedback ?? Self.defaultPinchFeedback), 1) }
    var playsHaptics: Bool { haptics ?? true }
    var placeholder: UIColor { placeholderColor ?? LMKColor.backgroundSecondary }
    var badgeGlyphTint: UIColor { badgeTint ?? LMKPhotoPalette.foreground }
    var selectionColor: UIColor { selectionTint ?? LMKColor.primary }
}
