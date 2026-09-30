//
//  LMKPhotoCropViewController+Style.swift
//  LumiKit
//
//  Style, strings, theme slot, and the fixed metrics of the crop editor.
//

import LumiKitUI
import UIKit

public extension LMKPhotoCropViewController {
    /// Appearance of the crop editor: the stage and dimming, the crop frame border, the
    /// handles, the rule-of-thirds grid, the aspect ratio control, and the overlay buttons.
    /// Every field is optional; `nil` resolves from `theme.photoCrop`, then the built-in
    /// defaults (a near-black stage with white chrome).
    nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// Stage behind the image; `nil` = near-black.
        public var backgroundColor: UIColor?
        /// Buttons, handles, frame border, grid; `nil` = white.
        public var chromeTint: UIColor?
        /// Dimming over the image outside the crop frame; `nil` = the stage color.
        public var dimmingColor: UIColor?
        /// Dimming alpha; `nil` = `alpha.large`.
        public var dimmingAlpha: CGFloat?
        /// Crop frame border (chrome tint, 2pt).
        public var cropFrameBorder: LMKBorderStyle?
        /// Handle diameter; `nil` = 18.
        public var handleSize: CGFloat?
        /// Handle color; `nil` = chrome tint.
        public var handleColor: UIColor?
        /// Square hit area around a handle; `nil` = handle size plus `spacing.medium`.
        public var handleHitSize: CGFloat?
        /// Whether the rule-of-thirds grid draws; `nil` = true.
        public var showsGrid: Bool?
        /// Grid line color; `nil` = chrome tint.
        public var gridColor: UIColor?
        /// Grid line alpha; `nil` = `alpha.large`.
        public var gridAlpha: CGFloat?
        /// Grid line width; `nil` = one hairline.
        public var gridLineWidth: CGFloat?
        /// Grid lines per axis; `nil` = 2 (rule of thirds).
        public var gridLineCount: Int?
        /// Layered on the aspect ratio control (dark stage at `alpha.xl`, chrome indicator).
        public var aspectControl: LMKSegmentedControl.Style
        /// Layered on the cancel and done buttons (a circle of the stage color at `alpha.large`).
        public var overlayButton: LMKButton.Style
        /// Side of the overlay buttons; `nil` = `minimumTouchTarget` (48 under Mac Catalyst).
        public var overlayButtonSize: CGFloat?
        /// Padding between the image, the crop frame, and the edges; `nil` = `spacing.xl`.
        public var contentInset: CGFloat?
        /// Smallest crop frame side; `nil` = `minimumTouchTarget`.
        public var minimumCropSize: CGFloat?
        /// Pinch zoom ceiling on the image; `nil` = 3.
        public var maximumZoomScale: CGFloat?
        /// iOS 26: asks the scene to lock its interface orientation while cropping; `nil` = true.
        public var locksOrientation: Bool?
        /// Impact and selection haptics; `nil` = enabled.
        public var haptics: Bool?

