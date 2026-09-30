//
//  LMKListRowConfiguration.swift
//  LumiKit
//
//  A `UIContentConfiguration` for the standard list row: a leading symbol
//  in a tinted circle or a thumbnail, title / subtitle / detail text, and a
//  trailing accessory (chevron, checkmark, switch, badge, image, or view).
//

import UIKit

/// The standard list row, as a content configuration for `UITableViewCell` and
/// `UICollectionViewListCell`.
///
/// ```swift
/// cell.lmk_applyListRow(LMKListRowConfiguration(
///     title: "Destinations",
///     subtitle: "Tokyo, Kyoto, Osaka",
///     leading: .symbol("mappin.and.ellipse", tint: LMKColor.success),
///     trailing: .disclosure
/// ))
/// ```
///
/// Appearance comes from `style` (per row) over `theme.listRow` (app-wide); the row re-renders
/// on theme, Dynamic Type, and appearance changes like every LumiKit view.
public struct LMKListRowConfiguration: UIContentConfiguration {
    // MARK: - Leading and trailing

    /// What sits before the text.
    public enum Leading {
        case none
        /// An SF Symbol in a circle filled with a translucent `tint` (`nil` = `primary`).
        case symbol(String, tint: UIColor? = nil)
        /// A thumbnail, clipped to `style.leadingCorners`.
        case image(UIImage)
        /// A thumbnail loaded on demand. `load` runs off the main actor for the row's `id`;
        /// a placeholder symbol shows meanwhile and a stale result never lands on a reused row.
        case asyncImage(id: String, placeholderSymbol: String? = nil, load: @Sendable (String) async -> UIImage?)
        /// Any view, sized by its own constraints or intrinsic size.
        case view(UIView)
    }

    /// What sits after the text.
    public enum Trailing {
        case none
        /// A chevron; the row reads as a button to VoiceOver.
        case disclosure
        /// A checkmark; the row reads as selected to VoiceOver.
        case checkmark
        /// An `LMKSwitch`; the row stops being one VoiceOver element so the switch stays reachable.
        case toggle(isOn: Bool, onChange: (Bool) -> Void)
        /// An `LMKBadgeView`.
        case badge(LMKBadgeView.Content)
        /// A symbol or image, tinted with `tint` (`nil` = `textTertiary`).
        case image(UIImage, tint: UIColor? = nil)
        /// Any view.
        case view(UIView)
    }

    // MARK: - Style

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// `nil` = `.body`.
        public var titleTextStyle: LMKTextStyle?
        /// `nil` = `.caption`.
        public var subtitleTextStyle: LMKTextStyle?
        /// `nil` = `.bodyMedium`.
        public var detailTextStyle: LMKTextStyle?
        /// `nil` = `textPrimary`.
        public var titleColor: UIColor?
        /// `nil` = `textSecondary`.
        public var subtitleColor: UIColor?
        /// `nil` = `textPrimary`.
        public var detailColor: UIColor?
        /// `nil` = 1.
        public var titleLines: Int?
        /// `nil` = 1.
        public var subtitleLines: Int?
        /// Side of the leading circle or thumbnail; `nil` = `iconCircle`.
        public var leadingSize: CGFloat?
        /// Symbol point size inside the leading circle; `nil` = `iconExtraSmall`.
        public var leadingSymbolPointSize: CGFloat?
        /// Alpha of the tint behind a leading symbol; `nil` = `alpha.xxs`.
        public var leadingCircleAlpha: CGFloat?
        /// Corners of a leading thumbnail; `nil` = `.fixed(small)`.
        public var leadingCorners: LMKCornerStyle?
        /// Between the leading view and the text; `nil` = `medium`.
        public var leadingSpacing: CGFloat?
        /// Between title and subtitle; `nil` = `xxs`.
        public var textSpacing: CGFloat?
        /// Between the text and the trailing views; `nil` = `small`.
        public var trailingSpacing: CGFloat?
        /// Chevron point size; `nil` = `symbolAccessory`.
        public var accessoryChevronSize: CGFloat?
        /// Chevron and trailing image tint; `nil` = `textTertiary`.
        public var accessoryTint: UIColor?
        /// Checkmark tint; `nil` = `primary`.
        public var checkmarkTint: UIColor?
        /// From the row's edges to its content; `nil` = `large` leading and trailing, `small` top
        /// and bottom. The row is as tall as its content plus the vertical insets, never shorter
        /// than `minimumHeight`.
        public var contentInsets: NSDirectionalEdgeInsets?
        /// `nil` = `rowHeightCompact`.
        public var minimumHeight: CGFloat?
        public var disabled: LMKControlStateStyle?

