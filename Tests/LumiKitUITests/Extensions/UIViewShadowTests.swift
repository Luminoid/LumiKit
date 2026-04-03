//
//  UIViewShadowTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - UIView+LMKShadow

@MainActor
struct UIViewShadowTests {
    @Test
    func `lmk_applyShadow sets layer properties`() {
        let view = UIView()
        view.lmk_applyShadow(LMKShadow.card())
        #expect(view.layer.shadowOpacity > 0)
        #expect(!view.layer.masksToBounds)
    }

    @Test
    func `lmk_removeShadow zeros opacity`() {
        let view = UIView()
        view.lmk_applyShadow(LMKShadow.card())
        view.lmk_removeShadow()
        #expect(view.layer.shadowOpacity == 0)
    }
}
