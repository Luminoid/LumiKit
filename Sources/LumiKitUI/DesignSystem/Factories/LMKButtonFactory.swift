//
//  LMKButtonFactory.swift
//  LumiKit
//
//  Factory methods for creating styled buttons.
//

import UIKit

/// Factory methods for creating styled `UIButton` instances.
public enum LMKButtonFactory {
    public static func primary(title: String, target: Any?, action: Selector) -> UIButton {
        makeButton(title: title, backgroundColor: LMKColor.primary, target: target, action: action)
    }

    public static func secondary(title: String, target: Any?, action: Selector) -> UIButton {
        makeButton(title: title, backgroundColor: LMKColor.secondary, target: target, action: action)
    }

    public static func destructive(title: String, target: Any?, action: Selector) -> UIButton {
        makeButton(title: title, backgroundColor: LMKColor.error, target: target, action: action)
    }

    public static func warning(title: String, target: Any?, action: Selector) -> UIButton {
        makeButton(title: title, backgroundColor: LMKColor.warning, target: target, action: action)
    }

    public static func outline(title: String, color: UIColor = LMKColor.primary, target: Any?, action: Selector) -> UIButton {
        var config = UIButton.Configuration.tinted()
        config.title = title
        config.baseBackgroundColor = color
        config.baseForegroundColor = color
        config.cornerStyle = .fixed
        config.background.cornerRadius = LMKCornerRadius.small
        config.contentInsets = NSDirectionalEdgeInsets(
            top: LMKSpacing.buttonPaddingVertical,
            leading: LMKSpacing.buttonPaddingHorizontal,
            bottom: LMKSpacing.buttonPaddingVertical,
            trailing: LMKSpacing.buttonPaddingHorizontal,
        )
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = LMKTypography.bodyMedium
            return outgoing
        }

        let button = UIButton(configuration: config)
        button.addTarget(target, action: action, for: .touchUpInside)
        button.addTarget(nil, action: #selector(UIButton.lmk_animatePress), for: .touchDown)
        return button
    }

    public static func text(title: String, color: UIColor = LMKColor.primary, target: Any?, action: Selector) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.title = title
        config.baseForegroundColor = color
        config.contentInsets = NSDirectionalEdgeInsets(
            top: LMKSpacing.buttonPaddingVertical,
            leading: LMKSpacing.buttonPaddingHorizontal,
            bottom: LMKSpacing.buttonPaddingVertical,
            trailing: LMKSpacing.buttonPaddingHorizontal,
        )
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = LMKTypography.bodyMedium
            return outgoing
        }

        let button = UIButton(configuration: config)
        button.addTarget(target, action: action, for: .touchUpInside)
        return button
    }

    public static func success(title: String, target: Any?, action: Selector) -> UIButton {
        makeButton(title: title, backgroundColor: LMKColor.success, target: target, action: action)
    }

    public static func info(title: String, target: Any?, action: Selector) -> UIButton {
        makeButton(title: title, backgroundColor: LMKColor.info, target: target, action: action)
    }

    private static func makeButton(
        title: String,
        backgroundColor: UIColor,
        foregroundColor: UIColor = LMKColor.white,
        target: Any?,
        action: Selector,
    ) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseBackgroundColor = backgroundColor
        config.baseForegroundColor = foregroundColor
        config.cornerStyle = .fixed
        config.background.cornerRadius = LMKCornerRadius.small
        config.contentInsets = NSDirectionalEdgeInsets(
            top: LMKSpacing.buttonPaddingVertical,
            leading: LMKSpacing.buttonPaddingHorizontal,
            bottom: LMKSpacing.buttonPaddingVertical,
            trailing: LMKSpacing.buttonPaddingHorizontal,
        )
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = LMKTypography.bodyMedium
            return outgoing
        }

        let button = UIButton(configuration: config)
        button.addTarget(target, action: action, for: .touchUpInside)
        button.addTarget(nil, action: #selector(UIButton.lmk_animatePress), for: .touchDown)
        return button
    }
}
