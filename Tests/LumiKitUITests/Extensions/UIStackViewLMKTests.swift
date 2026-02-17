//
//  UIStackViewLMKTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - UIStackView+LMK

@Suite("UIStackView+LMK")
@MainActor
struct UIStackViewLMKTests {
    @Test("Convenience init sets axis and spacing")
    func convenienceInit() {
        let stack = UIStackView(lmk_axis: .vertical, spacing: 12)
        #expect(stack.axis == .vertical)
        #expect(stack.spacing == 12)
    }

    @Test("lmk_addArrangedSubviews adds all views")
    func addArrangedSubviews() {
        let stack = UIStackView()
        let views = [UIView(), UIView(), UIView()]
        stack.lmk_addArrangedSubviews(views)
        #expect(stack.arrangedSubviews.count == 3)
    }

    @Test("lmk_removeAllArrangedSubviews clears all views")
    func removeAllArrangedSubviews() {
        let stack = UIStackView()
        stack.lmk_addArrangedSubviews([UIView(), UIView()])
        stack.lmk_removeAllArrangedSubviews()
        #expect(stack.arrangedSubviews.isEmpty)
    }
}
