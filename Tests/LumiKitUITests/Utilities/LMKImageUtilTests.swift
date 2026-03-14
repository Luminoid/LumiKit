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

// MARK: - LMKImageUtil (makeSymbolImage)

@Suite("LMKImageUtil (makeSymbolImage)")
@MainActor
struct LMKImageUtilMakeSymbolImageTests {
    @Test("returns non-nil for valid symbol")
    func validSymbol() {
        let image = LMKImageUtil.makeSymbolImage("heart.fill", size: CGSize(width: 44, height: 44), symbolPointSize: 20, tintColor: .red)
        #expect(image != nil)
    }

    @Test("returns nil for invalid symbol")
    func invalidSymbol() {
        let image = LMKImageUtil.makeSymbolImage("nonexistent.xyz.abc", size: CGSize(width: 44, height: 44), symbolPointSize: 20, tintColor: .red)
        #expect(image == nil)
    }

    @Test("returns image of correct size")
    func correctSize() {
        let size = CGSize(width: 60, height: 60)
        let image = LMKImageUtil.makeSymbolImage("star.fill", size: size, symbolPointSize: 24, tintColor: .blue)
        #expect(image?.size == size)
    }

    @Test("without backgroundColor produces image")
    func noBackground() {
        let image = LMKImageUtil.makeSymbolImage("checkmark", size: CGSize(width: 32, height: 32), symbolPointSize: 16, tintColor: .green, backgroundColor: nil)
        #expect(image != nil)
    }

    @Test("with backgroundColor produces image")
    func withBackground() {
        let image = LMKImageUtil.makeSymbolImage("checkmark", size: CGSize(width: 32, height: 32), symbolPointSize: 16, tintColor: .white, backgroundColor: .blue)
        #expect(image != nil)
    }
}
