//
//  LMKHapticFeedbackHelper.swift
//  LumiKit
//
//  Centralized haptic feedback helper.
//

import UIKit

/// Centralized haptic feedback helper.
///
/// On Mac Catalyst, haptic feedback is a no-op (Taptic Engine is not available).
/// No audible or visual alternative is provided — callers should handle
/// Mac-specific feedback if needed.
///
/// Call `prepare` methods when a haptic interaction is anticipated (e.g. when a view appears
/// or a gesture begins) to reduce latency. The Taptic Engine stays prepared for ~1–2 seconds.
///
/// ```swift
/// // In viewDidAppear or gesture recognizer .began:
/// LMKHapticFeedbackHelper.prepareNotification()
///
/// // When the action completes:
/// LMKHapticFeedbackHelper.success()
/// ```
public enum LMKHapticFeedbackHelper {
    private static let impactLight = { UIImpactFeedbackGenerator(style: .light) }()
    private static let impactMedium = { UIImpactFeedbackGenerator(style: .medium) }()
    private static let impactHeavy = { UIImpactFeedbackGenerator(style: .heavy) }()
    private static let notificationGenerator = { UINotificationFeedbackGenerator() }()
    private static let selectionGenerator = { UISelectionFeedbackGenerator() }()

    // MARK: - Feedback

    /// Success feedback (action completed).
    public static func success() { notificationGenerator.notificationOccurred(.success) }
    /// Warning feedback (caution state).
    public static func warning() { notificationGenerator.notificationOccurred(.warning) }
    /// Error feedback (validation failure).
    public static func error() { notificationGenerator.notificationOccurred(.error) }
    /// Selection feedback (item selected, picker changed).
    public static func selection() { selectionGenerator.selectionChanged() }
    /// Light impact (subtle interaction).
    public static func light() { impactLight.impactOccurred() }
    /// Medium impact (button press).
    public static func medium() { impactMedium.impactOccurred() }
    /// Heavy impact (important action).
    public static func heavy() { impactHeavy.impactOccurred() }

    // MARK: - Prepare

    /// Prepare the notification generator (success/warning/error).
    /// Call ~1–2s before the anticipated feedback.
    public static func prepareNotification() { notificationGenerator.prepare() }

    /// Prepare the selection generator.
    /// Call when a scrollable picker or segmented control appears.
    public static func prepareSelection() { selectionGenerator.prepare() }

    /// Prepare a specific impact generator.
    /// Call before an anticipated tap or press interaction.
    public static func prepareImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        switch style {
        case .light: impactLight.prepare()
        case .medium: impactMedium.prepare()
        case .heavy: impactHeavy.prepare()
        default: impactMedium.prepare()
        }
    }

    /// Prepare all generators. Use sparingly — prefer targeted prepare methods.
    public static func prepare() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }
}
