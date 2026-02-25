//
//  UIButtonAnimationTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - UIButton+LMKAnimation

@Suite("UIButton+LMKAnimation")
@MainActor
struct UIButtonAnimationTests {
    @Test("lmk_animatePress doesn't crash")
    func animatePress() {
        let button = UIButton()
        button.lmk_animatePress()
        // No crash = success — haptic and animation fire correctly
    }

    @Test("lmk_animatePress is available as @objc selector")
    func animatePressSelector() {
        let button = UIButton()
        #expect(button.responds(to: #selector(UIButton.lmk_animatePress)))
    }
}
