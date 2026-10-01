//
//  LMKSpacingTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKSpacing

@MainActor
struct LMKSpacingTests {
    @Test
    func `Spacing values follow 4pt grid`() {
        #expect(LMKSpacing.xxs == 2)
        #expect(LMKSpacing.xs == 4)
        #expect(LMKSpacing.small == 8)
        #expect(LMKSpacing.medium == 12)
        #expect(LMKSpacing.large == 16)
        #expect(LMKSpacing.xl == 20)
        #expect(LMKSpacing.xxl == 24)
    }

    @Test
    func `Canvas-scaled paddings follow the key window's size classes`() {
        let config = LMKTheme.current.spacing
        let cardPadding = LMKSpacing.cardPadding
        let cellPadding = LMKSpacing.cellPaddingVertical
        #if targetEnvironment(macCatalyst)
            #expect(cardPadding == config.cardPaddingMac)
            #expect(cellPadding == config.cellPaddingVerticalMac)
        #else
            if let window = LMKScene.keyWindow {
                let traits = window.traitCollection
                if traits.horizontalSizeClass == .regular, traits.verticalSizeClass == .regular {
                    let shortestSide = min(window.bounds.width, window.bounds.height)
                    let expectedCard = shortestSide <= 768 ? config.cardPaddingIPadCompact : shortestSide <= 834 ? config.cardPaddingIPadRegular : config.cardPaddingIPadLarge
                    let expectedCell = shortestSide <= 768 ? config.cellPaddingVerticalIPadCompact : shortestSide <= 834 ? config.cellPaddingVerticalIPadRegular : config.cellPaddingVerticalIPadLarge
                    #expect(cardPadding == expectedCard)
                    #expect(cellPadding == expectedCell)
                } else {
                    // Phone-class canvas (any iPhone, iPad Slide Over): plain theme values.
                    #expect(cardPadding == config.large)
                    #expect(cellPadding == config.small)
                }
            } else if UIDevice.current.userInterfaceIdiom == .pad {
                // No key window (the xctest host): an iPad assumes the regular tier.
                #expect(cardPadding == config.cardPaddingIPadRegular)
                #expect(cellPadding == config.cellPaddingVerticalIPadRegular)
            } else {
                #expect(cardPadding == config.large)
                #expect(cellPadding == config.small)
            }
        #endif
    }
}

// MARK: - LMKSpacingTheme

@MainActor
struct LMKSpacingConfigurationTests {
    @Test
    func `Default spacing matches original values`() {
        let config = LMKSpacingTheme()
        #expect(config.xxs == 2)
        #expect(config.xs == 4)
        #expect(config.small == 8)
        #expect(config.medium == 12)
        #expect(config.large == 16)
        #expect(config.xl == 20)
        #expect(config.xxl == 24)
        #expect(config.buttonPaddingVertical == 12)
        #expect(config.buttonPaddingHorizontal == 16)
    }

    @Test
    func `Custom spacing is applied via proxy`() {
        let original = LMKTheme.current.spacing
        defer { LMKTheme.update { $0.spacing = original } }

        LMKTheme.update { $0.spacing = .init(large: 20, xxl: 28) }
        #expect(LMKSpacing.large == 20)
        #expect(LMKSpacing.xxl == 28)
        // Other values stay at defaults
        #expect(LMKSpacing.small == 8)
    }
}
