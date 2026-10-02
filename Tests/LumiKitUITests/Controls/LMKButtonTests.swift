//
//  LMKButtonTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - Helper

private final class DummyTarget: NSObject {
    var count = 0
    @objc func dummyAction() {
        count += 1
    }
}

// MARK: - LMKButton

@MainActor
struct LMKButtonTests {
    private static func hex(_ color: UIColor?, _ traits: UITraitCollection) -> String? {
        color?.resolvedColor(with: traits).lmk_hexString
    }

    @Test
    func `A button keeps its styled look under the Mac idiom`() {
        // `.mac` would draw a Mac push button and drop the configuration's background.
        #expect(LMKButton(title: "Save", style: .filled()).preferredBehavioralStyle == .pad)
        #expect(LMKButton(systemImage: "xmark").preferredBehavioralStyle == .pad)
    }

    @Test
    func `onTap is called on didTap and can capture the button`() {
        let button = LMKButton()
        var received: LMKButton?
        button.onTap = { [weak button] in received = button }
        button.didTap()
        #expect(received === button)
        button.onTap = nil
        button.didTap()
    }

    private static func brightness(_ color: UIColor?, _ traits: UITraitCollection) -> CGFloat {
        var value: CGFloat = 0
        color?.resolvedColor(with: traits).getHue(nil, saturation: nil, brightness: &value, alpha: nil)
        return value
    }

    @Test
    func `A pressed or selected neutral button shades its gray fill, never its label color`() {
        let light = UITraitCollection(userInterfaceStyle: .light)
        let dark = UITraitCollection(userInterfaceStyle: .dark)
        let button = LMKButton(title: "Neutral", style: .filled(.neutral))
        let resting = button.configuration?.background.backgroundColor
        #expect(Self.hex(resting, light) == Self.hex(LMKColor.fill, light))

        button.isHighlighted = true
        button.updateConfiguration()
        let pressed = button.configuration?.background.backgroundColor
        #expect(abs(Self.brightness(pressed, light) - Self.brightness(resting, light) * 0.9) < 0.01, "the label color shaded came out black")
        #expect(Self.brightness(pressed, light) > 0.7)
        #expect(Self.brightness(pressed, dark) > Self.brightness(resting, dark), "a dark fill lightens, where darkening would not show")

        button.isHighlighted = false
        button.isSelected = true
        button.updateConfiguration()
        let selected = button.configuration?.background.backgroundColor
        #expect(abs(Self.brightness(selected, light) - Self.brightness(resting, light) * 0.85) < 0.01)
    }

    @Test
    func `A neutral button with its own tint shades that tint and uses the on-fill foreground`() {
        let button = LMKButton(title: "Neutral", style: LMKButton.Style(role: .neutral, variant: .filled, tintColor: .red))
        let traits = button.traitCollection
        #expect(Self.hex(button.configuration?.baseForegroundColor, traits) == Self.hex(LMKColor.onAccent, traits), "a custom fill takes the on-fill text, not textPrimary")
        button.isHighlighted = true
        button.updateConfiguration()
        #expect(abs(Self.brightness(button.configuration?.background.backgroundColor, traits) - 0.9) < 0.01)
    }

