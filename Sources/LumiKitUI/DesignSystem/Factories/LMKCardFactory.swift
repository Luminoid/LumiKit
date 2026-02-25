//
//  LMKCardFactory.swift
//  LumiKit
//
//  Factory for creating card views with standard shadow and corner radius.
//

import UIKit

/// Factory for creating card views with standard shadow and corner radius.
public enum LMKCardFactory {
    /// Create a card view with secondary background, medium corner radius, and cell card shadow.
    public static func cardView() -> UIView {
        let view = UIView()
        view.backgroundColor = LMKColor.backgroundSecondary
        view.layer.cornerRadius = LMKCornerRadius.medium
        view.layer.masksToBounds = false

        let shadow = LMKShadow.cellCard()
        view.layer.shadowColor = shadow.color.cgColor
        view.layer.shadowOffset = shadow.offset
        view.layer.shadowRadius = shadow.radius
        view.layer.shadowOpacity = shadow.opacity

        return view
    }

    /// Create an elevated card view with stronger shadow.
    public static func elevatedCardView() -> UIView {
        let view = UIView()
        view.backgroundColor = LMKColor.backgroundSecondary
        view.layer.cornerRadius = LMKCornerRadius.medium
        view.layer.masksToBounds = false

        let shadow = LMKShadow.card()
        view.layer.shadowColor = shadow.color.cgColor
        view.layer.shadowOffset = shadow.offset
        view.layer.shadowRadius = shadow.radius
        view.layer.shadowOpacity = shadow.opacity

        return view
    }

    /// Create a flat card view with no shadow.
    public static func flatCardView() -> UIView {
        let view = UIView()
        view.backgroundColor = LMKColor.backgroundSecondary
        view.layer.cornerRadius = LMKCornerRadius.medium
        view.layer.masksToBounds = true
        return view
    }
}
