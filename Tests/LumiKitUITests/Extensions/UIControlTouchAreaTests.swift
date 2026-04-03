//
//  UIControlTouchAreaTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - UIControl+LMKTouchArea

@MainActor
struct UIControlTouchAreaTests {
    @Test
    func `Default touchAreaEdgeInsets is zero`() {
        let control = UIControl()
        #expect(control.lmk_touchAreaEdgeInsets == .zero)
    }

    @Test
    func `Setting touchAreaEdgeInsets persists value`() {
        let control = UIControl()
        let insets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        control.lmk_touchAreaEdgeInsets = insets
        #expect(control.lmk_touchAreaEdgeInsets == insets)
    }

    @Test
    func `pointInside with zero insets uses default bounds`() {
        let control = UIControl(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        #expect(control.lmk_pointInside(CGPoint(x: 22, y: 22), with: nil))
        #expect(!control.lmk_pointInside(CGPoint(x: 50, y: 50), with: nil))
    }

    @Test
    func `pointInside with negative insets expands touch area`() {
        let control = UIControl(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        control.lmk_touchAreaEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)

        // Point outside original bounds but inside expanded area
        #expect(control.lmk_pointInside(CGPoint(x: -5, y: -5), with: nil))
        #expect(control.lmk_pointInside(CGPoint(x: 25, y: 25), with: nil))
        // Point outside expanded area
        #expect(!control.lmk_pointInside(CGPoint(x: -15, y: -15), with: nil))
    }

    @Test
    func `pointInside with positive insets shrinks touch area`() {
        let control = UIControl(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        control.lmk_touchAreaEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

        // Point inside original but outside shrunk area
        #expect(!control.lmk_pointInside(CGPoint(x: 5, y: 5), with: nil))
        // Point inside shrunk area
        #expect(control.lmk_pointInside(CGPoint(x: 22, y: 22), with: nil))
    }

    @Test
    func `pointInside returns false when control is disabled`() {
        let control = UIControl(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        control.lmk_touchAreaEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        control.isEnabled = false

        // When disabled, falls back to bounds.contains (zero insets behavior)
        #expect(control.lmk_pointInside(CGPoint(x: 22, y: 22), with: nil))
        // Points outside bounds return false even with expanded insets
        #expect(!control.lmk_pointInside(CGPoint(x: -5, y: -5), with: nil))
    }

    @Test
    func `pointInside returns false when control is hidden`() {
        let control = UIControl(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        control.lmk_touchAreaEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        control.isHidden = true

        #expect(control.lmk_pointInside(CGPoint(x: 22, y: 22), with: nil))
        #expect(!control.lmk_pointInside(CGPoint(x: -5, y: -5), with: nil))
    }

    @Test
    func `touchAreaEdgeInsets uses associated object storage`() {
        let control1 = UIControl()
        let control2 = UIControl()

        control1.lmk_touchAreaEdgeInsets = UIEdgeInsets(top: -5, left: -5, bottom: -5, right: -5)

        // control2 should still have default insets
        #expect(control2.lmk_touchAreaEdgeInsets == .zero)
    }
}
