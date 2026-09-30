//
//  LMKLayoutTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKLayout

@MainActor
struct LMKLayoutTests {
    @Test
    func `minimumTouchTarget meets Apple HIG`() {
        #expect(LMKLayout.minimumTouchTarget >= 44)
    }

    @Test
    func `Icon sizes are positive and ordered`() {
        #expect(LMKLayout.iconExtraSmall > 0)
        #expect(LMKLayout.iconSmall > LMKLayout.iconExtraSmall)
        #expect(LMKLayout.iconMedium > LMKLayout.iconSmall)
    }

    @Test
    func `Cell height minimum is positive`() {
        #expect(LMKLayout.cellHeightMin > 0)
    }

    @Test
    func `hairline(forScale:) is one physical pixel`() {
        #expect(LMKLayout.hairline(forScale: 1) == 1)
        #expect(LMKLayout.hairline(forScale: 2) == 0.5)
        #expect(abs(LMKLayout.hairline(forScale: 3) - 1.0 / 3.0) < 0.0001)
    }

    @Test
    func `pixelAligned rounds a length to whole pixels`() {
        // 1.5pt is 4.5 pixels at 3x: some edges would render 4 pixels and others 5.
        #expect(abs(LMKLayout.pixelAligned(1.5, scale: 3) - 5.0 / 3.0) < 0.0001)
        #expect(LMKLayout.pixelAligned(1.5, scale: 2) == 1.5)
        #expect(LMKLayout.pixelAligned(1, scale: 3) == 1)
        #expect(LMKLayout.pixelAligned(2.4, scale: 1) == 2)
        #expect(abs(LMKLayout.pixelAligned(1.0 / 3.0, scale: 3) - 1.0 / 3.0) < 0.0001)
    }

    @Test
    func `pixelAligned keeps a positive length at one pixel or more`() {
        #expect(abs(LMKLayout.pixelAligned(0.1, scale: 3) - 1.0 / 3.0) < 0.0001)
        #expect(LMKLayout.pixelAligned(0, scale: 3) == 0)
        #expect(LMKLayout.pixelAligned(-1, scale: 3) == 0)
        #expect(LMKLayout.pixelAligned(0.2, scale: 0) == 1)
    }

    @Test
    func `hairline(forScale:) clamps degenerate scales to a full point`() {
        #expect(LMKLayout.hairline(forScale: 0) == 1)
        #expect(LMKLayout.hairline(forScale: 0.5) == 1)
        #expect(LMKLayout.hairline(forScale: -2) == 1)
    }

    @Test
    func `hairline(for:) follows the view's display scale trait`() {
        let view = UIView()
        let hairline = LMKLayout.hairline(for: view)
        #expect(hairline > 0)
        #expect(hairline <= 1)
        if let scale = LMKScene.displayScale(of: view) {
            #expect(hairline == LMKLayout.hairline(forScale: scale))
        } else {
            #expect(hairline == LMKLayout.hairline)
        }
    }

    @Test
    func `hairline resolves from the key window scale with a sane fallback`() {
        let hairline = LMKLayout.hairline
        #expect(hairline > 0)
        #expect(hairline <= 1)
    }
}

// MARK: - LMKLayoutTheme

@MainActor
struct LMKLayoutConfigurationTests {
    @Test
    func `Default layout matches original values`() {
        let config = LMKLayoutTheme()
        #expect(config.minimumTouchTarget == 44)
        #expect(config.iconMedium == 24)
        #expect(config.iconSmall == 20)
        #expect(config.iconExtraSmall == 16)
        #expect(config.iconCircle == 36)
        #expect(config.pullThreshold == 80)
        #expect(config.cellHeightMin == 100)
    }

    @Test
    func `Custom layout is applied via proxy`() {
        let original = LMKTheme.current.layout
        defer { LMKTheme.update { $0.layout = original } }

        LMKTheme.update { $0.layout = .init(iconMedium: 28) }
        #expect(LMKLayout.iconMedium == 28)
        #expect(LMKLayout.iconSmall == 20) // unchanged
    }

    @Test
    func `Icon circle token is accessible and larger than the icon it wraps`() {
        #expect(LMKLayout.iconCircle == 36)
        #expect(LMKLayout.iconCircle > LMKLayout.iconExtraSmall)
    }
}

// MARK: - 1.0 layout additions

@MainActor
struct LMKLayoutScaleTests {
    @Test
    func `Symbol scale is monotonic`() {
        let scale = [
            LMKLayout.symbolMicro, LMKLayout.symbolBadge, LMKLayout.symbolAccessory, LMKLayout.symbolInline,
            LMKLayout.symbolRow, LMKLayout.symbolProminent, LMKLayout.symbolAction, LMKLayout.symbolLarge,
            LMKLayout.symbolPlaceholder, LMKLayout.symbolIllustration, LMKLayout.symbolHero,
        ]
        #expect(scale == scale.sorted())
        #expect(Set(scale).count == scale.count)
        #expect(LMKLayout.symbolRow == 16)
    }

    @Test
    func `Row heights default to 44 60 72 64 and readable width to 700`() {
        #expect(LMKLayout.rowHeightCompact == 44)
        #expect(LMKLayout.rowHeight == 60)
        #expect(LMKLayout.rowHeightComfortable == 72)
        #expect(LMKLayout.rowHeightEstimated == 64)
        #expect(LMKLayout.readableContentMaxWidth == 700)
    }

    @Test
    func `Theme override propagates to the symbol and row tokens`() {
        let original = LMKTheme.current.layout
        defer { LMKTheme.update { $0.layout = original } }
        LMKTheme.update { $0.layout = .init(symbolRow: 17, rowHeight: 64, readableContentMaxWidth: 640) }
        #expect(LMKLayout.symbolRow == 17)
        #expect(LMKLayout.rowHeight == 64)
        #expect(LMKLayout.readableContentMaxWidth == 640)
    }
}
