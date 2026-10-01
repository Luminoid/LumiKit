//
//  LMKScene.swift
//  LumiKit
//
//  Scene and window helpers: the active scene, the key window, the view
//  controller to present from, closing a scene, and Mac window setup.
//

import UIKit

/// Scene and window helpers.
public enum LMKScene {
    /// The scene the user is working in: the foreground-active window scene, else a foreground-
    /// inactive one, else any connected window scene.
    public static var activeWindowScene: UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first { $0.activationState == .foregroundActive }
            ?? scenes.first { $0.activationState == .foregroundInactive }
            ?? scenes.first
    }

    /// The key window: the active scene's key window, else the first key window of any scene,
    /// else the first window of any scene.
    ///
    /// The one key-window lookup in the kit; `UIViewController.lmk_topViewController()` and the
    /// window-level presenters all read it.
    public static var keyWindow: UIWindow? {
        if let window = activeWindowScene?.keyWindow { return window }
        let windows = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap(\.windows)
        return windows.first(where: \.isKeyWindow) ?? windows.first
    }

    /// The view controller to present from: the top-most controller on the key window (walks
    /// navigation and tab containers and presented controllers). `nil` without a key window.
    public static var presentingViewController: UIViewController? {
        guard let root = keyWindow?.rootViewController else { return nil }
        return UIViewController.lmk_topViewController(controller: root)
    }

    /// Display scale of the key window (e.g., 2.0 on iPad, 3.0 on iPhone).
    ///
    /// Read from the window's trait collection (`displayScale`), the value
    /// Apple recommends over `UIScreen.scale` now that a scene can sit on a
    /// display other than the main one (iPhone Mirroring, external displays).
    /// Falls back to `3.0` when no window is available or the trait is
    /// unspecified.
    public static var screenScale: CGFloat {
        displayScale(of: keyWindow) ?? fallbackDisplayScale
    }

    /// The scale assumed when no window can answer.
    public static let fallbackDisplayScale: CGFloat = 3

    /// Display scale from a view's trait collection, `nil` when the view is
    /// missing or the trait is unspecified (`0`).
    public static func displayScale(of view: UIView?) -> CGFloat? {
        guard let scale = view?.traitCollection.displayScale, scale > 0 else { return nil }
        return scale
    }

    /// Asks the system to close `scene` (the Close Window command on Mac and iPad).
    ///
    /// - Parameters:
    ///   - scene: The scene to close.
    ///   - onError: Called on the main actor when the system refuses; the scene stays open.
    public static func requestClose(_ scene: UIWindowScene, onError: (@MainActor (Error) -> Void)? = nil) {
        UIApplication.shared.requestSceneSessionDestruction(scene.session, options: nil, errorHandler: destructionErrorHandler(onError))
    }

    /// The block handed to UIKit for a refused destruction. Built outside the main actor so the
    /// block itself is nonisolated (UIKit does not promise a queue) and hops to the main actor.
    nonisolated static func destructionErrorHandler(_ onError: (@MainActor (Error) -> Void)?) -> ((Error) -> Void)? {
        guard let onError else { return nil }
        return { error in
            Task { @MainActor in onError(error) }
        }
    }

    /// Configures a Mac Catalyst window: size limits and an optional hidden title bar.
    /// No-op on iOS and iPadOS, so call it unconditionally from `scene(_:willConnectTo:options:)`.
    ///
    /// - Parameters:
    ///   - scene: The window scene being connected.
    ///   - minimumSize: Smallest window size; `nil` leaves the system default.
    ///   - maximumSize: Largest window size; `nil` leaves the window unbounded (full screen and wide tiling keep working).
    ///   - hidesTitleBar: Hides the title bar and removes the toolbar (apps that draw their own bars).
    public static func configureMacWindow(for scene: UIWindowScene, minimumSize: CGSize?, maximumSize: CGSize? = nil, hidesTitleBar: Bool = true) {
        #if targetEnvironment(macCatalyst)
            if hidesTitleBar, let titlebar = scene.titlebar {
                titlebar.titleVisibility = .hidden
                titlebar.toolbar = nil
            }
            if let minimumSize {
                scene.sizeRestrictions?.minimumSize = minimumSize
            }
            if let maximumSize {
                scene.sizeRestrictions?.maximumSize = maximumSize
            }
        #else
            _ = (scene, minimumSize, maximumSize, hidesTitleBar)
        #endif
    }
}
