//
//  LMKDeviceHelper.swift
//  LumiKit
//
//  Device type and screen size classification.
//

import UIKit

/// Device type classification.
public enum LMKDeviceType: Sendable {
    case iPhone
    case iPad
    case macCatalyst
    case other
}

/// Screen size category for adaptive layouts.
public enum LMKScreenSize: Sendable {
    /// iPhone SE, mini
    case compact
    /// Standard iPhone
    case regular
    /// iPhone Plus/Max
    case large
    /// iPad, Mac Catalyst
    case extraLarge
}

/// Device type and screen classification helpers.
public enum LMKDeviceHelper {
    /// Current device type.
    public static var deviceType: LMKDeviceType {
        #if targetEnvironment(macCatalyst)
            .macCatalyst
        #else
            switch UIDevice.current.userInterfaceIdiom {
            case .phone: .iPhone
            case .pad: .iPad
            default: .other
            }
        #endif
    }

    /// Whether the current device is iPad.
    public static var isIPad: Bool { deviceType == .iPad }

    /// Whether running as Mac Catalyst.
    public static var isMacCatalyst: Bool { deviceType == .macCatalyst }

    /// Screen size category based on screen bounds.
    public static var screenSize: LMKScreenSize {
        let screenBounds = LMKSceneUtil.getKeyWindow()?.windowScene?.screen.bounds ?? LMKSceneUtil.getKeyWindow()?.screen.bounds ?? .zero
        let longestSide = max(screenBounds.width, screenBounds.height)
        switch deviceType {
        case .iPad, .macCatalyst:
            return .extraLarge
        case .iPhone:
            if longestSide <= 667 { return .compact }
            else if longestSide <= 844 { return .regular }
            else { return .large }
        case .other:
            return .regular
        }
    }

    /// Whether the device has a notch or Dynamic Island (safe area top > 20).
    public static var hasTopNotch: Bool {
        guard let window = LMKSceneUtil.getKeyWindow() else { return false }
        return window.safeAreaInsets.top > 20
    }
}
