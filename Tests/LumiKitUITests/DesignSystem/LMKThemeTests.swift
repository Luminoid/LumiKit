//
//  LMKThemeTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - Store

/// Serialized: these tests mutate the process-wide theme.
@Suite(.serialized)
@MainActor
struct LMKThemeTests {
    private static let purple = UIColor.systemPurple
    private static let purpleTheme = LMKTheme(colors: LMKColorTheme(primary: purple))

    @Test
    func `Default theme uses the neutral color theme`() {
        LMKTheme.reset()
        let theme = LMKTheme.current
        #expect(theme.colors == LMKColorTheme())
        #expect(theme.colors.primary == UIColor.systemGreen)
        #expect(theme.colors.textPrimary == UIColor.label)
        #expect(theme.colors.backgroundPrimary == UIColor.systemBackground)
        #expect(theme.spacing.large == 16)
    }

    @Test
    func `apply replaces the current theme and reset restores the default`() {
        defer { LMKTheme.reset() }
        LMKTheme.apply(Self.purpleTheme)
        #expect(LMKTheme.current.colors.primary == Self.purple)
        LMKTheme.reset()
        #expect(LMKTheme.current.colors.primary == UIColor.systemGreen)
    }

    @Test
    func `update mutates a copy of the current theme and applies it`() {
        defer { LMKTheme.reset() }
        LMKTheme.update { theme in
            theme.spacing = .init(large: 20)
            theme.colors.primary = Self.purple
        }
        #expect(LMKTheme.current.spacing.large == 20)
        #expect(LMKTheme.current.colors.primary == Self.purple)
        #expect(LMKSpacing.large == 20)
    }

    @Test
    func `observe fires on every apply until cancelled`() {
        defer { LMKTheme.reset() }
        var received: [UIColor] = []
        let observation = LMKTheme.observe { received.append($0.colors.primary) }
        LMKTheme.apply(Self.purpleTheme)
        LMKTheme.apply(.default)
        #expect(received == [Self.purple, UIColor.systemGreen])
        observation.cancel()
        LMKTheme.apply(Self.purpleTheme)
        #expect(received.count == 2)
    }

    @Test
    func `updates stream yields one theme per apply`() async {
        defer { LMKTheme.reset() }
        let stream = LMKTheme.updates
        var iterator = stream.makeAsyncIterator()
        LMKTheme.apply(Self.purpleTheme)
        let first = await iterator.next()
        #expect(first?.colors.primary == Self.purple)
    }

    @Test
    func `current is readable off the main actor`() async {
        defer { LMKTheme.reset() }
        LMKTheme.update { $0.spacing = .init(large: 24) }
        let large = await Task.detached { LMKTheme.current.spacing.large }.value
        #expect(large == 24)
    }

    /// The xctest host's windows belong to no connected scene, so the window is stamped the way
    /// `apply` stamps scene windows (`LMKTheme.currentReference`); the assertion is that the stamp
    /// changes the trait and that `affectsColorAppearance` re-resolves a color the view already holds.
    @Test
    func `Stamping the theme trait re-resolves colors views already hold`() {
        defer { LMKTheme.reset() }
        let window = Self.makeWindow()
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        view.backgroundColor = LMKColor.primary
        window.addSubview(view)
        window.isHidden = false
        defer { window.isHidden = true }
        window.layoutIfNeeded()
        let green = UIColor.systemGreen.resolvedColor(with: view.traitCollection)
        #expect(Self.isSameColor(view.layer.backgroundColor, as: green))

        var traitChanges = 0
        let registration = view.registerForTraitChanges([LMKThemeTrait.self]) { (_: UIView, _) in traitChanges += 1 }
        defer { view.unregisterForTraitChanges(registration) }

        LMKTheme.apply(Self.purpleTheme)
        let connectedWindows = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap(\.windows)
        if !connectedWindows.contains(window) {
            window.traitOverrides.lmkTheme = LMKTheme.currentReference
        }
        view.updateTraitsIfNeeded()
        window.layoutIfNeeded()

        #expect(view.traitCollection[LMKThemeTrait.self] === LMKTheme.currentReference)
        #expect(traitChanges == 1)
        let purple = Self.purple.resolvedColor(with: view.traitCollection)
        #expect(LMKColor.primary.resolvedColor(with: view.traitCollection) == purple)
        #expect(Self.isSameColor(view.layer.backgroundColor, as: purple), "affectsColorAppearance re-resolves the layer color")
    }

    @Test
    func `traitOverrides scope a theme to a subtree without touching the store`() {
        LMKTheme.reset()
        let parent = UIView()
        let child = UILabel()
        parent.addSubview(child)
        let window = LMKThemeTesting.host(parent)
        defer { window.isHidden = true }
        parent.traitOverrides.lmkTheme = LMKThemeReference(Self.purpleTheme)
        parent.updateTraitsIfNeeded()
        child.updateTraitsIfNeeded()

        #expect(child.traitCollection.lmkTheme.colors.primary == Self.purple)
        #expect(LMKColor.primary.resolvedColor(with: child.traitCollection) == Self.purple.resolvedColor(with: child.traitCollection))
        #expect(LMKTheme.current.colors.primary == UIColor.systemGreen)
        #expect(UITraitCollection().lmkTheme.colors.primary == UIColor.systemGreen)
    }

    @Test
    func `Unstamped traits forward to the process-wide theme`() {
        defer { LMKTheme.reset() }
        LMKTheme.apply(Self.purpleTheme)
        #expect(UITraitCollection().lmkTheme.colors.primary == Self.purple)
        #expect(LMKThemeTrait.defaultValue === LMKThemeReference.global)
    }

