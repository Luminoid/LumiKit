//
//  UIViewControllerKeyboardDismissTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - UIViewController (lmk_dismissKeyboardOnTap)

@MainActor
struct UIViewControllerKeyboardDismissTests {
    @Test
    func `Installs a tap recognizer on the root view`() {
        let viewController = UIViewController()
        let before = viewController.view.gestureRecognizers?.count ?? 0

        viewController.lmk_dismissKeyboardOnTap()

        let recognizers = viewController.view.gestureRecognizers ?? []
        #expect(recognizers.count == before + 1)
        #expect(recognizers.last is UITapGestureRecognizer)
    }

    @Test
    func `Tap recognizer lets touches through to controls`() {
        let viewController = UIViewController()
        viewController.lmk_dismissKeyboardOnTap()

        let tap = viewController.view.gestureRecognizers?.last as? UITapGestureRecognizer
        #expect(tap?.cancelsTouchesInView == false)
    }
}