        public init(
            backgroundColor: UIColor? = nil,
            chromeTint: UIColor? = nil,
            dimmingColor: UIColor? = nil,
            dimmingAlpha: CGFloat? = nil,
            cropFrameBorder: LMKBorderStyle? = nil,
            handleSize: CGFloat? = nil,
            handleColor: UIColor? = nil,
            handleHitSize: CGFloat? = nil,
            showsGrid: Bool? = nil,
            gridColor: UIColor? = nil,
            gridAlpha: CGFloat? = nil,
            gridLineWidth: CGFloat? = nil,
            gridLineCount: Int? = nil,
            aspectControl: LMKSegmentedControl.Style = LMKSegmentedControl.Style(),
            overlayButton: LMKButton.Style = LMKButton.Style(),
            overlayButtonSize: CGFloat? = nil,
            contentInset: CGFloat? = nil,
            minimumCropSize: CGFloat? = nil,
            maximumZoomScale: CGFloat? = nil,
            locksOrientation: Bool? = nil,
            haptics: Bool? = nil
        ) {
            self.backgroundColor = backgroundColor
            self.chromeTint = chromeTint
            self.dimmingColor = dimmingColor
            self.dimmingAlpha = dimmingAlpha
            self.cropFrameBorder = cropFrameBorder
            self.handleSize = handleSize
            self.handleColor = handleColor
            self.handleHitSize = handleHitSize
            self.showsGrid = showsGrid
            self.gridColor = gridColor
            self.gridAlpha = gridAlpha
            self.gridLineWidth = gridLineWidth
            self.gridLineCount = gridLineCount
            self.aspectControl = aspectControl
            self.overlayButton = overlayButton
            self.overlayButtonSize = overlayButtonSize
            self.contentInset = contentInset
            self.minimumCropSize = minimumCropSize
            self.maximumZoomScale = maximumZoomScale
            self.locksOrientation = locksOrientation
            self.haptics = haptics
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                backgroundColor: other.backgroundColor ?? backgroundColor,
                chromeTint: other.chromeTint ?? chromeTint,
                dimmingColor: other.dimmingColor ?? dimmingColor,
                dimmingAlpha: other.dimmingAlpha ?? dimmingAlpha,
                cropFrameBorder: other.cropFrameBorder ?? cropFrameBorder,
                handleSize: other.handleSize ?? handleSize,
                handleColor: other.handleColor ?? handleColor,
                handleHitSize: other.handleHitSize ?? handleHitSize,
                showsGrid: other.showsGrid ?? showsGrid,
                gridColor: other.gridColor ?? gridColor,
                gridAlpha: other.gridAlpha ?? gridAlpha,
                gridLineWidth: other.gridLineWidth ?? gridLineWidth,
                gridLineCount: other.gridLineCount ?? gridLineCount,
                aspectControl: aspectControl.merging(other.aspectControl),
                overlayButton: overlayButton.merging(other.overlayButton),
                overlayButtonSize: other.overlayButtonSize ?? overlayButtonSize,
                contentInset: other.contentInset ?? contentInset,
                minimumCropSize: other.minimumCropSize ?? minimumCropSize,
                maximumZoomScale: other.maximumZoomScale ?? maximumZoomScale,
                locksOrientation: other.locksOrientation ?? locksOrientation,
                haptics: other.haptics ?? haptics
            )
        }
    }

    // MARK: - Strings

    /// User-visible strings of the crop editor, defaulting to the package's localized values.
    nonisolated struct Strings: Sendable, Equatable {
        public var title: String
        public var free: String
        public var cancel: String
        public var done: String
        /// Accessibility label of the aspect ratio control.
        public var aspectRatioAccessibilityLabel: String

        public init(
            title: String = LMKLocalized("photoCrop.title"),
            free: String = LMKLocalized("photoCrop.free"),
            cancel: String = LMKLocalized("photoCrop.cancel"),
            done: String = LMKLocalized("photoCrop.done"),
            aspectRatioAccessibilityLabel: String = LMKLocalized("photoCrop.aspectRatio.accessibilityLabel")
        ) {
            self.title = title
            self.free = free
            self.cancel = cancel
            self.done = done
            self.aspectRatioAccessibilityLabel = aspectRatioAccessibilityLabel
        }
    }

    /// The eight resize handles of the crop frame.
    nonisolated enum ResizeHandle: Int, Sendable, Hashable, CaseIterable {
        case topLeft = 0, topRight, bottomLeft, bottomRight
        case top, bottom, left, right

        public var isCorner: Bool {
            switch self {
            case .topLeft, .topRight, .bottomLeft, .bottomRight: true
            case .top, .bottom, .left, .right: false
            }
        }

        static let corners: [Self] = [.topLeft, .topRight, .bottomLeft, .bottomRight]
        static let edges: [Self] = [.top, .bottom, .left, .right]
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKPhotoCropViewController`.
    var photoCrop: LMKPhotoCropViewController.Style {
        get { self[LMKPhotoCropViewController.Style.self] }
        set { self[LMKPhotoCropViewController.Style.self] = newValue }
    }
}

// MARK: - Resolution

extension LMKPhotoCropViewController.Style {
    var stageColor: UIColor { backgroundColor ?? LMKPhotoPalette.background }
    var chrome: UIColor { chromeTint ?? LMKPhotoPalette.foreground }
    var handleSide: CGFloat { max(1, handleSize ?? LMKPhotoCropMetrics.handleSize) }
    var gridCount: Int { max(0, gridLineCount ?? LMKPhotoCropMetrics.gridLineCount) }
    var drawsGrid: Bool { (showsGrid ?? true) && gridCount > 0 }
    var maximumZoom: CGFloat { max(1, maximumZoomScale ?? LMKPhotoBrowserMetrics.maximumZoomScale) }
    var playsHaptics: Bool { haptics ?? true }

    func handleHitSide(theme: LMKTheme) -> CGFloat {
        max(handleSide, handleHitSize ?? handleSide + theme.spacing.medium)
    }

    func minimumCropSide(theme: LMKTheme) -> CGFloat {
        max(1, minimumCropSize ?? theme.layout.minimumTouchTarget)
    }

    func padding(theme: LMKTheme) -> CGFloat {
        max(0, contentInset ?? theme.spacing.xl)
    }

    func buttonSize(theme: LMKTheme) -> CGFloat {
        if let overlayButtonSize { return overlayButtonSize }
        #if targetEnvironment(macCatalyst)
            return LMKPhotoBrowserMetrics.macOverlayButtonSize
        #else
            return theme.layout.minimumTouchTarget
        #endif
    }

    /// The overlay button look with `overlayButton` layered on top.
    func overlayButtonStyle(theme: LMKTheme) -> LMKButton.Style {
        LMKButton.Style(
            variant: .filled,
            surface: LMKSurfaceStyle(
                background: .solid(stageColor.withAlphaComponent(theme.alpha.large)),
                corners: .circle,
                shadow: LMKShadowSource.none
            ),
            tintColor: stageColor,
            foregroundColor: chrome,
            symbolPointSize: theme.layout.symbolAction,
            minimumHeight: buttonSize(theme: theme),
            haptics: haptics
        ).merging(overlayButton)
    }

    /// The aspect ratio control look with `aspectControl` layered on top.
    func aspectControlStyle(theme: LMKTheme) -> LMKSegmentedControl.Style {
        LMKSegmentedControl.Style(
            surface: LMKSurfaceStyle(background: .solid(stageColor.withAlphaComponent(theme.alpha.xl))),
            indicator: LMKSurfaceStyle(background: .solid(chrome)),
            textColor: chrome,
            selectedTextColor: stageColor,
            haptics: haptics
        ).merging(aspectControl)
    }
}

// MARK: - Metrics

/// Fixed constants of the crop editor (not themeable).
nonisolated enum LMKPhotoCropMetrics {
    static let handleSize: CGFloat = 18
    static let gridLineCount = 2
    static let cropFrameBorderWidth: CGFloat = 2
}
