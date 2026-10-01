//
//  LMKDetailCardView+Style.swift
//  LumiKit
//
//  The detail card's Style (theme slot `detailCard`) and Strings.
//

import UIKit

public extension LMKDetailCardView {
    nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// Card
        /// Layered on the card surface (default `backgroundSecondary`, `medium` corners, a hairline
        /// `outline` border, and the `level1` shadow).
        public var card: LMKCardView.Style

        /// Header
        /// `nil` = `iconMedium`.
        public var headerIconSize: CGFloat?
        /// `nil` = `primary`.
        public var headerIconTint: UIColor?
        /// Whether the icon sits in a tinted circle; `nil` = no.
        public var headerIconInCircle: Bool?
        /// `nil` = `.h3`.
        public var headerTitleTextStyle: LMKTextStyle?
        /// `nil` = `textPrimary`.
        public var headerTitleColor: UIColor?
        /// `nil` = `.caption`.
        public var headerSubtitleTextStyle: LMKTextStyle?
        /// `nil` = `textSecondary`.
        public var headerSubtitleColor: UIColor?
        /// Between icon, text, and trailing items; `nil` = `small`.
        public var headerSpacing: CGFloat?
        /// Layered on trailing icon buttons.
        public var headerButton: LMKButton.Style
        /// Between the header and the first row; `nil` = `medium`.
        public var headerBottomSpacing: CGFloat?

        /// Rows
        /// `nil` = `medium`.
        public var rowSpacing: CGFloat?
        /// Hairline dividers between rows; `nil` = no.
        public var showsRowDividers: Bool?
        /// `nil` = `.subbodyMedium`.
        public var inlineKeyTextStyle: LMKTextStyle?
        /// `nil` = `.captionMedium`.
        public var stackedKeyTextStyle: LMKTextStyle?
        /// `nil` = `textSecondary`.
        public var keyColor: UIColor?
        /// `nil` = `.body`.
        public var valueTextStyle: LMKTextStyle?
        /// `nil` = `textPrimary`.
        public var valueColor: UIColor?
        /// Alignment of an inline value; `nil` = trailing.
        public var inlineValueAlignment: NSTextAlignment?
        /// Between key and value; `nil` = `small` inline, `xs` stacked.
        public var keyValueSpacing: CGFloat?
        /// `nil` = `.caption`.
        public var descriptionTextStyle: LMKTextStyle?
        /// `nil` = `textSecondary`.
        public var descriptionColor: UIColor?
        /// `nil` = `.body`.
        public var textStyle: LMKTextStyle?
        /// `nil` = `textPrimary`.
        public var textColor: UIColor?
        /// Heading above a text row; `nil` = `.h4`.
        public var textTitleTextStyle: LMKTextStyle?
        /// Layered on chips.
        public var chip: LMKChipView.Style
        /// `nil` = `small`.
        public var chipSpacing: CGFloat?

        /// Photo strip
        /// `nil` = 100.
        public var photoTileHeight: CGFloat?
        /// `nil` = `.fixed(medium)`.
        public var photoTileCorners: LMKCornerStyle?
        /// `nil` = `small`.
        public var photoSpacing: CGFloat?
        /// `nil` = `.smallMedium`.
        public var photoCaptionTextStyle: LMKTextStyle?
        /// `nil` = `textSecondary`.
        public var photoCaptionColor: UIColor?
        /// `nil` = `backgroundTertiary`.
        public var photoPlaceholderColor: UIColor?

        /// Progress
        /// `nil` = `small` (8pt).
        public var progressHeight: CGFloat?
        /// `nil` = `primary`.
        public var progressTint: UIColor?
        /// `nil` = `fill`.
        public var progressTrackColor: UIColor?

