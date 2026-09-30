//
//  LMKPhotoBrowserViewController+Style.swift
//  LumiKit
//
//  Style, strings, theme slot, and the fixed metrics of the photo browser.
//

import LumiKitUI
import UIKit

// MARK: - Style

public extension LMKPhotoBrowserViewController {
    /// Appearance of the browser: the stage behind the photos, the chrome over it, the
    /// overlay buttons, the page indicator, the LIVE badge, and the dismiss motion.
    ///
    /// Every field is optional; `nil` resolves from `theme.photoBrowser`, then the built-in
    /// defaults (a near-black stage with white chrome, kept in every appearance mode).
    nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// Stage behind the photos; `nil` = near-black.
        public var backgroundColor: UIColor?
        /// Buttons, counter, date pill text, page dots; `nil` = white.
        public var chromeTint: UIColor?
        /// Layered on the dismiss and action buttons (a circle of the stage color at `alpha.large`).
        public var overlayButton: LMKButton.Style
        /// Side of the overlay buttons; `nil` = `minimumTouchTarget` (48 under Mac Catalyst).
        public var overlayButtonSize: CGFloat?
        /// Counter text ("3 of 12"); `nil` = `caption`.
        public var counterTextStyle: LMKTextStyle?
        /// Counter alpha over the stage; `nil` = 0.9.
        public var counterAlpha: CGFloat?
        /// Date / subtitle pill (stage at `alpha.large`, `small` corners, small × medium insets).
        public var datePill: LMKSurfaceStyle
        /// Date / subtitle text; `nil` = `bodyMedium`.
        public var dateTextStyle: LMKTextStyle?
        /// Page dots under the counter (chrome tint; inactive at `alpha.medium`).
        public var pageIndicator: LMKPageIndicator.Style
        /// LIVE capsule on Live Photo pages (black at `alpha.xl`, capsule).
        public var liveBadge: LMKSurfaceStyle
        /// LIVE capsule text; `nil` = `extraSmallSemibold`.
        public var liveBadgeTextStyle: LMKTextStyle?
        /// Empty state shown on the stage when the data source has no photos.
        public var emptyState: LMKEmptyStateView.Style
        /// Gap between pages; `nil` = `spacing.large`.
        public var interPageSpacing: CGFloat?
        /// Pinch zoom ceiling; `nil` = 3.
        public var maximumZoomScale: CGFloat?
        /// Zoom reached by a double tap; `nil` = 2.
        public var doubleTapZoomScale: CGFloat?
        /// Scale-down of the page at full dismiss progress (`1 - value`); `nil` = 0.15.
        public var dismissScale: CGFloat?
        /// Stage alpha once a dismiss drag reaches its threshold; `nil` = 0.1. The screen the
        /// browser was presented over shows through the rest.
        public var dismissMinimumAlpha: CGFloat?
        /// Photos render their extended range (`preferredImageDynamicRange = .high`, constrained
        /// while the iOS 26 headroom limit is active); `nil` = true.
        public var prefersHDR: Bool?
        /// iOS 26: asks the scene to lock its interface orientation while the browser is up; `nil` = false.
        public var locksOrientation: Bool?
        /// Selection and impact haptics; `nil` = enabled.
        public var haptics: Bool?

