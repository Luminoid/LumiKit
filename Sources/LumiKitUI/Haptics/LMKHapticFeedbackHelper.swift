//
//  LMKHapticFeedbackHelper.swift
//  LumiKit
//
//  Centralized haptic feedback helper.
//

import UIKit

/// Centralized haptic feedback helper.
public enum LMKHapticFeedbackHelper {
    private static let impactLight = UIImpactFeedbackGenerator(style: .light)
    private static let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private static let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private static let notificationSuccess = UINotificationFeedbackGenerator()
    private static let notificationWarning = UINotificationFeedbackGenerator()
    private static let notificationError = UINotificationFeedbackGenerator()
    private static let selectionGenerator = UISelectionFeedbackGenerator()

    /// Success feedback (action completed).
    public static func success() { notificationSuccess.notificationOccurred(.success) }
    /// Warning feedback (caution state).
    public static func warning() { notificationWarning.notificationOccurred(.warning) }
    /// Error feedback (validation failure).
    public static func error() { notificationError.notificationOccurred(.error) }
    /// Selection feedback (item selected, picker changed).
    public static func selection() { selectionGenerator.selectionChanged() }
    /// Light impact (subtle interaction).
    public static func light() { impactLight.impactOccurred() }
    /// Medium impact (button press).
    public static func medium() { impactMedium.impactOccurred() }
    /// Heavy impact (important action).
    public static func heavy() { impactHeavy.impactOccurred() }

    /// Prepare all generators for better responsiveness.
    public static func prepare() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        notificationSuccess.prepare()
        notificationWarning.prepare()
        notificationError.prepare()
        selectionGenerator.prepare()
    }
}
