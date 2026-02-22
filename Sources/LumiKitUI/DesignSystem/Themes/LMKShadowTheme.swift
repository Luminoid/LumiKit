//
//  LMKShadowTheme.swift
//  LumiKit
//
//  Shadow configuration for customizing shadow styles.
//

import UIKit

/// Shadow configuration for the Lumi design system.
///
/// Override at app launch to customize shadows:
/// ```swift
/// LMKThemeManager.shared.apply(shadow: .init(cellCardRadius: 8, cardRadius: 12))
/// ```
public nonisolated struct LMKShadowTheme: Sendable {
    /// Standard shadow opacity for icon overlays (e.g. category icon on photo).
    public var iconOverlayOpacity: Float

    // MARK: - Cell Card Shadow

    public var cellCardOffset: CGSize
    public var cellCardRadius: CGFloat
    public var cellCardOpacity: Float
    public var cellCardLightAlpha: CGFloat
    public var cellCardDarkAlpha: CGFloat

    // MARK: - Card Shadow

    public var cardOffset: CGSize
    public var cardRadius: CGFloat
    public var cardOpacity: Float
    public var cardLightAlpha: CGFloat
    public var cardDarkAlpha: CGFloat

    // MARK: - Button Shadow

    public var buttonOffset: CGSize
    public var buttonRadius: CGFloat
    public var buttonOpacity: Float
    public var buttonLightAlpha: CGFloat
    public var buttonDarkAlpha: CGFloat

    // MARK: - Small Shadow

    public var smallOffset: CGSize
    public var smallRadius: CGFloat
    public var smallOpacity: Float
    public var smallLightAlpha: CGFloat
    public var smallDarkAlpha: CGFloat

    public init(
        iconOverlayOpacity: Float = 0.8,
        cellCardOffset: CGSize = CGSize(width: 0, height: 2),
        cellCardRadius: CGFloat = 6,
        cellCardOpacity: Float = 0.5,
        cellCardLightAlpha: CGFloat = 0.1,
        cellCardDarkAlpha: CGFloat = 0.3,
        cardOffset: CGSize = CGSize(width: 0, height: 2),
        cardRadius: CGFloat = 8,
        cardOpacity: Float = 1.0,
        cardLightAlpha: CGFloat = 0.1,
        cardDarkAlpha: CGFloat = 0.3,
        buttonOffset: CGSize = CGSize(width: 0, height: 2),
        buttonRadius: CGFloat = 4,
        buttonOpacity: Float = 1.0,
        buttonLightAlpha: CGFloat = 0.15,
        buttonDarkAlpha: CGFloat = 0.4,
        smallOffset: CGSize = CGSize(width: 0, height: 1),
        smallRadius: CGFloat = 2,
        smallOpacity: Float = 1.0,
        smallLightAlpha: CGFloat = 0.1,
        smallDarkAlpha: CGFloat = 0.3
    ) {
        self.iconOverlayOpacity = iconOverlayOpacity
        self.cellCardOffset = cellCardOffset
        self.cellCardRadius = cellCardRadius
        self.cellCardOpacity = cellCardOpacity
        self.cellCardLightAlpha = cellCardLightAlpha
        self.cellCardDarkAlpha = cellCardDarkAlpha
        self.cardOffset = cardOffset
        self.cardRadius = cardRadius
        self.cardOpacity = cardOpacity
        self.cardLightAlpha = cardLightAlpha
        self.cardDarkAlpha = cardDarkAlpha
        self.buttonOffset = buttonOffset
        self.buttonRadius = buttonRadius
        self.buttonOpacity = buttonOpacity
        self.buttonLightAlpha = buttonLightAlpha
        self.buttonDarkAlpha = buttonDarkAlpha
        self.smallOffset = smallOffset
        self.smallRadius = smallRadius
        self.smallOpacity = smallOpacity
        self.smallLightAlpha = smallLightAlpha
        self.smallDarkAlpha = smallDarkAlpha
    }
}
