//
//  LMKEmptyStateViewTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKEmptyStateView

@MainActor
struct LMKEmptyStateViewTests {
    @Test
    func `font property returns correct font per style`() {
        #expect(LMKEmptyStateStyle.fullScreen.font == LMKTypography.h3)
        #expect(LMKEmptyStateStyle.card.font == LMKTypography.body)
        #expect(LMKEmptyStateStyle.inline.font == LMKTypography.caption)
    }

    @Test
    func `isHorizontal is true only for inline`() {
        #expect(!LMKEmptyStateStyle.fullScreen.isHorizontal)
        #expect(!LMKEmptyStateStyle.card.isHorizontal)
        #expect(LMKEmptyStateStyle.inline.isHorizontal)
    }

    @Test
    func `iconSize is positive and ordered by style`() {
        #expect(LMKEmptyStateStyle.inline.iconSize < LMKEmptyStateStyle.card.iconSize)
        #expect(LMKEmptyStateStyle.card.iconSize < LMKEmptyStateStyle.fullScreen.iconSize)
    }
}
