//
//  LMKControlHitTestingTests.swift
//  LumiKit
//
//  A `UIControl` starts tracking only when it is the hit-test view: a touch that
//  lands on an interactive subview and reaches the control through the responder
//  chain never fires `touchUpInside`. Every custom control answers hit tests itself.
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - Control hit testing

@MainActor
struct LMKControlHitTestingTests {
    private static func layOut(_ control: UIControl, size: CGSize = CGSize(width: 120, height: 60)) {
        control.frame = CGRect(origin: .zero, size: size)
        control.layoutIfNeeded()
    }

    private static func hitsItself(_ control: UIControl) -> Bool {
        let points = [
            CGPoint(x: control.bounds.midX, y: control.bounds.midY),
            CGPoint(x: control.bounds.minX + 2, y: control.bounds.midY),
            CGPoint(x: control.bounds.maxX - 2, y: control.bounds.midY),
        ]
        return points.allSatisfy { control.hitTest($0, with: nil) === control }
    }

    @Test
    func `A tappable chip is the hit view across its title and icon`() {
        let chip = LMKChipView(text: "Photos", icon: UIImage(systemName: "photo"), style: .outlined)
        chip.onTap = {}
        Self.layOut(chip, size: CGSize(width: 96, height: 44))
        #expect(Self.hitsItself(chip))
        let titleCenter = chip.convert(CGPoint(x: chip.titleLabel.bounds.midX, y: chip.titleLabel.bounds.midY), from: chip.titleLabel)
        #expect(chip.hitTest(titleCenter, with: nil) === chip)
    }

    @Test
    func `A dismissible chip hands its xmark the touch and keeps the rest`() {
        let chip = LMKChipView(text: "Indoor", style: .filled)
        chip.onTap = {}
        chip.onDismiss = {}
        Self.layOut(chip, size: CGSize(width: 120, height: 44))
        let dismissCenter = chip.convert(CGPoint(x: chip.dismissButton.bounds.midX, y: chip.dismissButton.bounds.midY), from: chip.dismissButton)
        #expect(chip.hitTest(dismissCenter, with: nil) === chip.dismissButton)
        let titleCenter = chip.convert(CGPoint(x: chip.titleLabel.bounds.midX, y: chip.titleLabel.bounds.midY), from: chip.titleLabel)
        #expect(chip.hitTest(titleCenter, with: nil) === chip)
    }

    @Test
    func `A disabled or hidden chip takes no touches`() {
        let chip = LMKChipView(text: "Indoor")
        chip.onTap = {}
        Self.layOut(chip, size: CGSize(width: 96, height: 44))
        chip.isHidden = true
        #expect(chip.hitTest(CGPoint(x: 48, y: 22), with: nil) == nil)
        chip.isHidden = false
        chip.isUserInteractionEnabled = false
        #expect(chip.hitTest(CGPoint(x: 48, y: 22), with: nil) == nil)
    }

    @Test
    func `A floating button with a badge is the hit view under the badge`() throws {
        let button = LMKFloatingButton(icon: UIImage(systemName: "plus"))
        button.badge = .count(3)
        Self.layOut(button, size: CGSize(width: 56, height: 56))
        let badge = try #require(button.subviews.first { $0 is LMKBadgeView })
        let badgeCenter = button.convert(CGPoint(x: badge.bounds.midX, y: badge.bounds.midY), from: badge)
        #expect(button.bounds.contains(badgeCenter))
        #expect(button.hitTest(badgeCenter, with: nil) === button)
    }

    @Test
    func `Every custom control is its own hit view`() {
        let tile = LMKActionTile()
        tile.configure(title: "Feed", systemName: "fork.knife")
        let row = LMKActionSheetRowView()
        row.configure(LMKActionSheetRowView.Content(title: "Share", subtitle: "Send a copy", icon: UIImage(systemName: "square.and.arrow.up")))
        let controls: [UIControl] = [
            LMKCheckbox(),
            LMKPhotoButton(size: 60),
            LMKSwitch(),
            LMKRatingControl(maximum: 5),
            tile,
            row,
            LMKCalendarDayCell(frame: .zero),
        ]
        for control in controls {
            Self.layOut(control)
            #expect(Self.hitsItself(control), "\(type(of: control)) lets a subview take the touch")
        }
    }
}
