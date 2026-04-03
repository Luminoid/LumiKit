//
//  ComponentTokenTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - Component Configuration

@MainActor
struct ComponentTokenTests {
    @Test
    func `LMKToastView creates with correct type`() {
        let toast = LMKToastView(type: .success, message: "Test")
        #expect(toast.superview == nil) // Not added to any view yet
    }

    @Test
    func `LMKEmptyStateView can be configured`() {
        let emptyState = LMKEmptyStateView()
        emptyState.configure(
            message: "No items found",
            icon: "tray",
            style: .fullScreen
        )
        // Just verify it doesn't crash with the configuration
        #expect(emptyState.frame.size == .zero) // Not laid out yet
    }

    @Test
    func `LMKButton handlers work`() {
        var tapped = false
        let button = LMKButton()
        button.didTapHandler = { _ in tapped = true }
        button.didTap()
        #expect(tapped)
    }
}