        public init(
            titleTextStyle: LMKTextStyle? = nil,
            subtitleTextStyle: LMKTextStyle? = nil,
            detailTextStyle: LMKTextStyle? = nil,
            titleColor: UIColor? = nil,
            subtitleColor: UIColor? = nil,
            detailColor: UIColor? = nil,
            titleLines: Int? = nil,
            subtitleLines: Int? = nil,
            leadingSize: CGFloat? = nil,
            leadingSymbolPointSize: CGFloat? = nil,
            leadingCircleAlpha: CGFloat? = nil,
            leadingCorners: LMKCornerStyle? = nil,
            leadingSpacing: CGFloat? = nil,
            textSpacing: CGFloat? = nil,
            trailingSpacing: CGFloat? = nil,
            accessoryChevronSize: CGFloat? = nil,
            accessoryTint: UIColor? = nil,
            checkmarkTint: UIColor? = nil,
            contentInsets: NSDirectionalEdgeInsets? = nil,
            minimumHeight: CGFloat? = nil,
            disabled: LMKControlStateStyle? = nil
        ) {
            self.titleTextStyle = titleTextStyle
            self.subtitleTextStyle = subtitleTextStyle
            self.detailTextStyle = detailTextStyle
            self.titleColor = titleColor
            self.subtitleColor = subtitleColor
            self.detailColor = detailColor
            self.titleLines = titleLines
            self.subtitleLines = subtitleLines
            self.leadingSize = leadingSize
            self.leadingSymbolPointSize = leadingSymbolPointSize
            self.leadingCircleAlpha = leadingCircleAlpha
            self.leadingCorners = leadingCorners
            self.leadingSpacing = leadingSpacing
            self.textSpacing = textSpacing
            self.trailingSpacing = trailingSpacing
            self.accessoryChevronSize = accessoryChevronSize
            self.accessoryTint = accessoryTint
            self.checkmarkTint = checkmarkTint
            self.contentInsets = contentInsets
            self.minimumHeight = minimumHeight
            self.disabled = disabled
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                titleTextStyle: other.titleTextStyle ?? titleTextStyle,
                subtitleTextStyle: other.subtitleTextStyle ?? subtitleTextStyle,
                detailTextStyle: other.detailTextStyle ?? detailTextStyle,
                titleColor: other.titleColor ?? titleColor,
                subtitleColor: other.subtitleColor ?? subtitleColor,
                detailColor: other.detailColor ?? detailColor,
                titleLines: other.titleLines ?? titleLines,
                subtitleLines: other.subtitleLines ?? subtitleLines,
                leadingSize: other.leadingSize ?? leadingSize,
                leadingSymbolPointSize: other.leadingSymbolPointSize ?? leadingSymbolPointSize,
                leadingCircleAlpha: other.leadingCircleAlpha ?? leadingCircleAlpha,
                leadingCorners: other.leadingCorners ?? leadingCorners,
                leadingSpacing: other.leadingSpacing ?? leadingSpacing,
                textSpacing: other.textSpacing ?? textSpacing,
                trailingSpacing: other.trailingSpacing ?? trailingSpacing,
                accessoryChevronSize: other.accessoryChevronSize ?? accessoryChevronSize,
                accessoryTint: other.accessoryTint ?? accessoryTint,
                checkmarkTint: other.checkmarkTint ?? checkmarkTint,
                contentInsets: other.contentInsets ?? contentInsets,
                minimumHeight: other.minimumHeight ?? minimumHeight,
                disabled: LMKControlStateStyle.merge(disabled, other.disabled)
            )
        }
    }

    // MARK: - Content

    public var title: String
    public var subtitle: String?
    /// Trailing text before the accessory (an amount, a count, a status).
    public var detail: String?
    public var leading: Leading
    public var trailing: Trailing
    public var style: Style
    /// A disabled row dims and reads as not enabled; the cell's selection is the host's to turn off.
    public var isEnabled: Bool
    /// Replaces the generated "title, subtitle, detail" VoiceOver label.
    public var accessibilityLabel: String?
    public var accessibilityHint: String?

    /// Cell state from `updated(for:)`; the content view dims for `isDisabled`.
    public internal(set) var isHighlighted = false
    public internal(set) var isSelected = false

    public init(
        title: String,
        subtitle: String? = nil,
        detail: String? = nil,
        leading: Leading = .none,
        trailing: Trailing = .disclosure,
        style: Style = Style(),
        isEnabled: Bool = true,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.detail = detail
        self.leading = leading
        self.trailing = trailing
        self.style = style
        self.isEnabled = isEnabled
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
    }

    // MARK: - UIContentConfiguration

    public func makeContentView() -> UIView & UIContentView {
        LMKListRowContentView(configuration: self)
    }

    public func updated(for state: UIConfigurationState) -> Self {
        var copy = self
        if let cellState = state as? UICellConfigurationState {
            copy.isHighlighted = cellState.isHighlighted
            copy.isSelected = cellState.isSelected
            if cellState.isDisabled { copy.isEnabled = false }
        }
        return copy
    }

    /// Whether the row should be one VoiceOver element (a toggle or custom trailing view keeps its own).
    var isSingleAccessibilityElement: Bool {
        switch trailing {
        case .toggle, .view: false
        default: true
        }
    }
}
