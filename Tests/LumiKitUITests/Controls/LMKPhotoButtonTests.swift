//
//  LMKPhotoButtonTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKPhotoButtonTests {
    private func makeButton(size: CGFloat = 120, style: LMKPhotoButton.Style = LMKPhotoButton.Style()) -> (LMKPhotoButton, UIWindow) {
        let button = LMKPhotoButton(size: size, style: style)
        let window = LMKThemeTesting.host(button)
        button.frame = CGRect(origin: .zero, size: button.intrinsicContentSize)
        button.layoutIfNeeded()
        return (button, window)
    }

    @Test
    func `Defaults: circular placeholder with the add label`() {
        let (button, window) = makeButton()
        defer { window.isHidden = true }
        #expect(button.intrinsicContentSize == CGSize(width: 120, height: 120))
        #expect(button.layer.cornerRadius == 60)
        #expect(button.clipsToBounds)
        #expect(button.backgroundColor == LMKColor.backgroundSecondary)
        #expect(button.imageView.image == UIImage(systemName: "camera.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: LMKLayout.symbolHero, weight: .light)))
        #expect(button.imageView.contentMode == .center)
        #expect(button.imageView.tintColor == LMKColor.textTertiary)
        #expect(button.accessibilityLabel == LMKPhotoButton.Strings().addAccessibilityLabel)
        #expect(button.accessibilityTraits.contains(.button))
        #expect(!button.accessibilityTraits.contains(.image))
        #expect(button.imageView.frame == button.bounds)
    }

    @Test
    func `Setting an image fills the well and switches the label`() {
        let (button, window) = makeButton()
        defer { window.isHidden = true }
        let photo = UIImage.lmk_solidColor(.red, size: CGSize(width: 20, height: 20))
        button.image = photo
        #expect(button.imageView.image === photo)
        #expect(button.imageView.contentMode == .scaleAspectFill)
        #expect(button.accessibilityLabel == LMKPhotoButton.Strings().changeAccessibilityLabel)
        #expect(button.accessibilityTraits.contains(.image))
        button.image = nil
        #expect(button.imageView.contentMode == .center)
        #expect(button.accessibilityLabel == LMKPhotoButton.Strings().addAccessibilityLabel)
    }

    @Test
    func `size changes the intrinsic size and the circle`() {
        let (button, window) = makeButton()
        defer { window.isHidden = true }
        button.size = 80
        button.frame = CGRect(origin: .zero, size: button.intrinsicContentSize)
        button.layoutIfNeeded()
        #expect(button.intrinsicContentSize == CGSize(width: 80, height: 80))
        #expect(button.layer.cornerRadius == 40)
    }

    @Test
    func `Rounded shape and surface overrides`() {
        let (button, window) = makeButton(style: LMKPhotoButton.Style(shape: .rounded(radius: 12), surface: LMKSurfaceStyle(background: .solid(.blue))))
        defer { window.isHidden = true }
        #expect(button.layer.cornerRadius == 12)
        #expect(button.backgroundColor == UIColor.blue)
        button.style = LMKPhotoButton.Style(shape: .rounded())
        #expect(button.layer.cornerRadius == LMKCornerRadius.large)
    }

    @Test
    func `Tap calls onTap; disabled dims and blocks it`() {
        let (button, window) = makeButton()
        defer { window.isHidden = true }
        var taps = 0
        button.onTap = { taps += 1 }
        button.sendActions(for: .touchUpInside)
        button.perform(NSSelectorFromString("handleTap"))
        #expect(taps >= 1)
        button.isEnabled = false
        #expect(abs(button.alpha - LMKAlpha.disabled) < 0.001)
        #expect(button.accessibilityTraits.contains(.notEnabled))
        let before = taps
        button.perform(NSSelectorFromString("handleTap"))
        #expect(taps == before)
    }

    @Test
    func `Theme slot and strings`() {
        var theme = LMKTheme()
        theme.photoButton = LMKPhotoButton.Style(placeholderSymbol: "person.fill", placeholderTint: .magenta)
        let (button, window) = makeButton()
        defer { window.isHidden = true }
        button.applyTheme(theme)
        #expect(button.imageView.tintColor == UIColor.magenta)
        #expect(button.imageView.image == UIImage(systemName: "person.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: theme.layout.symbolHero, weight: .light)))
        button.strings = LMKPhotoButton.Strings(addAccessibilityLabel: "Add avatar", changeAccessibilityLabel: "Change avatar")
        #expect(button.accessibilityLabel == "Add avatar")
        #expect(LMKPhotoButton.Style().merging(LMKPhotoButton.Style(shape: .circle)).shape == .circle)
    }
}
