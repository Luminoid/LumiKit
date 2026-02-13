//
//  LMKButtonFactory.swift
//  LumiKit
//
//  Factory methods for creating styled buttons.
//

import UIKit

/// Factory methods for creating styled `UIButton` instances.
@MainActor
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

    private static func makeButton(
        title: String,
        backgroundColor: UIColor,
        target: Any?,
        action: Selector
    ) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = backgroundColor
        button.setTitleColor(LMKColor.white, for: .normal)
        button.titleLabel?.font = LMKTypography.bodyMedium
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.7
        button.titleLabel?.numberOfLines = 1
        button.layer.cornerRadius = LMKCornerRadius.small

        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = LMKColor.white
        config.contentInsets = NSDirectionalEdgeInsets(
            top: LMKSpacing.buttonPaddingVertical,
            leading: LMKSpacing.buttonPaddingHorizontal,
            bottom: LMKSpacing.buttonPaddingVertical,
            trailing: LMKSpacing.buttonPaddingHorizontal
        )
        button.configuration = config

        button.addTarget(target, action: action, for: .touchUpInside)
        button.addTarget(nil, action: #selector(UIButton.lmk_animatePress), for: .touchDown)
        button.addTarget(nil, action: #selector(UIButton.lmk_animateRelease), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        return button
    }
}