        /// Navigation, link, rating, image
        /// Layered on navigation rows.
        public var navigationRow: LMKListRowConfiguration.Style
        /// Background, corners, border of a navigation row (default clear; give it `backgroundSecondary` + corners for the inset look).
        public var navigationRowSurface: LMKSurfaceStyle
        /// `nil` = `link`.
        public var linkColor: UIColor?
        /// `nil` = `.bodyMedium`.
        public var linkTextStyle: LMKTextStyle?
        /// Whether link titles are underlined; `nil` = no.
        public var underlinesLinks: Bool?
        /// Layered on rating controls.
        public var rating: LMKRatingControl.Style
        /// `nil` = 240.
        public var imageMaxHeight: CGFloat?
        /// `nil` = `.fixed(medium)`.
        public var imageCorners: LMKCornerStyle?
        /// `nil` = `backgroundSecondary`.
        public var imageBackgroundColor: UIColor?

        /// Actions
        /// Between the last row and the buttons; `nil` = `large`.
        public var actionsTopSpacing: CGFloat?
        /// Between buttons; `nil` = `small`.
        public var actionSpacing: CGFloat?
        /// Per-role button styles; a missing role uses `filled(role)` (`ghost` for `destructive`).
        public var actionButtons: [LMKButton.Role: LMKButton.Style]

        /// Behavior
        /// Selection haptic on an action's long press; `nil` = yes.
        public var haptics: Bool?

