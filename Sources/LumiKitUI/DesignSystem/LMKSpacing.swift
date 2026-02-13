//
//  LMKSpacing.swift
//  LumiKit
//
//  Spacing tokens (4pt base unit).
//

import UIKit

/// General spacing tokens for the Lumi design system.
public enum LMKSpacing {
    /// Very tight spacing (stacked labels) — 2pt.
    public static let xxs: CGFloat = 2
    /// Tight spacing (icon to text) — 4pt.
    public static let xs: CGFloat = 4
    /// Standard spacing (elements in cards) — 8pt.
    public static let small: CGFloat = 8
    /// Comfortable spacing (between sections) — 12pt.
    public static let medium: CGFloat = 12
    /// Section spacing (card padding) — 16pt.
    public static let large: CGFloat = 16
    /// Large spacing (between major sections) — 20pt.
    public static let xl: CGFloat = 20
    /// Screen margins, large gaps — 24pt.
    public static let xxl: CGFloat = 24

    /// Content horizontal padding for headers, list content, cards.
    /// Scales based on device size (iPhone → iPad → Mac Catalyst).
    public static var cardPadding: CGFloat {
        #if targetEnvironment(macCatalyst)
            return 48
        #elseif os(iOS)
            if UIDevice.current.userInterfaceIdiom == .pad {
                let screenSize = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
                if screenSize <= 768 { return 24 }
                else if screenSize <= 820 { return 28 }
                else if screenSize <= 834 { return 32 }
                else if screenSize <= 1024 { return 36 }
                else { return 40 }
            }
            return 16
        #else
            return 16
        #endif
    }

    /// Cell vertical padding (larger on bigger screens).
    public static var cellPaddingVertical: CGFloat {
        #if targetEnvironment(macCatalyst)
            return 16
        #elseif os(iOS)
            if UIDevice.current.userInterfaceIdiom == .pad {
                let screenSize = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
                if screenSize <= 768 { return 12 }
                if screenSize <= 834 { return 14 }
                return 16
            }
            return 8
        #else
            return 12
        #endif
    }

    public static let buttonPaddingVertical: CGFloat = 12
    public static let buttonPaddingHorizontal: CGFloat = 16
    /// Between icons — 6pt.
    public static let iconSpacing: CGFloat = 6
    /// Icon to text — 8pt.
    public static let iconToText: CGFloat = 8
}
