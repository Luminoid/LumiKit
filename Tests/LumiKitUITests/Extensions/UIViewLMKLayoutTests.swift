//
//  UIViewLMKLayoutTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - UIView+LMKLayout

@Suite("UIView+LMKLayout")
@MainActor
struct UIViewLMKLayoutTests {
    @Test("lmk_safeAreaSnp returns non-nil DSL")
    func safeAreaSnpAccessor() {
        let view = UIView()
        // Accessing the property should not crash and returns a valid DSL
        let _ = view.lmk_safeAreaSnp
    }

    @Test("lmk_setEdgesEqualToSuperview adds constraints")
    func edgesEqualToSuperview() {
        let parent = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        let child = UIView()
        parent.addSubview(child)
        child.lmk_setEdgesEqualToSuperview()
        parent.layoutIfNeeded()
        #expect(child.frame == parent.bounds)
    }

    @Test("lmk_setEdgesEqualToSuperview is no-op without superview")
    func edgesEqualToSuperviewNoSuperview() {
        let child = UIView()
        // Should not crash when called without a superview
        child.lmk_setEdgesEqualToSuperview()
    }

    @Test("lmk_centerInSuperview centers child in parent")
    func centerInSuperview() {
        let parent = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        let child = UIView()
        parent.addSubview(child)
        child.lmk_setAutoLayoutSize(width: 50, height: 50)
        child.lmk_centerInSuperview()
        parent.layoutIfNeeded()
        #expect(child.center.x == parent.bounds.midX)
        #expect(child.center.y == parent.bounds.midY)
    }

    @Test("lmk_centerInSuperview is no-op without superview")
    func centerInSuperviewNoSuperview() {
        let child = UIView()
        // Should not crash when called without a superview
        child.lmk_centerInSuperview()
    }

    @Test("lmk_setAutoLayoutSize sets fixed width and height")
    func autoLayoutSize() {
        let parent = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        let child = UIView()
        parent.addSubview(child)
        child.lmk_setAutoLayoutSize(width: 100, height: 50)
        parent.layoutIfNeeded()
        #expect(child.frame.width == 100)
        #expect(child.frame.height == 50)
    }
}