    // MARK: Helpers

    private static func makeWindow() -> UIWindow {
        if let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
            return UIWindow(windowScene: scene)
        }
        return UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    }

    private static func isSameColor(_ cgColor: CGColor?, as color: UIColor) -> Bool {
        guard let cgColor else { return false }
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        UIColor(cgColor: cgColor).getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return abs(r1 - r2) < 0.01 && abs(g1 - g2) < 0.01 && abs(b1 - b2) < 0.01 && abs(a1 - a2) < 0.01
    }
}

// MARK: - Extensions slot

/// Not main-actor-isolated on purpose: the module's MainActor default must not reach members
/// that apps call from `static let` initializers and background queues (Swift 6.4 isolates the
/// members of an extension on a nonisolated type unless the extension says `nonisolated`).
struct LMKNonisolatedSurfaceTests {
    @Test
    func `Component style slots are readable and writable off the main actor`() async {
        let tint = await Task.detached { () -> UIColor? in
            var theme = LMKTheme.default
            theme.chip.tintColor = .systemPink
            theme.button.minimumHeight = 52
            return theme.button.minimumHeight == 52 ? theme.chip.tintColor : nil
        }.value
        #expect(tint == .systemPink)
    }

    @Test
    func `UIImage helpers run off the main actor`() async {
        let size = await Task.detached {
            UIImage.lmk_solidColor(.red, size: CGSize(width: 40, height: 20)).lmk_resized(maxDimension: 10).size
        }.value
        #expect(size.width == 10)
        #expect(size.height == 5)
    }

    @Test
    func `A nonisolated enum can conform to LMKEnumSelectable with the default icon`() {
        enum Option: String, LMKEnumSelectable {
            case only
            var displayName: String { rawValue }
        }
        #expect(Option.only.iconName == nil)
    }
}

struct LMKThemeExtensionSlotTests {
    private struct Accents: LMKThemeExtension, Equatable {
        static let defaultValue = Self()
        var gemini: UIColor = .systemPurple
    }

    @Test
    func `Extension slot returns the default until a value is stored`() {
        var theme = LMKTheme()
        #expect(theme[Accents.self] == Accents.defaultValue)
        #expect(!theme.extensions.contains(Accents.self))
        theme[Accents.self].gemini = .systemIndigo
        #expect(theme[Accents.self].gemini == UIColor.systemIndigo)
        #expect(theme.extensions.contains(Accents.self))
    }

    @Test
    func `Extension values are per theme value`() {
        var a = LMKTheme()
        a[Accents.self].gemini = .systemIndigo
        let b = a
        a[Accents.self].gemini = .systemTeal
        #expect(b[Accents.self].gemini == UIColor.systemIndigo)
        #expect(a[Accents.self].gemini == UIColor.systemTeal)
    }
}

// MARK: - LMKColorTheme

struct LMKColorThemeTests {
    @Test
    func `Partial init keeps every other role at its default`() {
        let theme = LMKColorTheme(primary: .systemPurple, secondary: .systemTeal)
        let defaults = LMKColorTheme()
        #expect(theme.primary == UIColor.systemPurple)
        #expect(theme.secondary == UIColor.systemTeal)
        #expect(theme.error == defaults.error)
        #expect(theme.textPrimary == defaults.textPrimary)
        #expect(theme.backgroundSecondary == defaults.backgroundSecondary)
        #expect(theme.divider == defaults.divider)
        #expect(theme.highContrastBoost == defaults.highContrastBoost)
    }

    @Test
    func `Derived roles follow primary and divider unless given`() {
        let light = UITraitCollection(userInterfaceStyle: .light)
        let theme = LMKColorTheme(primary: .systemPurple, divider: .systemGray)
        #expect(theme.link == UIColor.systemPurple)
        #expect(theme.selection == UIColor.systemPurple.withAlphaComponent(0.15))
        #expect(theme.outline == UIColor.systemGray.withAlphaComponent(0.5))
        let variant = theme.primaryVariant.resolvedColor(with: light)
        let base = UIColor.systemPurple.resolvedColor(with: light)
        #expect(variant.lmk_hexString != base.lmk_hexString)

        let explicit = LMKColorTheme(primary: .systemPurple, primaryVariant: .black, link: .systemBlue, outline: .red, selection: .yellow)
        #expect(explicit.primaryVariant == UIColor.black)
        #expect(explicit.link == UIColor.systemBlue)
        #expect(explicit.outline == UIColor.red)
        #expect(explicit.selection == UIColor.yellow)
    }

    @Test
    func `highContrastBoost is clamped at zero`() {
        #expect(LMKColorTheme(highContrastBoost: -1).highContrastBoost == 0)
        #expect(LMKColorTheme(highContrastBoost: 0.2).highContrastBoost == 0.2)
    }

    @Test
    func `Color themes compare by resolved appearance`() {
        #expect(LMKColorTheme() == LMKColorTheme())
        #expect(LMKColorTheme(primary: .systemPurple) != LMKColorTheme())
        #expect(LMKColorTheme(highContrastBoost: 0.2) != LMKColorTheme())
        let dynamic = LMKColorTheme(primary: .lmk_dynamic(light: .red, dark: .blue))
        #expect(dynamic == LMKColorTheme(primary: .lmk_dynamic(light: .red, dark: .blue)))
        #expect(dynamic != LMKColorTheme(primary: .lmk_dynamic(light: .red, dark: .green)))
        #expect(LMKColorTheme.roles.count == 23)
    }
}
