//
//  LMKPhotoButtonTests.swift
//  LumiKit
//

import Testing
import UIKit
import UniformTypeIdentifiers
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
    func `A small well still answers a 44pt touch; a disabled one absorbs touches inside its bounds`() {
        let (button, window) = makeButton(size: 32)
        defer { window.isHidden = true }
        #expect(button.point(inside: CGPoint(x: 16, y: -5), with: nil))
        #expect(!button.point(inside: CGPoint(x: 16, y: -7), with: nil))
        button.isEnabled = false
        #expect(button.point(inside: CGPoint(x: 16, y: 16), with: nil))
        #expect(!button.point(inside: CGPoint(x: 16, y: -5), with: nil), "no expanded area while disabled")
        button.isHidden = true
        #expect(!button.point(inside: CGPoint(x: 16, y: 16), with: nil))
    }

    @Test
    func `A surface shadow leaves the photo clipped to the shape`() {
        let (button, window) = makeButton(style: LMKPhotoButton.Style(surface: LMKSurfaceStyle(shadow: .level(.level2))))
        defer { window.isHidden = true }
        button.image = UIImage.lmk_solidColor(.red, size: CGSize(width: 20, height: 20))
        button.layoutIfNeeded()
        #expect(!button.layer.masksToBounds, "the well itself does not clip, or the shadow would go")
        #expect(button.imageView.layer.masksToBounds)
        #expect(button.imageView.layer.cornerRadius == 60, "the photo clips itself to the circle")
        button.style = LMKPhotoButton.Style(shape: .rounded(radius: 12), surface: LMKSurfaceStyle(shadow: .level(.level2)))
        #expect(button.imageView.layer.cornerRadius == 12)
    }

    @Test
    func `Placeholder point size and weight shape the symbol`() {
        let (button, window) = makeButton(style: LMKPhotoButton.Style(placeholderPointSize: 40, placeholderWeight: .bold))
        defer { window.isHidden = true }
        #expect(button.imageView.image == UIImage(systemName: "camera.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 40, weight: .bold)))
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

    // MARK: - Drop

    @Test
    func `onDropImage installs a drop target only while set`() {
        let (button, window) = makeButton()
        defer { window.isHidden = true }
        #expect(!button.interactions.contains { $0 is UIDropInteraction }, "inert by default")
        button.onDropImage = { _ in }
        #expect(button.interactions.count { $0 is UIDropInteraction } == 1)
        button.onDropImage = { _ in }
        #expect(button.interactions.count { $0 is UIDropInteraction } == 1, "setting it again adds no second target")
        button.onDropImage = nil
        #expect(!button.interactions.contains { $0 is UIDropInteraction })
    }

    @Test
    func `A dropped image arrives as its original bytes`() async throws {
        let (button, window) = makeButton()
        defer { window.isHidden = true }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let png = try #require(UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4), format: format).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }.pngData())
        var received: [Data] = []
        button.onDropImage = { received.append($0) }
        let text = NSItemProvider(object: "not a photo" as NSString)
        let image = NSItemProvider(item: png as NSData, typeIdentifier: UTType.png.identifier)
        button.handleDrop(of: [text, image])
        await LMKWait.until { !received.isEmpty }
        #expect(received == [png], "the first image provider, byte for byte")

        button.handleDrop(of: [text])
        try await Task.sleep(for: .milliseconds(100))
        #expect(received.count == 1, "nothing that is not an image")
    }

    @Test
    func `A hovering drag shows an accent outline unless the style sets a highlighted look`() {
        let (button, window) = makeButton()
        defer { window.isHidden = true }
        #expect(button.layer.borderWidth == 0)
        button.isHighlighted = true
        #expect(button.layer.borderWidth == 0, "a press keeps its own feedback")
        button.isHighlighted = false
        button.isDropTargeted = true
        #expect(button.layer.borderWidth == LMKLayout.pixelAligned(2, for: button))
        button.isDropTargeted = false
        #expect(button.layer.borderWidth == 0)

        button.style = LMKPhotoButton.Style(highlighted: LMKControlStateStyle(background: .solid(.blue)))
        button.isDropTargeted = true
        #expect(button.backgroundColor == UIColor.blue)
        #expect(button.layer.borderWidth == 0, "the style's highlighted look replaces the outline")
    }

    @Test
    func `Only the latest drop is delivered`() async throws {
        let (button, window) = makeButton()
        defer { window.isHidden = true }
        let first = Data([0x01])
        let second = Data([0x02])
        // The first drop answers only after the second one has.
        let slow = NSItemProvider()
        let gate = AsyncStream<Void>.makeStream()
        slow.registerDataRepresentation(forTypeIdentifier: UTType.png.identifier, visibility: .all) { completion in
            Task {
                for await _ in gate.stream {
                    break
                }
                completion(first, nil)
            }
            return nil
        }
        var received: [Data] = []
        button.onDropImage = { received.append($0) }
        button.handleDrop(of: [slow])
        button.handleDrop(of: [NSItemProvider(item: second as NSData, typeIdentifier: UTType.png.identifier)])
        await LMKWait.until { !received.isEmpty }
        gate.continuation.yield()
        gate.continuation.finish()
        try await Task.sleep(for: .milliseconds(200))
        #expect(received == [second])
    }
}
