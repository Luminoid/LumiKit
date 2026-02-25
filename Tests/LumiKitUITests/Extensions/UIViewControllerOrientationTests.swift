//
//  UIViewControllerOrientationTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - UIViewController+LMKOrientation

@Suite("UIViewController+LMKOrientation")
@MainActor
struct UIViewControllerOrientationTests {
    @Test("lmk_windowOrientation returns unknown when no window")
    func orientationWithoutWindow() {
        let vc = UIViewController()
        vc.loadViewIfNeeded()
        // Without a window, should return .unknown
        #expect(vc.lmk_windowOrientation == .unknown)
    }
}
