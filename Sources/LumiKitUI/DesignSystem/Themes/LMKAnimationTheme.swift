//
//  LMKAnimationTheme.swift
//  LumiKit
//
//  Animation timing configuration for customizing durations and spring parameters.
//

import UIKit

/// Animation timing configuration for the Lumi design system.
///
/// Override at app launch to customize animation timings:
/// ```swift
/// LMKThemeManager.shared.apply(animation: .init(modalPresentation: 0.25))
/// ```
public nonisolated struct LMKAnimationTheme: Sendable {
    public var screenTransition: TimeInterval
    public var modalPresentation: TimeInterval
    public var actionSheet: TimeInterval
    public var alert: TimeInterval
    /// Short UI transitions (menus, overlays).
    public var uiShort: TimeInterval
    public var buttonPress: TimeInterval
    public var successFeedback: TimeInterval
    public var errorShake: TimeInterval
    public var photoLoad: TimeInterval
    public var listUpdate: TimeInterval
    public var listInsertDelete: TimeInterval
    public var cardExpand: TimeInterval
    /// Damping for smooth spring animations.
    public var springDamping: CGFloat

    public init(
        screenTransition: TimeInterval = 0.35,
        modalPresentation: TimeInterval = 0.3,
        actionSheet: TimeInterval = 0.25,
        alert: TimeInterval = 0.2,
        uiShort: TimeInterval = 0.15,
        buttonPress: TimeInterval = 0.1,
        successFeedback: TimeInterval = 0.5,
        errorShake: TimeInterval = 0.4,
        photoLoad: TimeInterval = 0.15,
        listUpdate: TimeInterval = 0.3,
        listInsertDelete: TimeInterval = 0.3,
        cardExpand: TimeInterval = 0.3,
        springDamping: CGFloat = 0.8
    ) {
        self.screenTransition = screenTransition
        self.modalPresentation = modalPresentation
        self.actionSheet = actionSheet
        self.alert = alert
        self.uiShort = uiShort
        self.buttonPress = buttonPress
        self.successFeedback = successFeedback
        self.errorShake = errorShake
        self.photoLoad = photoLoad
        self.listUpdate = listUpdate
        self.listInsertDelete = listInsertDelete
        self.cardExpand = cardExpand
        self.springDamping = springDamping
    }
}
