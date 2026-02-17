//
//  LMKEmptyStateViewTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - LMKEmptyStateView

@Suite("LMKEmptyStateView")
@MainActor
struct LMKEmptyStateViewTests {
    @Test("font property returns correct font per style")
    func fontPerStyle() {
        #expect(LMKEmptyStateStyle.fullScreen.font == LMKTypography.h3)
        #expect(LMKEmptyStateStyle.card.font == LMKTypography.body)
        #expect(LMKEmptyStateStyle.inline.font == LMKTypography.caption)
    }

    @Test("isHorizontal is true only for inline")
    func isHorizontalOnlyInline() {
        #expect(!LMKEmptyStateStyle.fullScreen.isHorizontal)
        #expect(!LMKEmptyStateStyle.card.isHorizontal)
        #expect(LMKEmptyStateStyle.inline.isHorizontal)
    }

    @Test("iconSize is positive and ordered by style")
    func iconSizeOrdered() {
        #expect(LMKEmptyStateStyle.inline.iconSize < LMKEmptyStateStyle.card.iconSize)
        #expect(LMKEmptyStateStyle.card.iconSize < LMKEmptyStateStyle.fullScreen.iconSize)
    }
}
