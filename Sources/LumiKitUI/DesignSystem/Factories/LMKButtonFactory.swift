//
//  LMKButtonFactory.swift
//  LumiKit
//
//  Factory methods for creating styled buttons.
//

import UIKit

/// Semantic roles for button styling.
public enum LMKButtonRole {
    case primary, secondary, destructive, warning, success, info
}

/// Factory methods for creating styled `LMKButton` instances with target-action pattern.
public enum LMKButtonFactory {
    // MARK: - Filled Buttons

    /// Create a filled button for the given semantic role.
    public static func filled(role: LMKButtonRole, title: String, target: Any?, action: Selector) -> LMKButton {
        makeButton(title: title, color: color(for: role), target: target, action: action)
    }

    // MARK: - Outlined Buttons

    /// Create an outlined button for the given semantic role.
    public static func outlined(role: LMKButtonRole, title: String, target: Any?, action: Selector) -> LMKButton {
        makeOutlinedButton(title: title, color: color(for: role), target: target, action: action)
    }

    // MARK: - Private Helpers

    private static func color(for role: LMKButtonRole) -> UIColor {
        switch role {
        case .primary: LMKColor.primary
        case .secondary: LMKColor.secondary
        case .destructive: LMKColor.error
        case .warning: LMKColor.warning
        case .success: LMKColor.success
        case .info: LMKColor.info
        }
    }

    private static func makeButton(title: String, color: UIColor, target: Any?, action: Selector) -> LMKButton {
        let button = LMKButton(title: title, style: .filled(color))
        button.addTarget(target, action: action, for: .touchUpInside)
        return button
    }

    private static func makeOutlinedButton(title: String, color: UIColor, target: Any?, action: Selector) -> LMKButton {
        let button = LMKButton(title: title, style: .outlined(color))
        button.addTarget(target, action: action, for: .touchUpInside)
        return button
    }
}
