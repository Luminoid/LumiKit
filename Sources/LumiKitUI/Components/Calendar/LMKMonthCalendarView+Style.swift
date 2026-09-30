//
//  LMKMonthCalendarView+Style.swift
//  LumiKit
//
//  The month calendar's vocabulary and Style: header layout, row heights,
//  selection and today rendering, decoration sizes, and paging.
//

import LumiKitCore
import UIKit

public extension LMKMonthCalendarView {
    // MARK: - Vocabulary

    /// How the month header is arranged.
    nonisolated enum HeaderLayout: Sendable, Hashable, CaseIterable {
        /// Previous chevron, centered title, next chevron.
        case centeredTitle
        /// Leading title (with a chevron when tappable), then Today and the paging chevrons.
        case leadingTitle
        /// No header; the host provides its own.
        case hidden
    }

    /// How a selected day is drawn.
    nonisolated enum SelectionStyle: Sendable, Hashable, CaseIterable {
        /// A solid tinted circle behind the numeral, which turns `onAccent`.
        case filledCircle
        /// A tinted ring around the numeral.
        case ringCircle
        /// A tinted rounded-rectangle outline around the cell.
        case ringRoundedRect
    }

    /// How today is drawn.
    nonisolated enum TodayStyle: Sendable, Hashable, CaseIterable {
        /// A translucent tinted circle behind the numeral.
        case tintedCircle
        /// A tinted ring around the numeral.
        case ringCircle
        /// A tinted rounded-rectangle outline around the cell.
        case ringRoundedRect
        /// Only the numeral is tinted.
        case numeralOnly
    }

    /// How months change on a horizontal swipe.
    nonisolated enum Paging: Sendable, Hashable, CaseIterable {
        /// The grid follows the finger and settles (falls back to `discrete` under Reduce Motion).
        case interactive
        /// A swipe past the threshold changes the month without a slide.
        case discrete
        /// Only the header chevrons (and the API) change the month.
        case buttonsOnly
    }

    // MARK: - Style

    nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// Accent
        /// The master tint (selection, today, dots, header controls); `nil` = `primary`.
        public var accent: UIColor?

        /// Header
        /// `nil` = `.centeredTitle`.
        public var headerLayout: HeaderLayout?
        /// `nil` = `minimumTouchTarget`.
        public var headerHeight: CGFloat?
        /// Background, corners, border, shadow, and insets of the header band (default clear).
        public var headerSurface: LMKSurfaceStyle
        /// `nil` = `.h3`.
        public var titleTextStyle: LMKTextStyle?
        /// `nil` = `textPrimary`.
        public var titleColor: UIColor?
        /// Whether the title is a button (`onMonthTitleTapped`); `nil` = no.
        public var titleIsTappable: Bool?
        /// Whether a Today button shows in the header; `nil` = no.
        public var showsTodayButton: Bool?
        /// Layered on the paging chevrons and the tappable title.
        public var navigationButton: LMKButton.Style
        /// Layered on the Today button.
        public var todayButton: LMKButton.Style
        /// A localized date template for the title ("yMMMM"); `nil` = the month-year style.
        public var monthTitleTemplate: String?
        /// Between the header and the weekday row; `nil` = `small`.
        public var spacingAfterHeader: CGFloat?

        /// Weekday row
        /// `nil` = 24, floored at the text's line height.
        public var weekdayRowHeight: CGFloat?
        /// `nil` = `.captionMedium`.
        public var weekdayTextStyle: LMKTextStyle?
        /// `nil` = `textTertiary`.
        public var weekdayColor: UIColor?
        /// `nil` = `.narrow` ("S M T W T F S").
        public var weekdaySymbolStyle: LMKDateFormat.WeekdaySymbolStyle?
        /// Between the weekday row and the grid; `nil` = `xs`.
        public var spacingAfterWeekdays: CGFloat?

        /// Grid
        /// `nil` = `minimumTouchTarget`. A floor: rows grow to fit the numeral and the tallest
        /// decoration band in use, so a badge row is never clipped.
        public var dayRowHeight: CGFloat?
        /// `nil` = `.fitMonth`.
        public var weekRows: LMKCalendarMonth.WeekRowPolicy?
        /// Whether leading / trailing days of the neighbouring months show (dimmed); `nil` = yes.
        public var showsAdjacentMonthDays: Bool?
        /// From the view's edges to the content; `nil` = `small` on every side.
        public var contentInsets: NSDirectionalEdgeInsets?
        /// Background, corners, border of every day cell (default clear).
        public var cellSurface: LMKSurfaceStyle
        /// `nil` = `.body`.
        public var numeralTextStyle: LMKTextStyle?
        /// Text style of a selected or today numeral; `nil` = `.bodyMedium`.
        public var numeralEmphasisTextStyle: LMKTextStyle?
        /// `nil` = `textPrimary`.
        public var numeralColor: UIColor?
        /// Numeral on a selected day; `nil` = `onAccent` for `filledCircle`, the accent otherwise.
        public var numeralSelectedColor: UIColor?
        /// Numeral on today; `nil` = the accent.
        public var numeralTodayColor: UIColor?
        /// Numeral on a disabled or adjacent-month day; `nil` = `textTertiary`.
        public var numeralDisabledColor: UIColor?
        /// Vertical offset of the numeral from the cell's center (negative = up); `nil` = -3.
        public var numeralCenterOffset: CGFloat?

