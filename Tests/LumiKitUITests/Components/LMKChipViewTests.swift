//
//  LMKChipViewTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKChipView

@MainActor
struct LMKChipViewTests {
    private static func hex(_ color: UIColor?, _ traits: UITraitCollection) -> String? {
        color?.resolvedColor(with: traits).lmk_hexString
    }

    @Test
    func `The dismiss glyph stays a bare glyph under the Mac idiom`() {
        #expect(LMKChipView(text: "Test", style: .filled).dismissButton.preferredBehavioralStyle == .pad)
    }

    @Test
    func `Filled chip has a tinted background and onAccent text`() {
        let chip = LMKChipView(text: "Test", style: .filled)
        let traits = chip.traitCollection
        #expect(Self.hex(chip.backgroundColor, traits) == Self.hex(LMKColor.primary, traits))
        #expect(Self.hex(chip.titleLabel.textColor, traits) == Self.hex(LMKColor.onAccent, traits))
        #expect(chip.layer.borderWidth == 0)
        #expect(chip.lmk_cornerStyle == .capsule)
    }

    @Test
    func `Outlined chip has a clear background and a tinted border`() {
        let chip = LMKChipView(text: "Test", style: .outlined)
        let traits = chip.traitCollection
        #expect(chip.backgroundColor == UIColor.clear)
        #expect(chip.layer.borderWidth > 0)
        #expect(Self.hex(chip.titleLabel.textColor, traits) == Self.hex(LMKColor.primary, traits))
    }

    @Test
    func `A custom tint colors the chip`() {
        let chip = LMKChipView(text: "Test", style: .filled.tint(.red))
        #expect(chip.backgroundColor == UIColor.red)
        chip.style.tintColor = .blue
        #expect(chip.backgroundColor == UIColor.blue)
    }

    @Test
    func `Text and icon update through properties and configure`() {
        let chip = LMKChipView(text: "Indoor")
        #expect(chip.titleLabel.text == "Indoor")
        #expect(chip.iconView.isHidden)
        chip.configure(text: "Outdoor", icon: UIImage(systemName: "leaf"))
        #expect(chip.text == "Outdoor")
        #expect(chip.accessibilityLabel == "Outdoor")
        #expect(!chip.iconView.isHidden)
        chip.icon = nil
        #expect(chip.iconView.isHidden)
    }

    @Test
    func `Accessibility traits follow the handlers and states`() {
        let chip = LMKChipView(text: "Indoor")
        #expect(chip.accessibilityTraits == .staticText)
        chip.onTap = {}
        #expect(chip.accessibilityTraits == .button)
        chip.isSelected = true
        #expect(chip.accessibilityTraits.contains(.selected))
        chip.isEnabled = false
        #expect(chip.accessibilityTraits.contains(.notEnabled))
        chip.onTap = nil
        chip.isSelected = false
        chip.isEnabled = true
        #expect(chip.accessibilityTraits == .staticText)
    }

    // MARK: - Dismiss

    @Test
    func `Dismiss handler shows the xmark, sets the button trait, and exposes a custom action`() {
        let chip = LMKChipView(text: "Filter", style: .outlined)
        #expect(chip.dismissButton.isHidden)
        chip.onDismiss = {}
        #expect(!chip.dismissButton.isHidden)
        #expect(chip.accessibilityTraits == .button)
        #expect(chip.accessibilityCustomActions?.first?.name == LMKChipView.Strings().dismissAccessibilityLabel)

        chip.onDismiss = nil
        #expect(chip.dismissButton.isHidden)
        #expect(chip.accessibilityTraits == .staticText)
        #expect(chip.accessibilityCustomActions == nil)
    }

    @Test
    func `Per-instance strings name the dismiss action`() {
        let chip = LMKChipView(text: "Filter")
        chip.strings = LMKChipView.Strings(dismissAccessibilityLabel: "Quitar")
        chip.onDismiss = {}
        #expect(chip.accessibilityCustomActions?.first?.name == "Quitar")
    }

    // MARK: - Selection