        public init(
            card: LMKCardView.Style = LMKCardView.Style(),
            headerIconSize: CGFloat? = nil,
            headerIconTint: UIColor? = nil,
            headerIconInCircle: Bool? = nil,
            headerTitleTextStyle: LMKTextStyle? = nil,
            headerTitleColor: UIColor? = nil,
            headerSubtitleTextStyle: LMKTextStyle? = nil,
            headerSubtitleColor: UIColor? = nil,
            headerSpacing: CGFloat? = nil,
            headerButton: LMKButton.Style = LMKButton.Style(),
            headerBottomSpacing: CGFloat? = nil,
            rowSpacing: CGFloat? = nil,
            showsRowDividers: Bool? = nil,
            inlineKeyTextStyle: LMKTextStyle? = nil,
            stackedKeyTextStyle: LMKTextStyle? = nil,
            keyColor: UIColor? = nil,
            valueTextStyle: LMKTextStyle? = nil,
            valueColor: UIColor? = nil,
            inlineValueAlignment: NSTextAlignment? = nil,
            keyValueSpacing: CGFloat? = nil,
            descriptionTextStyle: LMKTextStyle? = nil,
            descriptionColor: UIColor? = nil,
            textStyle: LMKTextStyle? = nil,
            textColor: UIColor? = nil,
            textTitleTextStyle: LMKTextStyle? = nil,
            chip: LMKChipView.Style = LMKChipView.Style(),
            chipSpacing: CGFloat? = nil,
            photoTileHeight: CGFloat? = nil,
            photoTileCorners: LMKCornerStyle? = nil,
            photoSpacing: CGFloat? = nil,
            photoCaptionTextStyle: LMKTextStyle? = nil,
            photoCaptionColor: UIColor? = nil,
            photoPlaceholderColor: UIColor? = nil,
            progressHeight: CGFloat? = nil,
            progressTint: UIColor? = nil,
            progressTrackColor: UIColor? = nil,
            navigationRow: LMKListRowConfiguration.Style = LMKListRowConfiguration.Style(),
            navigationRowSurface: LMKSurfaceStyle = LMKSurfaceStyle(),
            linkColor: UIColor? = nil,
            linkTextStyle: LMKTextStyle? = nil,
            underlinesLinks: Bool? = nil,
            rating: LMKRatingControl.Style = LMKRatingControl.Style(),
            imageMaxHeight: CGFloat? = nil,
            imageCorners: LMKCornerStyle? = nil,
            imageBackgroundColor: UIColor? = nil,
            actionsTopSpacing: CGFloat? = nil,
            actionSpacing: CGFloat? = nil,
            actionButtons: [LMKButton.Role: LMKButton.Style] = [:],
            haptics: Bool? = nil
        ) {
            self.card = card
            self.headerIconSize = headerIconSize
            self.headerIconTint = headerIconTint
            self.headerIconInCircle = headerIconInCircle
            self.headerTitleTextStyle = headerTitleTextStyle
            self.headerTitleColor = headerTitleColor
            self.headerSubtitleTextStyle = headerSubtitleTextStyle
            self.headerSubtitleColor = headerSubtitleColor
            self.headerSpacing = headerSpacing
            self.headerButton = headerButton
            self.headerBottomSpacing = headerBottomSpacing
            self.rowSpacing = rowSpacing
            self.showsRowDividers = showsRowDividers
            self.inlineKeyTextStyle = inlineKeyTextStyle
            self.stackedKeyTextStyle = stackedKeyTextStyle
            self.keyColor = keyColor
            self.valueTextStyle = valueTextStyle
            self.valueColor = valueColor
            self.inlineValueAlignment = inlineValueAlignment
            self.keyValueSpacing = keyValueSpacing
            self.descriptionTextStyle = descriptionTextStyle
            self.descriptionColor = descriptionColor
            self.textStyle = textStyle
            self.textColor = textColor
            self.textTitleTextStyle = textTitleTextStyle
            self.chip = chip
            self.chipSpacing = chipSpacing
            self.photoTileHeight = photoTileHeight
            self.photoTileCorners = photoTileCorners
            self.photoSpacing = photoSpacing
            self.photoCaptionTextStyle = photoCaptionTextStyle
            self.photoCaptionColor = photoCaptionColor
            self.photoPlaceholderColor = photoPlaceholderColor
            self.progressHeight = progressHeight
            self.progressTint = progressTint
            self.progressTrackColor = progressTrackColor
            self.navigationRow = navigationRow
            self.navigationRowSurface = navigationRowSurface
            self.linkColor = linkColor
            self.linkTextStyle = linkTextStyle
            self.underlinesLinks = underlinesLinks
            self.rating = rating
            self.imageMaxHeight = imageMaxHeight
            self.imageCorners = imageCorners
            self.imageBackgroundColor = imageBackgroundColor
            self.actionsTopSpacing = actionsTopSpacing
            self.actionSpacing = actionSpacing
            self.actionButtons = actionButtons
            self.haptics = haptics
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                card: card.merging(other.card),
                headerIconSize: other.headerIconSize ?? headerIconSize,
                headerIconTint: other.headerIconTint ?? headerIconTint,
                headerIconInCircle: other.headerIconInCircle ?? headerIconInCircle,
                headerTitleTextStyle: other.headerTitleTextStyle ?? headerTitleTextStyle,
                headerTitleColor: other.headerTitleColor ?? headerTitleColor,
                headerSubtitleTextStyle: other.headerSubtitleTextStyle ?? headerSubtitleTextStyle,
                headerSubtitleColor: other.headerSubtitleColor ?? headerSubtitleColor,
                headerSpacing: other.headerSpacing ?? headerSpacing,
                headerButton: headerButton.merging(other.headerButton),
                headerBottomSpacing: other.headerBottomSpacing ?? headerBottomSpacing,
                rowSpacing: other.rowSpacing ?? rowSpacing,
                showsRowDividers: other.showsRowDividers ?? showsRowDividers,
                inlineKeyTextStyle: other.inlineKeyTextStyle ?? inlineKeyTextStyle,
                stackedKeyTextStyle: other.stackedKeyTextStyle ?? stackedKeyTextStyle,
                keyColor: other.keyColor ?? keyColor,
                valueTextStyle: other.valueTextStyle ?? valueTextStyle,
                valueColor: other.valueColor ?? valueColor,
                inlineValueAlignment: other.inlineValueAlignment ?? inlineValueAlignment,
                keyValueSpacing: other.keyValueSpacing ?? keyValueSpacing,
                descriptionTextStyle: other.descriptionTextStyle ?? descriptionTextStyle,
                descriptionColor: other.descriptionColor ?? descriptionColor,
                textStyle: other.textStyle ?? textStyle,
                textColor: other.textColor ?? textColor,
                textTitleTextStyle: other.textTitleTextStyle ?? textTitleTextStyle,
                chip: chip.merging(other.chip),
                chipSpacing: other.chipSpacing ?? chipSpacing,
                photoTileHeight: other.photoTileHeight ?? photoTileHeight,
                photoTileCorners: other.photoTileCorners ?? photoTileCorners,
                photoSpacing: other.photoSpacing ?? photoSpacing,
                photoCaptionTextStyle: other.photoCaptionTextStyle ?? photoCaptionTextStyle,
                photoCaptionColor: other.photoCaptionColor ?? photoCaptionColor,
                photoPlaceholderColor: other.photoPlaceholderColor ?? photoPlaceholderColor,
                progressHeight: other.progressHeight ?? progressHeight,
                progressTint: other.progressTint ?? progressTint,
                progressTrackColor: other.progressTrackColor ?? progressTrackColor,
                navigationRow: navigationRow.merging(other.navigationRow),
                navigationRowSurface: navigationRowSurface.merging(other.navigationRowSurface),
                linkColor: other.linkColor ?? linkColor,
                linkTextStyle: other.linkTextStyle ?? linkTextStyle,
                underlinesLinks: other.underlinesLinks ?? underlinesLinks,
                rating: rating.merging(other.rating),
                imageMaxHeight: other.imageMaxHeight ?? imageMaxHeight,
                imageCorners: other.imageCorners ?? imageCorners,
                imageBackgroundColor: other.imageBackgroundColor ?? imageBackgroundColor,
                actionsTopSpacing: other.actionsTopSpacing ?? actionsTopSpacing,
                actionSpacing: other.actionSpacing ?? actionSpacing,
                actionButtons: actionButtons.merging(other.actionButtons) { base, override in base.merging(override) },
                haptics: other.haptics ?? haptics
            )
        }

        /// The button style for an action role: the explicit entry, else `ghost` for `destructive`,
        /// `filled` for every other role.
        public func actionButtonStyle(for role: LMKButton.Role) -> LMKButton.Style {
            let base: LMKButton.Style = role == .destructive ? .ghost(.destructive) : .filled(role)
            guard let override = actionButtons[role] else { return base }
            return base.merging(override)
        }
    }

    // MARK: - Strings

    nonisolated struct Strings: Sendable, Equatable {
        public var removeLinkAccessibilityLabel: String
        public var loadingAccessibilityLabel: String
        /// VoiceOver value of a selected photo tile.
        public var photoSelectedAccessibilityValue: String
        /// Format for a photo tile's label ("Photo %lld of %lld").
        public var photoAccessibilityLabelFormat: String

        public init(
            removeLinkAccessibilityLabel: String = LMKLocalized("detailCard.removeLink.accessibilityLabel"),
            loadingAccessibilityLabel: String = LMKLocalized("detailCard.loading.accessibilityLabel"),
            photoSelectedAccessibilityValue: String = LMKLocalized("detailCard.photoSelected.accessibilityValue"),
            photoAccessibilityLabelFormat: String = LMKLocalized("detailCard.photo.accessibilityLabel")
        ) {
            self.removeLinkAccessibilityLabel = removeLinkAccessibilityLabel
            self.loadingAccessibilityLabel = loadingAccessibilityLabel
            self.photoSelectedAccessibilityValue = photoSelectedAccessibilityValue
            self.photoAccessibilityLabelFormat = photoAccessibilityLabelFormat
        }
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKDetailCardView`.
    var detailCard: LMKDetailCardView.Style {
        get { self[LMKDetailCardView.Style.self] }
        set { self[LMKDetailCardView.Style.self] = newValue }
    }
}