        /// Selection and today
        /// `nil` = `.filledCircle`.
        public var selectionStyle: SelectionStyle?
        /// `nil` = the accent.
        public var selectionTint: UIColor?
        /// `nil` = `.tintedCircle`.
        public var todayStyle: TodayStyle?
        /// `nil` = the accent.
        public var todayTint: UIColor?
        /// Alpha of the today circle; `nil` = `alpha.xs`.
        public var todayCircleAlpha: CGFloat?
        /// Whether the today mark hides under a selection; `nil` = yes.
        public var todayHiddenUnderSelection: Bool?
        /// Radius of the selection and today circles; `nil` = 18.
        public var circleRadius: CGFloat?
        /// Ring stroke width; `nil` = 2.
        public var ringWidth: CGFloat?
        /// Corner radius of the rounded-rect styles; `nil` = `cornerRadius.medium`.
        public var roundedRectRadius: CGFloat?
        /// Alpha of the band drawn across the middle days of a range; `nil` = `alpha.xs`.
        public var rangeBandAlpha: CGFloat?

        /// Decorations
        /// `nil` = 5.
        public var dotSize: CGFloat?
        /// `nil` = 2.
        public var dotSpacing: CGFloat?
        /// `nil` = 3.
        public var maxDots: Int?
        /// Layered on count badges.
        public var badge: LMKBadgeView.Style
        /// `nil` = `symbolInline`.
        public var glyphSize: CGFloat?
        /// `nil` = `textSecondary`.
        public var glyphTint: UIColor?

        /// Paging
        /// `nil` = `.interactive`.
        public var paging: Paging?
        /// Touch band (pt) at each horizontal edge left to an outer page controller; `nil` = 24.
        public var reservedEdgeBandWidth: CGFloat?
        /// Fraction of the width a drag must cover to commit; `nil` = 0.4.
        public var commitFraction: CGFloat?
        /// Velocity (pt/s) past which a flick commits; `nil` = 300.
        public var flickVelocity: CGFloat?
        /// Translation (pt) a discrete swipe must cover; `nil` = `minimumTouchTarget`.
        public var discreteSwipeThreshold: CGFloat?
        /// `nil` = `animation.slow`.
        public var transitionDuration: TimeInterval?

        /// Behavior
        /// Selection haptic on a day tap; `nil` = yes.
        public var haptics: Bool?
        /// Press animation on day cells; `nil` = yes.
        public var pressAnimation: Bool?
        /// Cap for Dynamic Type inside the calendar (rows are fixed height); `nil` = `.extraExtraLarge`.
        public var maximumContentSizeCategory: UIContentSizeCategory?