    @Test
    func `Selecting an outlined chip fills it`() {
        let chip = LMKChipView(text: "Active", style: .outlined)
        #expect(chip.backgroundColor == UIColor.clear)
        chip.isSelected = true
        let traits = chip.traitCollection
        #expect(Self.hex(chip.backgroundColor, traits) == Self.hex(LMKColor.primary, traits))
        #expect(chip.layer.borderWidth == 0)
        chip.isSelected = false
        #expect(chip.backgroundColor == UIColor.clear)
        #expect(chip.layer.borderWidth > 0)
    }

    private static func brightness(_ color: UIColor?, _ traits: UITraitCollection) -> CGFloat {
        var value: CGFloat = 0
        color?.resolvedColor(with: traits).getHue(nil, saturation: nil, brightness: &value, alpha: nil)
        return value
    }

    @Test
    func `Selecting a filled chip shades its tint by a quarter`() {
        let chip = LMKChipView(text: "Active", style: .filled.tint(UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)))
        let normal = Self.brightness(chip.backgroundColor, chip.traitCollection)
        chip.isSelected = true
        let selected = Self.brightness(chip.backgroundColor, chip.traitCollection)
        #expect(abs(selected - normal * 0.75) < 0.01, "a shade the eye picks out, and never black")
        #expect(chip.backgroundColor?.cgColor.alpha == 1)
    }

    @Test
    func `A dark filled chip lightens when selected or pressed`() {
        let dark = UIColor(white: 0.2, alpha: 1)
        let chip = LMKChipView(text: "Active", style: .filled.tint(dark))
        chip.isSelected = true
        #expect(Self.brightness(chip.backgroundColor, chip.traitCollection) > 0.2, "darkening a dark fill would not show")
        chip.isSelected = false
        chip.isHighlighted = true
        #expect(Self.brightness(chip.backgroundColor, chip.traitCollection) > 0.2)
    }

    @Test
    func `Tinted chip has a wash of the tint and text in the tint`() {
        let chip = LMKChipView(text: "Draft", style: .tinted.tint(.red))
        #expect(chip.backgroundColor == UIColor.red.withAlphaComponent(LMKTheme.current.alpha.xs))
        #expect(chip.titleLabel.textColor == UIColor.red)
        #expect(chip.layer.borderWidth == 0)
        chip.isSelected = true
        #expect(chip.backgroundColor == UIColor.red, "selected, a tinted chip takes the full tint")
        #expect(chip.titleLabel.textColor != UIColor.red)
    }

    @Test
    func `A press changes the fill of every variant and keeps the chip opaque`() {
        let theme = LMKTheme.current
        let filled = LMKChipView(text: "A", style: .filled.tint(.red))
        filled.isHighlighted = true
        #expect(filled.backgroundColor != UIColor.red)
        #expect(abs(Self.brightness(filled.backgroundColor, filled.traitCollection) - 0.85) < 0.01)
        #expect(filled.alpha == 1, "dimming the whole chip was hard to tell from the resting look")
        filled.isHighlighted = false
        #expect(filled.backgroundColor == UIColor.red)

        let tinted = LMKChipView(text: "A", style: .tinted.tint(.red))
        tinted.isHighlighted = true
        #expect(tinted.backgroundColor == UIColor.red.withAlphaComponent(theme.alpha.medium))

        let outlined = LMKChipView(text: "A", style: .outlined.tint(.red))
        outlined.isHighlighted = true
        #expect(outlined.backgroundColor == UIColor.red.withAlphaComponent(theme.alpha.xs))
        #expect(outlined.layer.borderWidth > 0)
        outlined.isHighlighted = false
        #expect(outlined.backgroundColor == UIColor.clear)

        // A selected chip pressed again shades the fill it shows.
        let selected = LMKChipView(text: "A", style: .outlined.tint(.red))
        selected.isSelected = true
        selected.isHighlighted = true
        #expect(abs(Self.brightness(selected.backgroundColor, selected.traitCollection) - 0.85) < 0.01)
    }

    @Test
    func `A highlighted override replaces the derived press`() {
        var style = LMKChipView.Style.filled.tint(.red)
        style.highlighted = LMKControlStateStyle(alpha: 0.5)
        let chip = LMKChipView(text: "A", style: style)
        chip.isHighlighted = true
        #expect(chip.backgroundColor == UIColor.red)
        #expect(abs(chip.alpha - 0.5) < 0.001)

        style.highlighted = LMKControlStateStyle(background: .solid(.yellow))
        chip.style = style
        #expect(chip.backgroundColor == UIColor.yellow)
        #expect(chip.alpha == 1)
    }

    @Test
    func `Variants list all three fills`() {
        #expect(LMKChipView.Variant.allCases == [.filled, .tinted, .outlined])
    }

    @Test
    func `selectedVariant outlined inverts a filled chip`() {
        var style = LMKChipView.Style.filled
        style.selectedVariant = .outlined
        let chip = LMKChipView(text: "Active", style: style)
        chip.isSelected = true
        #expect(chip.backgroundColor == UIColor.clear)
        #expect(chip.layer.borderWidth > 0)
    }

    @Test
    func `State overrides win over the derived appearance`() {
        var style = LMKChipView.Style.filled
        style.selected = LMKControlStateStyle(background: .solid(.yellow), foregroundColor: .black)
        style.disabled = LMKControlStateStyle(alpha: 0.2)
        let chip = LMKChipView(text: "Active", style: style)
        chip.isSelected = true
        #expect(chip.backgroundColor == UIColor.yellow)
        #expect(chip.titleLabel.textColor == UIColor.black)
        chip.isEnabled = false
        #expect(abs(chip.alpha - 0.2) < 0.001)
        chip.isEnabled = true
        #expect(chip.alpha == 1)
    }

    // MARK: - Interaction

    @Test
    func `Taps fire onTap only while enabled`() {
        let chip = LMKChipView(text: "Tap")
        var taps = 0
        chip.onTap = { taps += 1 }
        chip.didTap()
        #expect(taps == 1)
        chip.isEnabled = false
        chip.didTap()
        #expect(taps == 1)
        var dismissed = 0
        chip.onDismiss = { dismissed += 1 }
        chip.didDismiss()
        #expect(dismissed == 0, "disabled chips ignore dismiss too")
        chip.isEnabled = true
        chip.didDismiss()
        #expect(dismissed == 1)
    }

    @Test
    func `Disabled chips dim to the theme's disabled alpha`() {
        let chip = LMKChipView(text: "Off")
        chip.isEnabled = false
        #expect(abs(chip.alpha - LMKTheme.current.alpha.disabled) < 0.001)
    }

    @Test
    func `Interactive chips keep a 44pt hit target; disabled ones absorb their bounds`() {
        let chip = LMKChipView(text: "Small")
        chip.frame = CGRect(x: 0, y: 0, width: 60, height: 24)
        #expect(!chip.point(inside: CGPoint(x: 30, y: -8), with: nil), "display-only chips use their bounds")
        chip.onTap = {}
        #expect(chip.point(inside: CGPoint(x: 30, y: -8), with: nil))
        #expect(!chip.point(inside: CGPoint(x: 30, y: -12), with: nil))
        chip.isEnabled = false
        #expect(chip.point(inside: CGPoint(x: 30, y: 12), with: nil), "a disabled chip swallows the touch like a disabled UIControl")
        #expect(!chip.point(inside: CGPoint(x: 30, y: -8), with: nil), "without the expanded area")
        chip.isEnabled = true
        chip.isHidden = true
        #expect(!chip.point(inside: CGPoint(x: 30, y: 12), with: nil))
    }

    @Test
    func `A display-only chip is not the hit view; a handler, host target, or recognizer makes it one`() {
        let chip = LMKChipView(text: "Tag")
        chip.frame = CGRect(x: 0, y: 0, width: 60, height: 24)
        chip.layoutIfNeeded()
        let center = CGPoint(x: 30, y: 12)
        #expect(chip.hitTest(center, with: nil) == nil, "the row or card under a tag chip gets the tap")

        chip.onTap = {}
        #expect(chip.hitTest(center, with: nil) === chip)
        chip.onTap = nil
        chip.onDismiss = {}
        #expect(chip.hitTest(center, with: nil) === chip)
        chip.onDismiss = nil
        #expect(chip.hitTest(center, with: nil) == nil)

        final class Target: NSObject {
            @objc func fire() {}
        }
        let target = Target()
        chip.addTarget(target, action: #selector(Target.fire), for: .touchUpInside)
        #expect(chip.hitTest(center, with: nil) === chip, "a host target-action makes the chip interactive")
        chip.removeTarget(target, action: nil, for: .allEvents)
        #expect(chip.hitTest(center, with: nil) == nil)

        let action = UIAction { _ in }
        chip.addAction(action, for: .touchUpInside)
        #expect(chip.hitTest(center, with: nil) === chip, "a host UIAction makes the chip interactive")
        chip.removeAction(action, for: .touchUpInside)
        #expect(chip.hitTest(center, with: nil) == nil)

        chip.addGestureRecognizer(UITapGestureRecognizer())
        #expect(chip.hitTest(center, with: nil) === chip, "a host recognizer makes the chip interactive")
    }

    @Test
    func `State overrides apply for their own state only, and a state fill is pressed once`() {
        var style = LMKChipView.Style.filled.tint(.red)
        style.surface.background = .solid(.gray)
        style.highlighted = LMKControlStateStyle(background: .solid(.yellow))
        let chip = LMKChipView(text: "A", style: style)
        #expect(chip.backgroundColor == UIColor.gray)
        chip.isEnabled = false
        #expect(chip.backgroundColor == UIColor.gray, "a highlighted fill does not leak into the disabled look")
        chip.isEnabled = true
        chip.isSelected = true
        #expect(chip.backgroundColor == UIColor.gray, "nor into the selected look")
        chip.isHighlighted = true
        #expect(chip.backgroundColor == UIColor.yellow)
        chip.isHighlighted = false
        chip.isSelected = false

        var selectedFill = LMKChipView.Style.filled.tint(.red)
        selectedFill.selected = LMKControlStateStyle(background: .solid(UIColor(white: 0.6, alpha: 1)))
        let pressedSelected = LMKChipView(text: "B", style: selectedFill)
        pressedSelected.isSelected = true
        pressedSelected.isHighlighted = true
        #expect(abs(Self.brightness(pressedSelected.backgroundColor, pressedSelected.traitCollection) - 0.6 * 0.85) < 0.01, "one shade, not two")
    }

    // MARK: - Theme

    @Test
    func `Chips follow the theme carried by the traits`() {
        let chip = LMKChipView(text: "Themed", style: .outlined)
        let window = LMKThemeTesting.host(chip, theme: LMKThemeTesting.distinct)
        defer { window.isHidden = true }
        let traits = chip.traitCollection
        #expect(Self.hex(chip.titleLabel.textColor, traits) == UIColor.systemPurple.resolvedColor(with: traits).lmk_hexString)
        #expect(chip.contentStack.spacing == LMKThemeTesting.distinct.spacing.xs)
        #expect(chip.titleLabel.font.familyName == "Georgia")
    }

    @Test
    func `theme.chip supplies app-wide defaults and the instance wins`() {
        var theme = LMKTheme()
        theme.chip = LMKChipView.Style(variant: .outlined, tintColor: .red, iconSpacing: 9)
        let chip = LMKChipView(text: "Themed")
        let window = LMKThemeTesting.host(chip, theme: theme)
        defer { window.isHidden = true }
        #expect(chip.backgroundColor == UIColor.clear)
        #expect(chip.titleLabel.textColor == UIColor.red)
        #expect(chip.contentStack.spacing == 9)

        chip.style = .filled.tint(.blue)
        #expect(chip.backgroundColor == UIColor.blue)
        #expect(chip.contentStack.spacing == 9)
    }

    @Test
    func `didApplyStyle runs after every apply`() {
        let chip = LMKChipView(text: "Hook")
        var count = 0
        chip.didApplyStyle = { _ in count += 1 }
        chip.style = .outlined
        #expect(count == 1)
        chip.isSelected = true
        #expect(count == 2)
    }

    @Test
    func `Style merging keeps the base fields`() {
        let base = LMKChipView.Style(variant: .outlined, tintColor: .red, iconSize: 10)
        let merged = base.merging(LMKChipView.Style(tintColor: .blue))
        #expect(merged.variant == .outlined)
        #expect(merged.tintColor == UIColor.blue)
        #expect(merged.iconSize == 10)
    }
}
