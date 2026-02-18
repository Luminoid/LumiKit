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

    @Test("lmk_setEdgesEqualToSuperView adds constraints")
    func edgesEqualToSuperView() {
        let parent = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        let child = UIView()
        parent.addSubview(child)
        child.lmk_setEdgesEqualToSuperView()
        parent.layoutIfNeeded()
        #expect(child.frame == parent.bounds)
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