        public init(
            accent: UIColor? = nil,
            headerLayout: HeaderLayout? = nil,
            headerHeight: CGFloat? = nil,
            headerSurface: LMKSurfaceStyle = LMKSurfaceStyle(),
            titleTextStyle: LMKTextStyle? = nil,
            titleColor: UIColor? = nil,
            titleIsTappable: Bool? = nil,
            showsTodayButton: Bool? = nil,
            navigationButton: LMKButton.Style = LMKButton.Style(),
            todayButton: LMKButton.Style = LMKButton.Style(),
            monthTitleTemplate: String? = nil,
            spacingAfterHeader: CGFloat? = nil,
            weekdayRowHeight: CGFloat? = nil,
            weekdayTextStyle: LMKTextStyle? = nil,
            weekdayColor: UIColor? = nil,
            weekdaySymbolStyle: LMKDateFormat.WeekdaySymbolStyle? = nil,
            spacingAfterWeekdays: CGFloat? = nil,
            dayRowHeight: CGFloat? = nil,
            weekRows: LMKCalendarMonth.WeekRowPolicy? = nil,
            showsAdjacentMonthDays: Bool? = nil,
            contentInsets: NSDirectionalEdgeInsets? = nil,
            cellSurface: LMKSurfaceStyle = LMKSurfaceStyle(),
            numeralTextStyle: LMKTextStyle? = nil,
            numeralEmphasisTextStyle: LMKTextStyle? = nil,
            numeralColor: UIColor? = nil,
            numeralSelectedColor: UIColor? = nil,
            numeralTodayColor: UIColor? = nil,
            numeralDisabledColor: UIColor? = nil,
            numeralCenterOffset: CGFloat? = nil,
            selectionStyle: SelectionStyle? = nil,
            selectionTint: UIColor? = nil,
            todayStyle: TodayStyle? = nil,
            todayTint: UIColor? = nil,
            todayCircleAlpha: CGFloat? = nil,
            todayHiddenUnderSelection: Bool? = nil,
            circleRadius: CGFloat? = nil,
            ringWidth: CGFloat? = nil,
            roundedRectRadius: CGFloat? = nil,
            rangeBandAlpha: CGFloat? = nil,
            dotSize: CGFloat? = nil,
            dotSpacing: CGFloat? = nil,
            maxDots: Int? = nil,
            badge: LMKBadgeView.Style = LMKBadgeView.Style(),
            glyphSize: CGFloat? = nil,
            glyphTint: UIColor? = nil,
            paging: Paging? = nil,
            reservedEdgeBandWidth: CGFloat? = nil,
            commitFraction: CGFloat? = nil,
            flickVelocity: CGFloat? = nil,
            discreteSwipeThreshold: CGFloat? = nil,
            transitionDuration: TimeInterval? = nil,
            haptics: Bool? = nil,
            pressAnimation: Bool? = nil,
            maximumContentSizeCategory: UIContentSizeCategory? = nil
        ) {
            self.accent = accent
            self.headerLayout = headerLayout
            self.headerHeight = headerHeight
            self.headerSurface = headerSurface
            self.titleTextStyle = titleTextStyle
            self.titleColor = titleColor
            self.titleIsTappable = titleIsTappable
            self.showsTodayButton = showsTodayButton
            self.navigationButton = navigationButton
            self.todayButton = todayButton
            self.monthTitleTemplate = monthTitleTemplate
            self.spacingAfterHeader = spacingAfterHeader
            self.weekdayRowHeight = weekdayRowHeight
            self.weekdayTextStyle = weekdayTextStyle
            self.weekdayColor = weekdayColor
            self.weekdaySymbolStyle = weekdaySymbolStyle
            self.spacingAfterWeekdays = spacingAfterWeekdays
            self.dayRowHeight = dayRowHeight
            self.weekRows = weekRows
            self.showsAdjacentMonthDays = showsAdjacentMonthDays
            self.contentInsets = contentInsets
            self.cellSurface = cellSurface
            self.numeralTextStyle = numeralTextStyle
            self.numeralEmphasisTextStyle = numeralEmphasisTextStyle
            self.numeralColor = numeralColor
            self.numeralSelectedColor = numeralSelectedColor
            self.numeralTodayColor = numeralTodayColor
            self.numeralDisabledColor = numeralDisabledColor
            self.numeralCenterOffset = numeralCenterOffset
            self.selectionStyle = selectionStyle
            self.selectionTint = selectionTint
            self.todayStyle = todayStyle
            self.todayTint = todayTint
            self.todayCircleAlpha = todayCircleAlpha
            self.todayHiddenUnderSelection = todayHiddenUnderSelection
            self.circleRadius = circleRadius
            self.ringWidth = ringWidth
            self.roundedRectRadius = roundedRectRadius
            self.rangeBandAlpha = rangeBandAlpha
            self.dotSize = dotSize
            self.dotSpacing = dotSpacing
            self.maxDots = maxDots
            self.badge = badge
            self.glyphSize = glyphSize
            self.glyphTint = glyphTint
            self.paging = paging
            self.reservedEdgeBandWidth = reservedEdgeBandWidth
            self.commitFraction = commitFraction
            self.flickVelocity = flickVelocity
            self.discreteSwipeThreshold = discreteSwipeThreshold
            self.transitionDuration = transitionDuration
            self.haptics = haptics
            self.pressAnimation = pressAnimation
            self.maximumContentSizeCategory = maximumContentSizeCategory
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                accent: other.accent ?? accent,
                headerLayout: other.headerLayout ?? headerLayout,
                headerHeight: other.headerHeight ?? headerHeight,
                headerSurface: headerSurface.merging(other.headerSurface),
                titleTextStyle: other.titleTextStyle ?? titleTextStyle,
                titleColor: other.titleColor ?? titleColor,
                titleIsTappable: other.titleIsTappable ?? titleIsTappable,
                showsTodayButton: other.showsTodayButton ?? showsTodayButton,
                navigationButton: navigationButton.merging(other.navigationButton),
                todayButton: todayButton.merging(other.todayButton),
                monthTitleTemplate: other.monthTitleTemplate ?? monthTitleTemplate,
                spacingAfterHeader: other.spacingAfterHeader ?? spacingAfterHeader,
                weekdayRowHeight: other.weekdayRowHeight ?? weekdayRowHeight,
                weekdayTextStyle: other.weekdayTextStyle ?? weekdayTextStyle,
                weekdayColor: other.weekdayColor ?? weekdayColor,
                weekdaySymbolStyle: other.weekdaySymbolStyle ?? weekdaySymbolStyle,
                spacingAfterWeekdays: other.spacingAfterWeekdays ?? spacingAfterWeekdays,
                dayRowHeight: other.dayRowHeight ?? dayRowHeight,
                weekRows: other.weekRows ?? weekRows,
                showsAdjacentMonthDays: other.showsAdjacentMonthDays ?? showsAdjacentMonthDays,
                contentInsets: other.contentInsets ?? contentInsets,
                cellSurface: cellSurface.merging(other.cellSurface),
                numeralTextStyle: other.numeralTextStyle ?? numeralTextStyle,
                numeralEmphasisTextStyle: other.numeralEmphasisTextStyle ?? numeralEmphasisTextStyle,
                numeralColor: other.numeralColor ?? numeralColor,
                numeralSelectedColor: other.numeralSelectedColor ?? numeralSelectedColor,
                numeralTodayColor: other.numeralTodayColor ?? numeralTodayColor,
                numeralDisabledColor: other.numeralDisabledColor ?? numeralDisabledColor,
                numeralCenterOffset: other.numeralCenterOffset ?? numeralCenterOffset,
                selectionStyle: other.selectionStyle ?? selectionStyle,
                selectionTint: other.selectionTint ?? selectionTint,
                todayStyle: other.todayStyle ?? todayStyle,
                todayTint: other.todayTint ?? todayTint,
                todayCircleAlpha: other.todayCircleAlpha ?? todayCircleAlpha,
                todayHiddenUnderSelection: other.todayHiddenUnderSelection ?? todayHiddenUnderSelection,
                circleRadius: other.circleRadius ?? circleRadius,
                ringWidth: other.ringWidth ?? ringWidth,
                roundedRectRadius: other.roundedRectRadius ?? roundedRectRadius,
                rangeBandAlpha: other.rangeBandAlpha ?? rangeBandAlpha,
                dotSize: other.dotSize ?? dotSize,
                dotSpacing: other.dotSpacing ?? dotSpacing,
                maxDots: other.maxDots ?? maxDots,
                badge: badge.merging(other.badge),
                glyphSize: other.glyphSize ?? glyphSize,
                glyphTint: other.glyphTint ?? glyphTint,
                paging: other.paging ?? paging,
                reservedEdgeBandWidth: other.reservedEdgeBandWidth ?? reservedEdgeBandWidth,
                commitFraction: other.commitFraction ?? commitFraction,
                flickVelocity: other.flickVelocity ?? flickVelocity,
                discreteSwipeThreshold: other.discreteSwipeThreshold ?? discreteSwipeThreshold,
                transitionDuration: other.transitionDuration ?? transitionDuration,
                haptics: other.haptics ?? haptics,
                pressAnimation: other.pressAnimation ?? pressAnimation,
                maximumContentSizeCategory: other.maximumContentSizeCategory ?? maximumContentSizeCategory
            )
        }
    }

    // MARK: - Strings

    nonisolated struct Strings: Sendable, Equatable {
        /// The Today button title, and the prefix VoiceOver reads before today's date.
        public var today: String
        public var previousMonthAccessibilityLabel: String
        public var nextMonthAccessibilityLabel: String
        /// Hint on the month title when it is tappable.
        public var monthTitleAccessibilityHint: String

        public init(
            today: String = LMKLocalized("monthCalendar.today"),
            previousMonthAccessibilityLabel: String = LMKLocalized("monthCalendar.previousMonth.accessibilityLabel"),
            nextMonthAccessibilityLabel: String = LMKLocalized("monthCalendar.nextMonth.accessibilityLabel"),
            monthTitleAccessibilityHint: String = LMKLocalized("monthCalendar.monthTitle.accessibilityHint")
        ) {
            self.today = today
            self.previousMonthAccessibilityLabel = previousMonthAccessibilityLabel
            self.nextMonthAccessibilityLabel = nextMonthAccessibilityLabel
            self.monthTitleAccessibilityHint = monthTitleAccessibilityHint
        }
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKMonthCalendarView`.
    var monthCalendar: LMKMonthCalendarView.Style {
        get { self[LMKMonthCalendarView.Style.self] }
        set { self[LMKMonthCalendarView.Style.self] = newValue }
    }
}
