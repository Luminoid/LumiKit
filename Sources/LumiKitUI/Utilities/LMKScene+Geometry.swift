//
//  LMKScene+Geometry.swift
//  LumiKit
//
//  Window geometry observation: size, safe area, orientation, and the iOS 26
//  interactive-resize flag (`LMKDevice.observeScreenSize` builds on it).
//

import UIKit

public extension LMKScene {
    /// A window's geometry at one layout pass.
    nonisolated struct Geometry: Equatable, Sendable {
        /// The window's bounds size in points.
        public var size: CGSize
        public var safeAreaInsets: UIEdgeInsets
        /// The scene's interface orientation (`.unknown` without a scene).
        public var interfaceOrientation: UIInterfaceOrientation
        /// Whether the user is dragging the window's edge (iOS 26 `UIWindowSceneGeometry.isInteractivelyResizing`;
        /// always `false` before 26). Defer heavy relayout until a pass with `false`.
        public var isInteractivelyResizing: Bool
        /// The layout tier of this size (`LMKDevice.screenSize(for:)`).
        public var screenSize: LMKDevice.ScreenSize

        public init(size: CGSize, safeAreaInsets: UIEdgeInsets, interfaceOrientation: UIInterfaceOrientation, isInteractivelyResizing: Bool, screenSize: LMKDevice.ScreenSize) {
            self.size = size
            self.safeAreaInsets = safeAreaInsets
            self.interfaceOrientation = interfaceOrientation
            self.isInteractivelyResizing = isInteractivelyResizing
            self.screenSize = screenSize
        }
    }

    /// The current geometry of `window`.
    static func geometry(of window: UIWindow) -> Geometry {
        let sceneGeometry = window.windowScene?.effectiveGeometry
        let resizing: Bool = if #available(iOS 26, *), let sceneGeometry {
            sceneGeometry.isInteractivelyResizing
        } else {
            false
        }
        return Geometry(
            size: window.bounds.size,
            safeAreaInsets: window.safeAreaInsets,
            interfaceOrientation: sceneGeometry?.interfaceOrientation ?? .unknown,
            isInteractivelyResizing: resizing,
            screenSize: LMKDevice.screenSize(for: window)
        )
    }

    /// Calls `onChange` whenever `window`'s geometry changes: a rotation, a resized iPad or Mac
    /// window, an iPhone Duo fold, a safe-area change (also once at install).
    ///
    /// Driven by the window's own layout pass plus the scene's `effectiveGeometry` (a 180°
    /// rotation and the end of an iOS 26 interactive resize change neither bounds nor safe
    /// area), so it needs no hook in the app's `UIWindowSceneDelegate`; on iOS 26 each callback
    /// carries the scene's `isInteractivelyResizing` so hosts can wait for the final pass. Keep
    /// the returned observation; `cancel()` (or letting it deinit) stops the callbacks.
    static func observeGeometry(of window: UIWindow, onChange: @escaping (Geometry) -> Void) -> LMKSceneGeometryObservation {
        LMKSceneGeometryObservation(window: window, onChange: onChange)
    }
}

/// A live geometry observation from `LMKScene.observeGeometry(of:onChange:)`.
public final class LMKSceneGeometryObservation {
    private var sentinel: LMKGeometrySentinelView?

    fileprivate init(window: UIWindow, onChange: @escaping (LMKScene.Geometry) -> Void) {
        let sentinel = LMKGeometrySentinelView(onChange: onChange)
        sentinel.frame = window.bounds
        window.insertSubview(sentinel, at: 0)
        self.sentinel = sentinel
        sentinel.report()
    }

    isolated deinit {
        cancel()
    }

    /// The window observed, `nil` once cancelled.
    public var window: UIWindow? { sentinel?.window }

    /// The last geometry reported.
    public var geometry: LMKScene.Geometry? { sentinel?.lastGeometry }

    /// Stops the callbacks and detaches from the window.
    public func cancel() {
        sentinel?.removeFromSuperview()
        sentinel = nil
    }
}

/// An invisible full-window view whose layout pass tracks the window's geometry, plus a KVO
/// observation of the scene's `effectiveGeometry` for the changes that trigger no layout.
private final class LMKGeometrySentinelView: UIView {
    private let onChange: (LMKScene.Geometry) -> Void
    private(set) var lastGeometry: LMKScene.Geometry?
    private var sceneObservation: NSKeyValueObservation?

    init(onChange: @escaping (LMKScene.Geometry) -> Void) {
        self.onChange = onChange
        super.init(frame: .zero)
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        isUserInteractionEnabled = false
        isAccessibilityElement = false
        accessibilityElementsHidden = true
        alpha = 0
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        sceneObservation = window?.windowScene?.observe(\.effectiveGeometry, options: [.new]) { [weak self] _, _ in
            MainActor.assumeIsolated { self?.report() }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        report()
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        report()
    }

    /// Reports the window's geometry when it differs from the last report.
    func report() {
        guard let window else { return }
        let geometry = LMKScene.geometry(of: window)
        guard geometry != lastGeometry else { return }
        lastGeometry = geometry
        onChange(geometry)
    }
}
