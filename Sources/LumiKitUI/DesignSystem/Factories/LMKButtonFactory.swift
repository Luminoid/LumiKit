//
//  LMKButtonFactory.swift
//  LumiKit
//
//  Factory methods for creating styled buttons.
//

import UIKit

/// Factory methods for creating styled `LMKButton` instances with target-action pattern.
public enum LMKButtonFactory {
    // MARK: - Filled Buttons

    public static func primary(title: String, target: Any?, action: Selector) -> LMKButton {
        makeButton(title: title, color: LMKColor.primary, target: target, action: action)
    }

    public static func secondary(title: String, target: Any?, action: Selector) -> LMKButton {
        makeButton(title: title, color: LMKColor.secondary, target: target, action: action)
    }

    public static func destructive(title: String, target: Any?, action: Selector) -> LMKButton {
        makeButton(title: title, color: LMKColor.error, target: target, action: action)
    }

    public static func warning(title: String, target: Any?, action: Selector) -> LMKButton {
        makeButton(title: title, color: LMKColor.warning, target: target, action: action)
    }

    public static func success(title: String, target: Any?, action: Selector) -> LMKButton {
        makeButton(title: title, color: LMKColor.success, target: target, action: action)
    }

    public static func info(title: String, target: Any?, action: Selector) -> LMKButton {
        makeButton(title: title, color: LMKColor.info, target: target, action: action)
    }

    // MARK: - Outlined Buttons

    public static func primaryOutlined(title: String, target: Any?, action: Selector) -> LMKButton {
        makeOutlinedButton(title: title, color: LMKColor.primary, target: target, action: action)
    }

    public static func secondaryOutlined(title: String, target: Any?, action: Selector) -> LMKButton {
        makeOutlinedButton(title: title, color: LMKColor.secondary, target: target, action: action)
    }

    public static func destructiveOutlined(title: String, target: Any?, action: Selector) -> LMKButton {
        makeOutlinedButton(title: title, color: LMKColor.error, target: target, action: action)
    }

    public static func warningOutlined(title: String, target: Any?, action: Selector) -> LMKButton {
        makeOutlinedButton(title: title, color: LMKColor.warning, target: target, action: action)
    }

    public static func successOutlined(title: String, target: Any?, action: Selector) -> LMKButton {
        makeOutlinedButton(title: title, color: LMKColor.success, target: target, action: action)
    }

    public static func infoOutlined(title: String, target: Any?, action: Selector) -> LMKButton {
        makeOutlinedButton(title: title, color: LMKColor.info, target: target, action: action)
    }

    // MARK: - Private Helpers

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
