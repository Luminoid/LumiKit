//
//  UIButtonAnimationTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - UIButton+LMKAnimation

@MainActor
struct UIButtonAnimationTests {
    @Test
    func `lmk_animatePress doesn't crash`() {
        let button = UIButton()
        button.lmk_animatePress()
        // No crash = success — haptic and animation fire correctly
    }

    @Test
    func `lmk_animatePress is available as @objc selector`() {
        let button = UIButton()
        #expect(button.responds(to: #selector(UIButton.lmk_animatePress)))
    }
}
