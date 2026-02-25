//
//  UIControlTouchAreaTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - UIControl+LMKTouchArea

@Suite("UIControl+LMKTouchArea")
@MainActor
struct UIControlTouchAreaTests {
    @Test("Default touchAreaEdgeInsets is zero")
    func defaultInsets() {
        let control = UIControl()
        #expect(control.lmk_touchAreaEdgeInsets == .zero)
    }

    @Test("Setting touchAreaEdgeInsets persists value")
    func setInsets() {
        let control = UIControl()
        let insets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        control.lmk_touchAreaEdgeInsets = insets
        #expect(control.lmk_touchAreaEdgeInsets == insets)
    }

    @Test("pointInside with zero insets uses default bounds")
    func pointInsideZeroInsets() {
        let control = UIControl(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        #expect(control.lmk_pointInside(CGPoint(x: 22, y: 22), with: nil))
        #expect(!control.lmk_pointInside(CGPoint(x: 50, y: 50), with: nil))
    }

    @Test("pointInside with negative insets expands touch area")
    func pointInsideExpandedArea() {
        let control = UIControl(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        control.lmk_touchAreaEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)

        // Point outside original bounds but inside expanded area
        #expect(control.lmk_pointInside(CGPoint(x: -5, y: -5), with: nil))
        #expect(control.lmk_pointInside(CGPoint(x: 25, y: 25), with: nil))
        // Point outside expanded area
        #expect(!control.lmk_pointInside(CGPoint(x: -15, y: -15), with: nil))
    }

    @Test("pointInside with positive insets shrinks touch area")
    func pointInsideShrunkArea() {
        let control = UIControl(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        control.lmk_touchAreaEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

        // Point inside original but outside shrunk area
        #expect(!control.lmk_pointInside(CGPoint(x: 5, y: 5), with: nil))
        // Point inside shrunk area
        #expect(control.lmk_pointInside(CGPoint(x: 22, y: 22), with: nil))
    }

    @Test("pointInside returns false when control is disabled")
    func pointInsideDisabled() {
        let control = UIControl(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        control.lmk_touchAreaEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        control.isEnabled = false

        // When disabled, falls back to bounds.contains (zero insets behavior)
        #expect(control.lmk_pointInside(CGPoint(x: 22, y: 22), with: nil))
        // Points outside bounds return false even with expanded insets
        #expect(!control.lmk_pointInside(CGPoint(x: -5, y: -5), with: nil))
    }

    @Test("pointInside returns false when control is hidden")
    func pointInsideHidden() {
        let control = UIControl(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        control.lmk_touchAreaEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        control.isHidden = true

        #expect(control.lmk_pointInside(CGPoint(x: 22, y: 22), with: nil))
        #expect(!control.lmk_pointInside(CGPoint(x: -5, y: -5), with: nil))
    }

    @Test("touchAreaEdgeInsets uses associated object storage")
    func associatedObjectStorage() {
        let control1 = UIControl()
        let control2 = UIControl()

        control1.lmk_touchAreaEdgeInsets = UIEdgeInsets(top: -5, left: -5, bottom: -5, right: -5)

        // control2 should still have default insets
        #expect(control2.lmk_touchAreaEdgeInsets == .zero)
    }
}
