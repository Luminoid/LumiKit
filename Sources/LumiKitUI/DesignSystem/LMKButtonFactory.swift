//
//  LMKButtonFactory.swift
//  LumiKit
//
//  Factory methods for creating styled buttons.
//

import UIKit

/// Factory methods for creating styled `UIButton` instances.
public enum LMKButtonFactory {
    private static let minimumScaleFactor: CGFloat = 0.7

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
        action: Selector,
    ) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseBackgroundColor = backgroundColor
        config.baseForegroundColor = LMKColor.white
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
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = minimumScaleFactor
        button.titleLabel?.numberOfLines = 1
        button.addTarget(target, action: action, for: .touchUpInside)
        button.addTarget(nil, action: #selector(UIButton.lmk_animatePress), for: .touchDown)
        return button
    }
}
