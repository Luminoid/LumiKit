//
//  LMKDeviceHelper.swift
//  LumiKit
//
//  Device type and layout-size classification.
//

import UIKit

/// Device type classification. Nonisolated because device type is constant at runtime.
public nonisolated enum LMKDeviceType: Sendable, Equatable {
    case iPhone
    case iPad
    case macCatalyst
    case other
}

/// Layout-size category for adaptive layouts.
///
/// Classified from the canvas the content actually has (window or root view
/// bounds plus size classes), never from the device model, so a resizable
/// window on iPad, iPhone Mirroring on the Mac, and both iPhone Duo displays
/// land in the tier their real width earns. Nonisolated: a pure value.
public nonisolated enum LMKScreenSize: Sendable, Equatable {
    /// Portrait width ≤ 375pt: iPhone SE, iPhone 13 mini, iPhone XS / 11 Pro,
    /// iPad Slide Over (320pt).
    case compact
    /// Portrait width ≤ 402pt: iPhone 16e / 17e (390), iPhone 15 / 16 (393),
    /// iPhone 16 Pro / 17 / 17 Pro / 18 Pro (402).
    case regular
    /// Portrait width > 402pt: iPhone 11 / XR (414), iPhone Air (420),
    /// iPhone Plus (430), iPhone Pro Max (440), iPhone Duo cover display (466).
    case large
    /// Regular width AND regular height: iPad, Mac Catalyst, wide iPad
    /// multitasking windows, iPhone Duo inner display (669 × 951pt).
    case extraLarge
}

/// Device type and layout-size classification helpers.
///
/// Prefer ``screenSize(for:)`` from a view controller's root view over the
/// static ``screenSize``: it reads that view's own traits and bounds, which is
/// what a split-view child, a resizable iPad window, or an iPhone Duo scene
/// actually has. Re-read it from `viewWillTransition(to:with:)` or a
/// `registerForTraitChanges` handler — the tier changes when the window
/// resizes, the device rotates, or iPhone Duo folds.
public enum LMKDeviceHelper {
    // MARK: - Breakpoints

    /// Widest portrait width classified as ``LMKScreenSize/compact`` (SE, mini).
    public nonisolated static let compactMaxWidth: CGFloat = 375
    /// Widest portrait width classified as ``LMKScreenSize/regular`` (18 Pro is 402).
    public nonisolated static let regularMaxWidth: CGFloat = 402

    // MARK: - Device Type

    /// Current device type. Nonisolated because device type never changes at runtime.
    public nonisolated static var deviceType: LMKDeviceType {
        #if targetEnvironment(macCatalyst)
            .macCatalyst
        #else
            MainActor.assumeIsolated {
                switch UIDevice.current.userInterfaceIdiom {
                case .phone: .iPhone
                case .pad: .iPad
                default: .other
                }
            }
        #endif
    }

    /// Whether the current device is iPad.
    public nonisolated static var isIPad: Bool { deviceType == .iPad }

    /// Whether running as Mac Catalyst.
    public nonisolated static var isMacCatalyst: Bool { deviceType == .macCatalyst }

    // MARK: - Screen Size

    /// Layout-size category of the key window.
    ///
    /// Reads the key window's bounds and traits (not `UIScreen`), so a
    /// resized iPad window or an unfolded iPhone Duo reports its current tier.
    /// Without a key window (early launch, tests) falls back to
    /// ``LMKScreenSize/extraLarge`` on iPad / Mac and ``LMKScreenSize/regular``
    /// elsewhere.
    public static var screenSize: LMKScreenSize {
        guard let window = LMKSceneUtil.getKeyWindow() else {
            switch deviceType {
            case .iPad, .macCatalyst: return .extraLarge
            case .iPhone, .other: return .regular
            }
        }
        return screenSize(for: window)
    }

    /// Layout-size category for the environment of `view`.
    ///
    /// Pass a view controller's root view (or a window). Uses the view's own
    /// trait collection and bounds; a view that has not been laid out yet
    /// (empty bounds) borrows its window's bounds instead.
    public static func screenSize(for view: UIView) -> LMKScreenSize {
        let size = view.bounds.isEmpty ? (view.window?.bounds.size ?? .zero) : view.bounds.size
        let traits = view.traitCollection
        return screenSize(
            forWindowSize: size,
            horizontalSizeClass: traits.horizontalSizeClass,
            verticalSizeClass: traits.verticalSizeClass
        )
    }

    /// Pure classification from a canvas size and its size classes.
    ///
    /// - Regular width **and** regular height → ``LMKScreenSize/extraLarge``
    ///   (iPad, Mac, wide multitasking windows, iPhone Duo inner display).
    /// - Otherwise by the shortest side (the portrait width, so rotation does
    ///   not flip the tier): ≤ ``compactMaxWidth`` → compact,
    ///   ≤ ``regularMaxWidth`` → regular, wider → large. A Pro Max in landscape
    ///   is regular-width but compact-height, so it stays ``LMKScreenSize/large``.
    /// - Unspecified size classes (detached views) classify by width only and
    ///   never reach `extraLarge`.
    public nonisolated static func screenSize(
        forWindowSize size: CGSize,
        horizontalSizeClass: UIUserInterfaceSizeClass,
        verticalSizeClass: UIUserInterfaceSizeClass
    ) -> LMKScreenSize {
        if horizontalSizeClass == .regular, verticalSizeClass == .regular {
            return .extraLarge
        }
        let portraitWidth = min(size.width, size.height)
        if portraitWidth <= compactMaxWidth {
            return .compact
        } else if portraitWidth <= regularMaxWidth {
            return .regular
        } else {
            return .large
        }
    }

    // MARK: - Display Cutout

    /// Whether the key window currently has a notch or Dynamic Island above
    /// its content (top safe-area inset beyond the 20pt status bar), iPhone only.
    ///
    /// Orientation-dependent by design: in landscape the cutout moves to a
    /// side edge and this returns `false`. iPad's 24pt status bar never counts.
    /// iPhone Duo places its camera region beside the status bar and can
    /// report asymmetric side insets; read `safeAreaInsets` per edge rather
    /// than assuming the cutout is top-only.
    public static var hasTopNotch: Bool {
        guard deviceType == .iPhone, let window = LMKSceneUtil.getKeyWindow() else { return false }
        return window.safeAreaInsets.top > 20
    }
}
