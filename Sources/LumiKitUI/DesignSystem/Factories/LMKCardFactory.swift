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
    ///
    /// - Note: `layer.shadowColor` stores a CGColor snapshot. Re-apply shadow via
    ///   `lmk_applyShadow(_:)` in `traitCollectionDidChange` for dark mode support.
    public static func cardView() -> UIView {
        makeCard(shadow: LMKShadow.cellCard())
    }

    /// Create an elevated card view with stronger shadow.
    ///
    /// - Note: `layer.shadowColor` stores a CGColor snapshot. Re-apply shadow via
    ///   `lmk_applyShadow(_:)` in `traitCollectionDidChange` for dark mode support.
    public static func elevatedCardView() -> UIView {
        makeCard(shadow: LMKShadow.card())
    }

    // MARK: - Helpers

    private static func makeCard(shadow: LMKShadowStyle) -> UIView {
        let view = UIView()
        view.backgroundColor = LMKColor.backgroundSecondary
        view.layer.cornerRadius = LMKCornerRadius.medium
        view.lmk_applyShadow(shadow)
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
