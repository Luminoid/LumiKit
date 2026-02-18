//
//  LMKImageUtilTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - LMKImageUtil

@Suite("LMKImageUtil")
@MainActor
struct LMKImageUtilTests {
    @Test("getSFSymbolImage returns image for valid symbol name")
    func validSymbolReturnsImage() {
        let image = LMKImageUtil.getSFSymbolImage("heart.fill", pointSize: 24)
        #expect(image != nil)
    }

    @Test("getSFSymbolImage returns nil for invalid symbol name")
    func invalidSymbolReturnsNil() {
        let image = LMKImageUtil.getSFSymbolImage("nonexistent.symbol.xyz", pointSize: 24)
        #expect(image == nil)
    }

    @Test("getSFSymbolImage with color returns tinted image")
    func symbolWithColor() {
        let image = LMKImageUtil.getSFSymbolImage("star.fill", pointSize: 20, color: .red)
        #expect(image != nil)
        #expect(image?.renderingMode == .alwaysOriginal)
    }

    @Test("getSFSymbolImage without color uses template rendering")
    func symbolWithoutColor() {
        let image = LMKImageUtil.getSFSymbolImage("star.fill", pointSize: 20)
        #expect(image != nil)
        #expect(image?.renderingMode != .alwaysOriginal)
    }
}
