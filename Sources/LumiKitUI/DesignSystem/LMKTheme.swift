//
//  LMKTheme.swift
//  LumiKit
//
//  The theme value (every token category plus per-component defaults) and the
//  process-wide store behind `LMKTheme.current` / `LMKTheme.apply(_:)`.
//

import Synchronization
import UIKit

// MARK: - Theme value

/// A complete design-system configuration: colors, typography, spacing, corner
/// radii, shadows, opacity, layout, motion, plus an extension slot that holds
/// per-component defaults (`theme.chip`, `theme.button`, …) and app-defined
/// accents.
///
/// Register an app theme once at launch:
/// ```swift
/// extension LMKTheme {
///     static let petfolio = LMKTheme(colors: LMKColorTheme(primary: …, secondary: …))
/// }
/// LMKTheme.apply(.petfolio)
/// ```
///
/// Reads are nonisolated (`LMKTheme.current`, every `LMK*` token proxy), so
/// `static let` defaults and background code can use tokens. Applying a theme
/// re-renders every live view: colors flow through the `lmkTheme` trait, and
/// components conforming to `LMKThemeApplying` re-resolve their styles.
public nonisolated struct LMKTheme: Sendable {
    public var colors: LMKColorTheme
    public var typography: LMKTypographyTheme
    public var spacing: LMKSpacingTheme
    public var cornerRadius: LMKCornerRadiusTheme
    public var shadow: LMKShadowTheme
    public var alpha: LMKAlphaTheme
    public var layout: LMKLayoutTheme
    public var animation: LMKAnimationTheme
    /// Per-component defaults and app-defined values; read through the typed subscript.
    public var extensions: LMKThemeExtensions

    public init(
        colors: LMKColorTheme = .init(),
        typography: LMKTypographyTheme = .init(),
        spacing: LMKSpacingTheme = .init(),
        cornerRadius: LMKCornerRadiusTheme = .init(),
        shadow: LMKShadowTheme = .init(),
        alpha: LMKAlphaTheme = .init(),
        layout: LMKLayoutTheme = .init(),
        animation: LMKAnimationTheme = .init(),
        extensions: LMKThemeExtensions = .init()
    ) {
        self.colors = colors
        self.typography = typography
        self.spacing = spacing
        self.cornerRadius = cornerRadius
        self.shadow = shadow
        self.alpha = alpha
        self.layout = layout
        self.animation = animation
        self.extensions = extensions
    }

    /// The built-in neutral theme (system colors, green accent).
    public static let `default` = Self()

    /// A typed slot in `extensions`; returns `E.defaultValue` until something is stored.
    public subscript<E: LMKThemeExtension>(_ type: E.Type) -> E {
        get { extensions[type] }
        set { extensions[type] = newValue }
    }
}

// MARK: - Extension slot

/// A value that can live in `LMKTheme.extensions`: a component's default `Style`,
/// or an app's own accents.
///
/// ```swift
/// struct PetfolioAccents: LMKThemeExtension {
///     static let defaultValue = PetfolioAccents()
///     var gemini: UIColor = .systemPurple
/// }
/// var theme = LMKTheme.petfolio
/// theme[PetfolioAccents.self].gemini = .systemIndigo
/// ```
public nonisolated protocol LMKThemeExtension: Sendable {
    static var defaultValue: Self { get }
}

/// Type-keyed storage for `LMKThemeExtension` values.
public nonisolated struct LMKThemeExtensions: Sendable {
    private var storage: [ObjectIdentifier: any Sendable] = [:]

    public init() {}

    public subscript<E: LMKThemeExtension>(_ type: E.Type) -> E {
        get { storage[ObjectIdentifier(type)] as? E ?? E.defaultValue }
        set { storage[ObjectIdentifier(type)] = newValue }
    }

    /// Whether a value has been stored for `type` (as opposed to the default).
    public func contains(_ type: (some LMKThemeExtension).Type) -> Bool {
        storage[ObjectIdentifier(type)] != nil
    }
}

// MARK: - Store

