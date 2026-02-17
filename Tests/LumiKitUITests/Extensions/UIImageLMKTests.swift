//
//  UIImageLMKTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - UIImage+LMK

@Suite("UIImage+LMK")
@MainActor
struct UIImageLMKTests {
    @Test("lmk_resized maxDimension preserves aspect ratio")
    func resizedMaxDimension() {
        let image = UIImage.lmk_solidColor(.red, size: CGSize(width: 200, height: 100))
        let resized = image.lmk_resized(maxDimension: 100)
        #expect(resized.size.width == 100)
        #expect(resized.size.height == 50)
    }

    @Test("lmk_resized to exact size")
    func resizedExactSize() {
        let image = UIImage.lmk_solidColor(.blue, size: CGSize(width: 100, height: 100))
        let resized = image.lmk_resized(to: CGSize(width: 50, height: 50))
        #expect(resized.size.width == 50)
        #expect(resized.size.height == 50)
    }

    @Test("lmk_solidColor creates image with correct size")
    func solidColor() {
        let image = UIImage.lmk_solidColor(.green, size: CGSize(width: 10, height: 20))
        #expect(image.size.width == 10)
        #expect(image.size.height == 20)
    }

    @Test("lmk_rounded returns non-nil image")
    func rounded() {
        let image = UIImage.lmk_solidColor(.red, size: CGSize(width: 100, height: 100))
        let rounded = image.lmk_rounded(cornerRadius: 10)
        #expect(rounded.size.width == 100)
    }
}
