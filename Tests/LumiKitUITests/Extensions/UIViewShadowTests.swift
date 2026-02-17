//
//  UIViewShadowTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - UIView+LMKShadow

@Suite("UIView+LMKShadow")
@MainActor
struct UIViewShadowTests {
    @Test("lmk_applyShadow sets layer properties")
    func applyShadow() {
        let view = UIView()
        view.lmk_applyShadow(LMKShadow.card())
        #expect(view.layer.shadowOpacity > 0)
        #expect(!view.layer.masksToBounds)
    }

    @Test("lmk_removeShadow zeros opacity")
    func removeShadow() {
        let view = UIView()
        view.lmk_applyShadow(LMKShadow.card())
        view.lmk_removeShadow()
        #expect(view.layer.shadowOpacity == 0)
    }
}
