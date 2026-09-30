//
//  LMKCalendarDayDecoration.swift
//  LumiKit
//
//  Per-day content a host attaches to a month calendar: presence dots, count
//  badges, a glyph beside the numeral, a VoiceOver value, and enablement.
//

import UIKit

/// What a day cell shows besides its numeral.
///
/// ```swift
/// decorations[day] = LMKCalendarDayDecoration(
///     dots: [LMKColor.primary, LMKColor.info],
///     accessibilityValue: "2 events"
/// )
/// ```
public nonisolated struct LMKCalendarDayDecoration: Sendable, Equatable {
    /// A small count or text capsule under the numeral.
    public struct Badge: Sendable, Equatable {
        public var text: String
        /// `nil` = the calendar's accent.
        public var color: UIColor?

        public init(text: String, color: UIColor? = nil) {
            self.text = text
            self.color = color
        }

        /// A numeric badge; `0` or less yields `nil` so callers can `compactMap`.
        public static func count(_ count: Int, color: UIColor? = nil) -> Self? {
            count > 0 ? Self(text: String(count), color: color) : nil
        }
    }

    /// Presence dots under the numeral, in order; the view caps the count at `maxDots`.
    public var dots: [UIColor]
    /// Count / text capsules under the numeral.
    public var badges: [Badge]
    /// A glyph beside the numeral (a weather symbol).
    public var glyph: UIImage?
    /// `nil` = `textSecondary`.
    public var glyphTint: UIColor?
    /// What VoiceOver reads after the date ("3 events").
    public var accessibilityValue: String?
    /// `false` renders the day dimmed and ignores taps.
    public var isEnabled: Bool

    public init(
        dots: [UIColor] = [],
        badges: [Badge] = [],
        glyph: UIImage? = nil,
        glyphTint: UIColor? = nil,
        accessibilityValue: String? = nil,
        isEnabled: Bool = true
    ) {
        self.dots = dots
        self.badges = badges
        self.glyph = glyph
        self.glyphTint = glyphTint
        self.accessibilityValue = accessibilityValue
        self.isEnabled = isEnabled
    }

    /// No decoration.
    public static let none = Self()

    /// Whether anything is drawn besides the numeral.
    public var isEmpty: Bool {
        dots.isEmpty && badges.isEmpty && glyph == nil
    }
}
