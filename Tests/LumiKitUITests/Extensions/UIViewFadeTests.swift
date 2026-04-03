//
//  UIViewFadeTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - UIView+LMKFade

@MainActor
struct UIViewLMKFadeTests {
    @Test
    func `fadeIn with zero duration sets alpha immediately`() {
        let view = UIView()
        view.alpha = 0
        view.lmk_fadeIn(1.0, duration: 0) { _ in }
        #expect(view.alpha == 1.0)
    }

    @Test
    func `fadeOut with zero duration sets alpha immediately`() {
        let view = UIView()
        view.alpha = 1.0
        view.lmk_fadeOut(0.0, duration: 0) { _ in }
        #expect(view.alpha == 0.0)
    }

    @Test
    func `fadeIn custom alpha is respected with zero duration`() {
        let view = UIView()
        view.alpha = 0
        view.lmk_fadeIn(0.5, duration: 0) { _ in }
        #expect(view.alpha == 0.5)
    }
}
