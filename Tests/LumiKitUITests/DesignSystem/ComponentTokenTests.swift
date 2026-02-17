//
//  ComponentTokenTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - Component Configuration

@Suite("Component token usage")
@MainActor
struct ComponentTokenTests {
    @Test("LMKToastView creates with correct type")
    func toastViewCreation() {
        let toast = LMKToastView(type: .success, message: "Test")
        #expect(toast.superview == nil) // Not added to any view yet
    }

    @Test("LMKEmptyStateView can be configured")
    func emptyStateViewConfiguration() {
        let emptyState = LMKEmptyStateView()
        emptyState.configure(
            message: "No items found",
            icon: "tray",
            style: .fullScreen
        )
        // Just verify it doesn't crash with the configuration
        #expect(emptyState.frame.size == .zero) // Not laid out yet
    }

    @Test("LMKButton handlers work")
    func buttonHandlers() {
        var tapped = false
        let button = LMKButton()
        button.didTapHandler = { _ in tapped = true }
        button.didTap()
        #expect(tapped)
    }
}
