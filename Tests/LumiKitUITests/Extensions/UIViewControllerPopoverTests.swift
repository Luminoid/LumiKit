//
//  UIViewControllerPopoverTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - UIViewController+LMKPopover

@Suite("UIViewController+LMKPopover")
@MainActor
struct UIViewControllerPopoverTests {
    @Test("lmk_centeredPopoverSourceRect returns center of view bounds")
    func centeredPopoverSourceRect() {
        let vc = UIViewController()
        vc.view.frame = CGRect(x: 0, y: 0, width: 400, height: 600)

        let rect = vc.lmk_centeredPopoverSourceRect
        #expect(rect.origin.x == 200)
        #expect(rect.origin.y == 300)
        #expect(rect.width == 0)
        #expect(rect.height == 0)
    }

    @Test("lmk_configurePopoverForActionSheet configures popover source")
    func configurePopoverForActionSheet() {
        let vc = UIViewController()
        vc.view.frame = CGRect(x: 0, y: 0, width: 400, height: 600)
        let alert = UIAlertController(title: "Test", message: nil, preferredStyle: .actionSheet)

        vc.lmk_configurePopoverForActionSheet(alert)

        if let popover = alert.popoverPresentationController {
            #expect(popover.sourceView === vc.view)
            #expect(popover.sourceRect.origin.x == 200)
            #expect(popover.sourceRect.origin.y == 300)
            #expect(popover.permittedArrowDirections == [])
        }
    }

    @Test("lmk_configurePopoverForActionSheet no-op for alert style")
    func configurePopoverNoOpForAlert() {
        let vc = UIViewController()
        let alert = UIAlertController(title: "Test", message: nil, preferredStyle: .alert)

        vc.lmk_configurePopoverForActionSheet(alert)

        // Alert style should not configure popover
        if let popover = alert.popoverPresentationController {
            #expect(popover.sourceView == nil)
        }
    }
}
