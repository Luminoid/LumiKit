//
//  UIViewBorderTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - UIView+LMKBorder

@MainActor
struct UIViewBorderTests {
    @Test
    func `lmk_applyBorder sets layer properties`() {
        let view = UIView()
        view.lmk_applyBorder(color: .red, width: 2, cornerRadius: 8)
        #expect(view.layer.borderWidth == 2)
        #expect(view.layer.cornerRadius == 8)
        #expect(view.layer.masksToBounds)
    }

    @Test
    func `lmk_removeBorder clears layer properties`() {
        let view = UIView()
        view.lmk_applyBorder(color: .red, width: 2)
        view.lmk_removeBorder()
        #expect(view.layer.borderWidth == 0)
    }

    @Test
    func `lmk_applyCornerRadius sets radius and masking`() {
        let view = UIView()
        view.lmk_applyCornerRadius(12, masking: false)
        #expect(view.layer.cornerRadius == 12)
        #expect(!view.layer.masksToBounds)
    }
}