/// Identity-compared handle carried by the `lmkTheme` trait. `.global` forwards
/// to the store live, so views that were never stamped read the current theme.
public final nonisolated class LMKThemeReference: NSObject, @unchecked Sendable {
    private let stored: LMKTheme?

    public var theme: LMKTheme { stored ?? LMKTheme.current }

    /// Reads the process-wide theme at access time.
    public static let global = LMKThemeReference(stored: nil)

    public init(_ theme: LMKTheme) {
        stored = theme
        super.init()
    }

    private init(stored: LMKTheme?) {
        self.stored = stored
        super.init()
    }
}

private final nonisolated class LMKThemeStore: Sendable {
    static let shared = LMKThemeStore()
    let reference = Mutex<LMKThemeReference>(LMKThemeReference(.default))
}

/// MainActor-only observer registry; theme *reads* never touch it.
@MainActor
private enum LMKThemeObservers {
    static var handlers: [UUID: @MainActor (LMKTheme) -> Void] = [:]
    static var continuations: [UUID: AsyncStream<LMKTheme>.Continuation] = [:]
}

/// Token returned by `LMKTheme.observe(_:)`; call `cancel()` (or let it deinit) to stop.
public final class LMKThemeObservation {
    private let id: UUID
    private var isCancelled = false

    fileprivate init(id: UUID) {
        self.id = id
    }

    public func cancel() {
        guard !isCancelled else { return }
        isCancelled = true
        LMKThemeObservers.handlers[id] = nil
    }

    deinit {
        let id = self.id
        Task { @MainActor in LMKThemeObservers.handlers[id] = nil }
    }
}

public nonisolated extension LMKTheme {
    /// The process-wide theme. Readable from any isolation.
    static var current: LMKTheme {
        LMKThemeStore.shared.reference.withLock { $0 }.theme
    }

    /// The handle for the current theme (what `apply` stamps onto windows); stamp it onto windows
    /// you create outside a scene (`window.traitOverrides.lmkTheme = LMKTheme.currentReference`).
    static var currentReference: LMKThemeReference {
        LMKThemeStore.shared.reference.withLock { $0 }
    }

    /// Makes `theme` the process-wide theme and re-renders every connected window.
    ///
    /// Colors held by views (`LMKColor.*`) re-resolve through the `lmkTheme` trait;
    /// components conforming to `LMKThemeApplying` re-apply their styles; observers
    /// registered with `observe(_:)` and `updates` receive the new value.
    @MainActor
    static func apply(_ theme: LMKTheme) {
        let reference = LMKThemeReference(theme)
        LMKThemeStore.shared.reference.withLock { $0 = reference }
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                window.traitOverrides.lmkTheme = reference
            }
        }
        for handler in LMKThemeObservers.handlers.values {
            handler(theme)
        }
        for continuation in LMKThemeObservers.continuations.values {
            continuation.yield(theme)
        }
    }

    /// Copies the current theme, lets `mutate` change it, and applies the result.
    @MainActor
    static func update(_ mutate: (inout LMKTheme) throws -> Void) rethrows {
        var theme = current
        try mutate(&theme)
        apply(theme)
    }

    /// Restores `LMKTheme.default`.
    @MainActor
    static func reset() {
        apply(.default)
    }

    /// Calls `handler` after every `apply` until the returned observation is cancelled or released.
    @MainActor
    @discardableResult
    static func observe(_ handler: @escaping @MainActor (LMKTheme) -> Void) -> LMKThemeObservation {
        let id = UUID()
        LMKThemeObservers.handlers[id] = handler
        return LMKThemeObservation(id: id)
    }

    /// A stream of themes, one element per `apply`, for structured-concurrency observers.
    @MainActor
    static var updates: AsyncStream<LMKTheme> {
        let id = UUID()
        return AsyncStream { continuation in
            LMKThemeObservers.continuations[id] = continuation
            continuation.onTermination = { _ in
                Task { @MainActor in LMKThemeObservers.continuations[id] = nil }
            }
        }
    }
}
