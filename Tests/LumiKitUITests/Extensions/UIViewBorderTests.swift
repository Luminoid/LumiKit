//
//  UIViewBorderTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - UIView+LMKBorder

@Suite("UIView+LMKBorder")
@MainActor
struct UIViewBorderTests {
    @Test("lmk_applyBorder sets layer properties")
    func applyBorder() {
        let view = UIView()
        view.lmk_applyBorder(color: .red, width: 2, cornerRadius: 8)
        #expect(view.layer.borderWidth == 2)
        #expect(view.layer.cornerRadius == 8)
        #expect(view.layer.masksToBounds)
    }

    @Test("lmk_removeBorder clears layer properties")
    func removeBorder() {
        let view = UIView()
        view.lmk_applyBorder(color: .red, width: 2)
        view.lmk_removeBorder()
        #expect(view.layer.borderWidth == 0)
    }

    @Test("lmk_applyCornerRadius sets radius and masking")
    func applyCornerRadius() {
        let view = UIView()
        view.lmk_applyCornerRadius(12, masking: false)
        #expect(view.layer.cornerRadius == 12)
        #expect(!view.layer.masksToBounds)
    }
}
