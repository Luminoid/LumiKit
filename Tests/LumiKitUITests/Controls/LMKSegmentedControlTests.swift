//
//  LMKSegmentedControlTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - LMKSegmentedControl

@Suite("LMKSegmentedControl")
@MainActor
struct LMKSegmentedControlTests {
    @Test("Creates with correct number of segments")
    func creation() {
        let control = LMKSegmentedControl(items: ["A", "B", "C"])
        #expect(control.numberOfSegments == 3)
    }

    @Test("Handlers can be set")
    func handlersSet() {
        let control = LMKSegmentedControl(items: ["X", "Y"])
        control.valueChangedHandler = { _ in }
        control.didValueChangeHandler = { _ in }
        #expect(control.valueChangedHandler != nil)
        #expect(control.didValueChangeHandler != nil)
    }
}