        public init(
            backgroundColor: UIColor? = nil,
            chromeTint: UIColor? = nil,
            overlayButton: LMKButton.Style = LMKButton.Style(),
            overlayButtonSize: CGFloat? = nil,
            counterTextStyle: LMKTextStyle? = nil,
            counterAlpha: CGFloat? = nil,
            datePill: LMKSurfaceStyle = LMKSurfaceStyle(),
            dateTextStyle: LMKTextStyle? = nil,
            pageIndicator: LMKPageIndicator.Style = LMKPageIndicator.Style(),
            liveBadge: LMKSurfaceStyle = LMKSurfaceStyle(),
            liveBadgeTextStyle: LMKTextStyle? = nil,
            emptyState: LMKEmptyStateView.Style = LMKEmptyStateView.Style(),
            interPageSpacing: CGFloat? = nil,
            maximumZoomScale: CGFloat? = nil,
            doubleTapZoomScale: CGFloat? = nil,
            dismissScale: CGFloat? = nil,
            dismissMinimumAlpha: CGFloat? = nil,
            prefersHDR: Bool? = nil,
            locksOrientation: Bool? = nil,
            haptics: Bool? = nil
        ) {
            self.backgroundColor = backgroundColor
            self.chromeTint = chromeTint
            self.overlayButton = overlayButton
            self.overlayButtonSize = overlayButtonSize
            self.counterTextStyle = counterTextStyle
            self.counterAlpha = counterAlpha
            self.datePill = datePill
            self.dateTextStyle = dateTextStyle
            self.pageIndicator = pageIndicator
            self.liveBadge = liveBadge
            self.liveBadgeTextStyle = liveBadgeTextStyle
            self.emptyState = emptyState
            self.interPageSpacing = interPageSpacing
            self.maximumZoomScale = maximumZoomScale
            self.doubleTapZoomScale = doubleTapZoomScale
            self.dismissScale = dismissScale
            self.dismissMinimumAlpha = dismissMinimumAlpha
            self.prefersHDR = prefersHDR
            self.locksOrientation = locksOrientation
            self.haptics = haptics
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                backgroundColor: other.backgroundColor ?? backgroundColor,
                chromeTint: other.chromeTint ?? chromeTint,
                overlayButton: overlayButton.merging(other.overlayButton),
                overlayButtonSize: other.overlayButtonSize ?? overlayButtonSize,
                counterTextStyle: other.counterTextStyle ?? counterTextStyle,
                counterAlpha: other.counterAlpha ?? counterAlpha,
                datePill: datePill.merging(other.datePill),
                dateTextStyle: other.dateTextStyle ?? dateTextStyle,
                pageIndicator: pageIndicator.merging(other.pageIndicator),
                liveBadge: liveBadge.merging(other.liveBadge),
                liveBadgeTextStyle: other.liveBadgeTextStyle ?? liveBadgeTextStyle,
                emptyState: emptyState.merging(other.emptyState),
                interPageSpacing: other.interPageSpacing ?? interPageSpacing,
                maximumZoomScale: other.maximumZoomScale ?? maximumZoomScale,
                doubleTapZoomScale: other.doubleTapZoomScale ?? doubleTapZoomScale,
                dismissScale: other.dismissScale ?? dismissScale,
                dismissMinimumAlpha: other.dismissMinimumAlpha ?? dismissMinimumAlpha,
                prefersHDR: other.prefersHDR ?? prefersHDR,
                locksOrientation: other.locksOrientation ?? locksOrientation,
                haptics: other.haptics ?? haptics
            )
        }
    }

    // MARK: - Strings

    /// User-visible strings of the browser, defaulting to the package's localized values.
    nonisolated struct Strings: Sendable, Equatable {
        /// Empty state message.
        public var emptyText: String
        /// Counter format with two `%lld` slots (current, total).
        public var counterFormat: String
        /// Accessibility hint on the page area.
        public var tapToToggleHint: String
        /// Text in the LIVE capsule.
        public var liveBadge: String
        /// Accessibility label of a Live Photo page.
        public var livePhotoAccessibilityLabel: String
        /// Accessibility label of the close button (also the Escape key command title).
        public var dismissAccessibilityLabel: String
        /// Accessibility label of the action button (also its key command title).
        public var actionAccessibilityLabel: String
        /// Key command title for the previous photo.
        public var previousPhoto: String
        /// Key command title for the next photo.
        public var nextPhoto: String

        public init(
            emptyText: String = LMKLocalized("photoBrowser.empty"),
            counterFormat: String = LMKLocalized("photoBrowser.counter"),
            tapToToggleHint: String = LMKLocalized("photoBrowser.tapToToggle.accessibilityHint"),
            liveBadge: String = LMKLocalized("photoBrowser.liveBadge"),
            livePhotoAccessibilityLabel: String = LMKLocalized("photoBrowser.livePhoto.accessibilityLabel"),
            dismissAccessibilityLabel: String = LMKLocalized("photoBrowser.dismiss.accessibilityLabel"),
            actionAccessibilityLabel: String = LMKLocalized("photoBrowser.action.accessibilityLabel"),
            previousPhoto: String = LMKLocalized("photoBrowser.previousPhoto"),
            nextPhoto: String = LMKLocalized("photoBrowser.nextPhoto")
        ) {
            self.emptyText = emptyText
            self.counterFormat = counterFormat
            self.tapToToggleHint = tapToToggleHint
            self.liveBadge = liveBadge
            self.livePhotoAccessibilityLabel = livePhotoAccessibilityLabel
            self.dismissAccessibilityLabel = dismissAccessibilityLabel
            self.actionAccessibilityLabel = actionAccessibilityLabel
            self.previousPhoto = previousPhoto
            self.nextPhoto = nextPhoto
        }
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKPhotoBrowserViewController`.
    var photoBrowser: LMKPhotoBrowserViewController.Style {
        get { self[LMKPhotoBrowserViewController.Style.self] }
        set { self[LMKPhotoBrowserViewController.Style.self] = newValue }
    }
}

// MARK: - Resolution

extension LMKPhotoBrowserViewController.Style {
    /// Stage color behind the photos.
    var stageColor: UIColor { backgroundColor ?? LMKPhotoPalette.background }
    /// Color of everything drawn over the stage.
    var chrome: UIColor { chromeTint ?? LMKPhotoPalette.foreground }
    var wantsHDR: Bool { prefersHDR ?? true }
    var maximumZoom: CGFloat { max(1, maximumZoomScale ?? LMKPhotoBrowserMetrics.maximumZoomScale) }
    var doubleTapZoom: CGFloat { max(1, doubleTapZoomScale ?? LMKPhotoBrowserMetrics.doubleTapZoomScale) }
    var dismissScaleEffect: CGFloat { dismissScale ?? LMKPhotoBrowserMetrics.dismissScale }
    var dismissFloorAlpha: CGFloat { dismissMinimumAlpha ?? LMKPhotoBrowserMetrics.dismissMinimumAlpha }
    var playsHaptics: Bool { haptics ?? true }

    func pageGap(theme: LMKTheme) -> CGFloat {
        max(0, interPageSpacing ?? theme.spacing.large)
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
}

// MARK: - Metrics

/// Fixed constants of the browser and its pages (not themeable).
nonisolated enum LMKPhotoBrowserMetrics {
    static let counterAlpha: CGFloat = 0.9
    static let dismissScale: CGFloat = 0.15
    static let dismissMinimumAlpha: CGFloat = 0.1
    /// Fraction of progress before the stage starts fading (tiny drags never flicker).
    static let dismissOpacityStartThreshold: CGFloat = 0.15
    /// The overlay fades this many times faster than the stage during a dismiss drag.
    static let overlayFadeMultiplier: CGFloat = 2.5
    /// Scale of the page when a swipe commits a dismiss.
    static let dismissSnapScale: CGFloat = 0.7
    /// Fraction of the page height a vertical drag must cover to dismiss.
    static let verticalDismissThresholdFraction: CGFloat = 0.2
    static let verticalDismissMinimumPoints: CGFloat = 80
    /// Vertical velocity (pt/s) that dismisses on a flick.
    static let verticalDismissVelocityThreshold: CGFloat = 700
    /// Distance a flick must already have covered before velocity counts.
    static let verticalDismissMinimumDistanceForVelocity: CGFloat = 20
    static let minimumZoomScale: CGFloat = 1
    static let maximumZoomScale: CGFloat = 3
    static let doubleTapZoomScale: CGFloat = 2
    static let macOverlayButtonSize: CGFloat = 48
    /// Horizontal scroll-wheel velocity (pt/s) that pages under Mac Catalyst.
    static let scrollWheelVelocityThreshold: CGFloat = 300
    static let liveBadgeHeight: CGFloat = 22
    /// Rubber-band floor when pinching below 1x.
    static let pinchShrinkFloor: CGFloat = 0.5
    /// Rubber-band ceiling when pinching past the maximum zoom.
    static let pinchOvershootCeiling: CGFloat = 1.5
    static let initialImageViewSide: CGFloat = 100
}