    @Test
    func `Closure initializer and target action both fire`() {
        var taps = 0
        let button = LMKButton(title: "Go", style: .filled()) { taps += 1 }
        button.didTap()
        #expect(taps == 1)
        #expect(button.title == "Go")

        let target = DummyTarget()
        let wired = LMKButton(title: "Go", style: .outlined(), target: target, action: #selector(DummyTarget.dummyAction))
        #expect(wired.actions(forTarget: target, forControlEvent: .touchUpInside) == ["dummyAction"])
    }

    @Test
    func `Pointer interaction is enabled by default`() {
        #expect(LMKButton().isPointerInteractionEnabled)
    }

    @Test
    func `imageContentMode defaults to scaleAspectFit`() {
        #expect(LMKButton().imageContentMode == .scaleAspectFit)
    }

    // MARK: - Roles and variants

    @Test
    func `Filled buttons use the role tint with onAccent text and capsule corners`() {
        let button = LMKButton(title: "Save", style: .filled(.destructive))
        button.updateConfiguration()
        let traits = button.traitCollection
        #expect(Self.hex(button.configuration?.background.backgroundColor, traits) == Self.hex(LMKColor.error, traits))
        #expect(Self.hex(button.configuration?.baseForegroundColor, traits) == Self.hex(LMKColor.onAccent, traits))
        #expect(button.configuration?.cornerStyle == .capsule)
        #expect(button.configuration?.title == "Save")
    }

    @Test
    func `Outlined buttons stroke the tint on a clear background`() {
        let button = LMKButton(title: "Cancel", style: .outlined(.secondary))
        button.updateConfiguration()
        let traits = button.traitCollection
        #expect(button.configuration?.background.backgroundColor == UIColor.clear)
        #expect(Self.hex(button.configuration?.background.strokeColor, traits) == Self.hex(LMKColor.secondary, traits))
        #expect(button.configuration?.background.strokeWidth == 1)
        #expect(Self.hex(button.configuration?.baseForegroundColor, traits) == Self.hex(LMKColor.secondary, traits))
    }

    @Test
    func `Ghost and tinted buttons`() {
        let ghost = LMKButton(title: "Link", style: .ghost())
        ghost.updateConfiguration()
        #expect(ghost.configuration?.background.backgroundColor == UIColor.clear)
        #expect(ghost.configuration?.background.strokeWidth == 0)

        let tinted = LMKButton(title: "Soft", style: .tinted(.info))
        tinted.updateConfiguration()
        #expect(tinted.configuration?.background.backgroundColor?.cgColor.alpha == LMKTheme.current.alpha.xs)
    }

    @Test
    func `A custom tint overrides the role`() {
        let button = LMKButton(title: "Custom", style: .filled().tint(.red))
        button.updateConfiguration()
        #expect(button.configuration?.background.backgroundColor == UIColor.red)
    }

    @Test
    func `Icon-only buttons show a symbol with no title and circle corners`() {
        let button = LMKButton(systemImage: "chevron.left")
        button.updateConfiguration()
        #expect(button.configuration?.image != nil)
        #expect(button.configuration?.title == nil)
        #expect(button.configuration?.cornerStyle == .capsule)
        #expect(button.configuration?.contentInsets == .lmk_all(LMKTheme.current.spacing.small))
    }

    @Test
    func `setSymbol leaves size and weight to the style unless they are passed`() {
        let button = LMKButton(style: .iconOnly())
        button.setSymbol("heart")
        #expect(button.image == UIImage(systemName: "heart"), "nothing baked into the image")
        button.style.symbolPointSize = 28
        button.style.symbolWeight = .bold
        button.updateConfiguration()
        let preferred = button.configuration?.preferredSymbolConfigurationForImage
        #expect(preferred == UIImage.SymbolConfiguration(pointSize: 28, weight: .bold), "the style moves the glyph after the fact")

        button.setSymbol("heart", pointSize: 12)
        #expect(button.image == UIImage(systemName: "heart", withConfiguration: UIImage.SymbolConfiguration(pointSize: 12)))
        button.setSymbol("heart", weight: .thin)
        #expect(button.image == UIImage(systemName: "heart", withConfiguration: UIImage.SymbolConfiguration(weight: .thin)))
    }

    @Test
    func `Image placement, image padding, and the loading indicator color reach the configuration`() {
        let button = LMKButton(title: "Next", image: UIImage(systemName: "arrow.right"), style: LMKButton.Style(imagePlacement: .trailing, imagePadding: 11, loadingIndicatorColor: .magenta))
        #expect(button.configuration?.imagePlacement == .trailing)
        #expect(button.configuration?.imagePadding == 11)
        #expect(button.configuration?.activityIndicatorColorTransformer?(.black) == UIColor.magenta)
        let merged = LMKButton.Style(imagePlacement: .top).merging(LMKButton.Style(imagePadding: 3))
        #expect(merged.imagePlacement == .top)
        #expect(merged.imagePadding == 3)
    }

    @Test
    func `Glass renders as tinted where Liquid Glass does not exist`() {
        #expect(LMKButton.renderedVariant(.glass, supportsGlass: false) == .tinted)
        #expect(LMKButton.renderedVariant(.glass, supportsGlass: true) == .glass)
        #expect(LMKButton.renderedVariant(.outlined, supportsGlass: false) == .outlined)
    }

    @Test
    func `Sizes change insets and text style`() {
        let small = LMKButton(title: "S", style: .filled().size(.small))
        small.updateConfiguration()
        #expect(small.configuration?.contentInsets.top == LMKTheme.current.spacing.xs)
        let large = LMKButton(title: "L", style: .filled().size(.large))
        large.updateConfiguration()
        #expect(large.configuration?.contentInsets.top == LMKTheme.current.spacing.large)
        let medium = LMKButton(title: "M", style: .filled())
        medium.updateConfiguration()
        #expect(medium.configuration?.contentInsets.top == LMKTheme.current.spacing.buttonPaddingVertical)
    }

    @Test
    func `Surface overrides reach the configuration`() {
        var style = LMKButton.Style.filled()
        style.surface.corners = .fixed(6)
        style.surface.contentInsets = .lmk_all(2)
        style.surface.border = .solid(.blue, width: 3)
        style.surface.shadow = .level(.level2)
        let button = LMKButton(title: "Box", style: style)
        button.updateConfiguration()
        #expect(button.configuration?.cornerStyle == .fixed)
        #expect(button.configuration?.background.cornerRadius == 6)
        #expect(button.configuration?.contentInsets == .lmk_all(2))
        #expect(button.configuration?.background.strokeColor == UIColor.blue)
        #expect(button.configuration?.background.strokeWidth == 3)
        #expect(button.configuration?.background.shadowProperties.opacity ?? 0 > 0)
    }

    @Test
    func `A surface background is the resting fill; the states still shade or replace it`() {
        let style = LMKButton.Style(
            variant: .outlined,
            surface: LMKSurfaceStyle(background: .solid(.red), border: .solid(.green, width: 2)),
            highlighted: LMKControlStateStyle(background: .solid(.blue)),
            selected: LMKControlStateStyle(border: .solid(.yellow, width: 2))
        )
        let button = LMKButton(title: "Surface", style: style)
        #expect(button.configuration?.background.backgroundColor == UIColor.red)
        #expect(button.configuration?.background.strokeColor == UIColor.green)

        button.isHighlighted = true
        button.updateConfiguration()
        #expect(button.configuration?.background.backgroundColor == UIColor.blue, "the pressed override wins over the surface")

        button.isHighlighted = false
        button.isSelected = true
        button.updateConfiguration()
        #expect(button.configuration?.background.strokeColor == UIColor.yellow, "the selected border wins over the surface border")
        let selected = button.configuration?.background.backgroundColor
        #expect(selected != UIColor.red, "a selected solid surface is shaded like a filled button")
        #expect(abs(Self.brightness(selected, button.traitCollection) - 0.85) < 0.01)
    }

    @Test
    func `A translucent border keeps its own alpha and fades with the disabled state`() {
        var style = LMKButton.Style.ghost()
        style.surface.border = .solid(UIColor.blue.withAlphaComponent(0.5), width: 1)
        let button = LMKButton(title: "Faint", style: style)
        #expect(button.configuration?.background.strokeColor?.cgColor.alpha == 0.5)
        button.isEnabled = false
        button.updateConfiguration()
        let expected = 0.5 * LMKTheme.current.alpha.disabled
        #expect(abs((button.configuration?.background.strokeColor?.cgColor.alpha ?? 0) - expected) < 0.001)
    }

    // MARK: - States

    @Test
    func `Disabled buttons fade the background and foreground`() {
        let button = LMKButton(title: "Off", style: .filled().tint(.red))
        button.isEnabled = false
        button.updateConfiguration()
        let transformer = button.configuration?.background.backgroundColorTransformer
        #expect(transformer?(.red).cgColor.alpha == LMKTheme.current.alpha.disabled)
        #expect(button.configuration?.baseForegroundColor?.cgColor.alpha == LMKTheme.current.alpha.disabled)

        let glass = LMKButton(title: "Off", style: .glass())
        glass.isEnabled = false
        glass.updateConfiguration()
        #expect(glass.configuration?.baseForegroundColor?.cgColor.alpha == LMKTheme.current.alpha.disabled, "a disabled glass button fades its label too")
    }

    @Test
    func `The press scale comes from the highlighted style, else the theme`() {
        let button = LMKButton(title: "Press", style: .filled())
        button.perform(NSSelectorFromString("handleTouchDown"))
        guard LMKAnimation.shouldAnimate else {
            #expect(button.transform == .identity, "Reduce Motion: no press scale")
            return
        }
        #expect(abs(button.transform.a - LMKTheme.current.animation.pressScale) < 0.001)
        button.perform(NSSelectorFromString("handleTouchUp"))
        #expect(button.transform == .identity)

        button.style.highlighted = LMKControlStateStyle(scale: 0.5)
        button.perform(NSSelectorFromString("handleTouchDown"))
        #expect(abs(button.transform.a - 0.5) < 0.001, "Style.highlighted.scale is honored")
        button.perform(NSSelectorFromString("handleTouchUp"))

        button.style.highlighted = nil
        button.style.pressAnimation = false
        button.perform(NSSelectorFromString("handleTouchDown"))
        #expect(button.transform == .identity)
    }

    @Test
    func `A button whose menu opens on touch does not shrink unless its style asks`() {
        let button = LMKMenu.makeButton(menu: UIMenu(children: [UIAction(title: "One") { _ in }]), systemImageName: "ellipsis", accessibilityLabel: "More")
        #expect(button.pressScale == 1, "the menu's presentation animates the button")
        button.showsMenuAsPrimaryAction = false
        #expect(button.pressScale == LMKTheme.current.animation.pressScale, "a menu behind a long press keeps the press")
        button.showsMenuAsPrimaryAction = true
        button.style.pressAnimation = true
        #expect(button.pressScale == LMKTheme.current.animation.pressScale, "an explicit pressAnimation wins")
        button.style.pressAnimation = nil
        button.style.highlighted = LMKControlStateStyle(scale: 0.5)
        #expect(button.pressScale == 0.5)
    }

    @Test
    func `Selected filled buttons darken the tint and per-state overrides win`() {
        let gray = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        let button = LMKButton(title: "On", style: .filled().tint(gray))
        button.updateConfiguration()
        let normal = Self.hex(button.configuration?.background.backgroundColor, button.traitCollection)
        button.isSelected = true
        button.updateConfiguration()
        let selected = Self.hex(button.configuration?.background.backgroundColor, button.traitCollection)
        #expect(selected != normal)

        button.style.selected = LMKControlStateStyle(background: .solid(.yellow), foregroundColor: .black)
        button.updateConfiguration()
        #expect(button.configuration?.background.backgroundColor == UIColor.yellow)
        #expect(button.configuration?.baseForegroundColor == UIColor.black)
    }

    // MARK: - Toggle

    @Test
    func `Toggle buttons flip on tap, swap content, and expose on/off`() {
        let button = LMKButton(title: "Like", image: UIImage(systemName: "heart"), style: .ghost())
        button.isToggle = true
        button.selectedTitle = "Liked"
        button.selectedImage = UIImage(systemName: "heart.fill")
        var values: [Bool] = []
        button.onValueChange = { values.append($0) }
        #expect(button.accessibilityValue == "Off")
        #expect(button.accessibilityTraits.contains(.toggleButton))
        button.didTap()
        #expect(button.isSelected)
        #expect(button.configuration?.title == "Liked")
        #expect(button.configuration?.image == UIImage(systemName: "heart.fill"))
        #expect(button.accessibilityValue == "On")
        button.didTap()
        #expect(!button.isSelected)
        #expect(button.configuration?.title == "Like")
        #expect(values == [true, false])
    }

    @Test
    func `A plain button keeps a host-set accessibility value across content updates`() {
        let button = LMKButton(title: "Volume")
        button.accessibilityValue = "50%"
        button.title = "Loudness"
        button.style = .ghost()
        #expect(button.accessibilityValue == "50%")
        #expect(!button.accessibilityTraits.contains(.toggleButton))
    }

    @Test
    func `Per-instance strings localize the toggle value`() {
        let button = LMKButton(title: "T")
        button.isToggle = true
        button.strings = LMKButton.Strings(onAccessibilityValue: "Activado", offAccessibilityValue: "Desactivado")
        #expect(button.accessibilityValue == "Desactivado")
        button.isSelected = true
        #expect(button.accessibilityValue == "Activado")
    }

    // MARK: - Loading

    @Test
    func `Loading state shows an activity indicator and restores the current title`() {
        let button = LMKButton(title: "Save", style: .filled())
        button.isLoading = true
        #expect(button.configuration?.showsActivityIndicator == true)
        #expect(button.configuration?.title == " ")
        #expect(button.accessibilityLabel == "Save", "VoiceOver keeps the title while the placeholder shows")
        #expect(button.accessibilityTraits.contains(.notEnabled))
        var taps = 0
        button.onTap = { taps += 1 }
        button.didTap()
        #expect(taps == 0, "a tap while loading is absorbed")
        LMKThemeTesting.fit(button, width: 120)
        #expect(button.point(inside: CGPoint(x: 10, y: 10), with: nil), "a loading button absorbs the touch like a disabled one")
        #expect(!button.point(inside: CGPoint(x: -10, y: 10), with: nil), "without the expanded hit area")
        button.title = "Saved"
        button.isLoading = false
        #expect(button.configuration?.title == "Saved", "a title set while loading is not overwritten by the old one")
        #expect(button.configuration?.showsActivityIndicator == false)
        #expect(!button.accessibilityTraits.contains(.notEnabled))
        button.didTap()
        #expect(taps == 1)

        let toggle = LMKButton(title: "Follow", style: .tinted())
        toggle.isToggle = true
        toggle.selectedTitle = "Following"
        toggle.isLoading = true
        toggle.isSelected = true
        toggle.isLoading = false
        #expect(toggle.configuration?.title == "Following")
    }

    @Test
    func `A loading icon-only button keeps no title, so it does not widen`() {
        let button = LMKButton(systemImage: "plus")
        LMKThemeTesting.fit(button, width: 100)
        let resting = button.intrinsicContentSize
        button.isLoading = true
        #expect(button.configuration?.title == nil)
        #expect(button.configuration?.showsActivityIndicator == true)
        #expect(button.intrinsicContentSize.width < resting.width + LMKTheme.current.spacing.iconToText, "no image padding plus a space is added")
    }

    @Test
    func `shrinkingTitleToFit survives configuration rebuilds`() {
        let button = LMKButton(title: "A rather long title for a narrow button", style: .filled())
        button.shrinkingTitleToFit(minimumScaleFactor: 0.6)
        button.isHighlighted = true
        button.updateConfiguration()
        button.style = .outlined()
        #expect(button.configuration?.titleLineBreakMode == .byTruncatingTail)
        #expect(button.titleLabel?.adjustsFontSizeToFitWidth == true)
        #expect(abs((button.titleLabel?.minimumScaleFactor ?? 0) - 0.6) < 0.001)
        #expect(button.titleLabel?.numberOfLines == 1)
        let window = LMKThemeTesting.host(button)
        defer { window.isHidden = true }
        button.frame = CGRect(x: 0, y: 0, width: 80, height: 44)
        button.layoutIfNeeded()
        #expect(button.titleLabel?.adjustsFontSizeToFitWidth == true, "layout does not reset the label")
        #expect(button.titleLabel?.numberOfLines == 1)
    }

    // MARK: - Hit target

    @Test
    func `Buttons keep a 44pt hit target`() {
        let button = LMKButton(title: "Tiny", style: .ghost().size(.small))
        button.frame = CGRect(x: 0, y: 0, width: 30, height: 20)
        #expect(button.point(inside: CGPoint(x: 15, y: -10), with: nil))
        #expect(button.point(inside: CGPoint(x: -6, y: 10), with: nil))
        #expect(!button.point(inside: CGPoint(x: 15, y: -14), with: nil))
        button.minimumHitTarget = 20
        #expect(!button.point(inside: CGPoint(x: 15, y: -10), with: nil))
        button.minimumHitTarget = nil
        button.isEnabled = false
        #expect(button.point(inside: CGPoint(x: 15, y: 10), with: nil), "a disabled button absorbs a touch inside its bounds")
        #expect(!button.point(inside: CGPoint(x: 15, y: -10), with: nil), "without the expanded area")
        button.isHidden = true
        #expect(!button.point(inside: CGPoint(x: 15, y: 10), with: nil))
    }

    // MARK: - Theme

    @Test
    func `theme.button supplies app-wide defaults and buttons follow the traits' theme`() {
        var theme = LMKThemeTesting.distinct
        theme.button = LMKButton.Style(variant: .outlined, size: .small)
        let button = LMKButton(title: "Themed")
        let window = LMKThemeTesting.host(button, theme: theme)
        defer { window.isHidden = true }
        button.updateConfiguration()
        let traits = button.traitCollection
        #expect(button.configuration?.background.backgroundColor == UIColor.clear)
        #expect(Self.hex(button.configuration?.background.strokeColor, traits) == UIColor.systemPurple.resolvedColor(with: traits).lmk_hexString)
        #expect(button.configuration?.contentInsets.top == theme.spacing.xs)

        button.style = .filled(.info)
        button.updateConfiguration()
        #expect(Self.hex(button.configuration?.background.backgroundColor, traits) == UIColor.systemCyan.resolvedColor(with: traits).lmk_hexString)
        #expect(button.configuration?.contentInsets.top == theme.spacing.xs, "the theme's size still applies")
    }

    @Test
    func `Menu indicator follows the style and the menu`() {
        let button = LMKButton(title: "Sort", style: .outlined())
        button.style.showsMenuIndicator = true
        button.updateConfiguration()
        #expect(button.configuration?.indicator == UIButton.Configuration.Indicator.none)
        button.menu = UIMenu(children: [UIAction(title: "A") { _ in }])
        button.updateConfiguration()
        #expect(button.configuration?.indicator == .popup)
    }

    @Test
    func `didApplyStyle runs after style changes`() {
        let button = LMKButton(title: "Hook")
        var count = 0
        button.didApplyStyle = { _ in count += 1 }
        button.style = .ghost()
        #expect(count == 1)
    }

    @Test
    func `applyContentTheme runs before didApplyStyle so a subclass never has to follow super`() {
        final class ThemedButton: LMKButton {
            var order: [String] = []
            override func applyContentTheme(_ theme: LMKTheme) {
                order.append("content")
            }
        }
        let button = ThemedButton(title: "Sub")
        button.didApplyStyle = { ($0 as? ThemedButton)?.order.append("hook") }
        button.order = []
        button.style = .tinted()
        #expect(button.order == ["content", "hook"])
    }

    @Test
    func `Style merging and presets`() {
        let merged = LMKButton.Style.filled(.destructive).merging(LMKButton.Style(size: .large, tintColor: .red))
        #expect(merged.role == .destructive)
        #expect(merged.variant == .filled)
        #expect(merged.size == .large)
        #expect(merged.tintColor == UIColor.red)
        #expect(LMKButton.Style.iconOnly().surface.corners == .circle)
        #expect(LMKButton.Style.glass(.info).variant == .glass)
    }
}
