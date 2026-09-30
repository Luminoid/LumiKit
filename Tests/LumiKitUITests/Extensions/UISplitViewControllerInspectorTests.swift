//
//  UISplitViewControllerInspectorTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct UISplitViewControllerInspectorTests {
    @Test
    func `The inspector column exists on iOS 26 and is inert before`() {
        let split = UISplitViewController(style: .doubleColumn)
        split.setViewController(UIViewController(), for: .primary)
        split.setViewController(UIViewController(), for: .secondary)
        let inspector = UIViewController()

        #expect(split.lmk_inspector == nil)
        #expect(!split.lmk_isShowingInspector)
        split.lmk_setInspector(inspector, preferredWidth: 320)

        if #available(iOS 26, *) {
            #expect(split.lmk_supportsInspector)
            #expect(split.lmk_inspector === inspector)
            #expect(split.preferredInspectorColumnWidth == 320)
            split.lmk_setInspector(nil)
            #expect(split.lmk_inspector == nil)
        } else {
            #expect(!split.lmk_supportsInspector)
            #expect(split.lmk_inspector == nil, "no column before 26")
            #expect(!split.lmk_isShowingInspector)
        }
        // Toggling without a window never traps on either branch.
        split.lmk_toggleInspector()
        split.lmk_setInspectorShown(false)
    }
}
