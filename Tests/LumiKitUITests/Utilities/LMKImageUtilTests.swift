//
//  LMKImageUtilTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKImageUtil

@MainActor
struct LMKImageUtilTests {
    @Test
    func `getSFSymbolImage returns image for valid symbol name`() {
        let image = LMKImageUtil.getSFSymbolImage("heart.fill", pointSize: 24)
        #expect(image != nil)
    }

    @Test
    func `getSFSymbolImage returns nil for invalid symbol name`() {
        let image = LMKImageUtil.getSFSymbolImage("nonexistent.symbol.xyz", pointSize: 24)
        #expect(image == nil)
    }

    @Test
    func `getSFSymbolImage with color returns tinted image`() {
        let image = LMKImageUtil.getSFSymbolImage("star.fill", pointSize: 20, color: .red)
        #expect(image != nil)
        #expect(image?.renderingMode == .alwaysOriginal)
    }

    @Test
    func `getSFSymbolImage without color uses template rendering`() {
        let image = LMKImageUtil.getSFSymbolImage("star.fill", pointSize: 20)
        #expect(image != nil)
        #expect(image?.renderingMode != .alwaysOriginal)
    }
}

// MARK: - LMKImageUtil (makeSymbolImage)

@MainActor
struct LMKImageUtilMakeSymbolImageTests {
    @Test
    func `returns non-nil for valid symbol`() {
        let image = LMKImageUtil.makeSymbolImage("heart.fill", size: CGSize(width: 44, height: 44), symbolPointSize: 20, tintColor: .red)
        #expect(image != nil)
    }

    @Test
    func `returns nil for invalid symbol`() {
        let image = LMKImageUtil.makeSymbolImage("nonexistent.xyz.abc", size: CGSize(width: 44, height: 44), symbolPointSize: 20, tintColor: .red)
        #expect(image == nil)
    }

    @Test
    func `returns image of correct size`() {
        let size = CGSize(width: 60, height: 60)
        let image = LMKImageUtil.makeSymbolImage("star.fill", size: size, symbolPointSize: 24, tintColor: .blue)
        #expect(image?.size == size)
    }

    @Test
    func `without backgroundColor produces image`() {
        let image = LMKImageUtil.makeSymbolImage("checkmark", size: CGSize(width: 32, height: 32), symbolPointSize: 16, tintColor: .green, backgroundColor: nil)
        #expect(image != nil)
    }

    @Test
    func `with backgroundColor produces image`() {
        let image = LMKImageUtil.makeSymbolImage("checkmark", size: CGSize(width: 32, height: 32), symbolPointSize: 16, tintColor: .white, backgroundColor: .blue)
        #expect(image != nil)
    }
}
