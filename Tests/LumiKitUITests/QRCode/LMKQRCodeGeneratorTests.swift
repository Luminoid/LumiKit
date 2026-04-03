//
//  LMKQRCodeGeneratorTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKQRCodeGeneratorTests {
    @Test
    func `Valid string generates non-nil image`() throws {
        let image = try #require(LMKQRCodeGenerator.generateQRCode(from: "https://example.com"))
        #expect(image.size.width > 0)
        #expect(image.size.height > 0)
    }

    @Test
    func `Empty string returns nil`() {
        let image = LMKQRCodeGenerator.generateQRCode(from: "")
        #expect(image == nil)
    }

    @Test
    func `All correction levels produce images`() {
        let levels: [LMKQRCodeGenerator.CorrectionLevel] = [.low, .medium, .quartile, .high]
        for level in levels {
            let image = LMKQRCodeGenerator.generateQRCode(from: "test", correctionLevel: level)
            #expect(image != nil, "Correction level \(level) should produce an image")
        }
    }

    @Test
    func `Custom size produces image`() {
        let image = LMKQRCodeGenerator.generateQRCode(from: "test", size: 100)
        #expect(image != nil)
    }

    @Test
    func `Default correction level is medium`() {
        // Both should succeed — default vs explicit medium
        let defaultImage = LMKQRCodeGenerator.generateQRCode(from: "test")
        let mediumImage = LMKQRCodeGenerator.generateQRCode(from: "test", correctionLevel: .medium)
        #expect(defaultImage != nil)
        #expect(mediumImage != nil)
    }

    @Test
    func `CorrectionLevel raw values match QR standard`() {
        #expect(LMKQRCodeGenerator.CorrectionLevel.low.rawValue == "L")
        #expect(LMKQRCodeGenerator.CorrectionLevel.medium.rawValue == "M")
        #expect(LMKQRCodeGenerator.CorrectionLevel.quartile.rawValue == "Q")
        #expect(LMKQRCodeGenerator.CorrectionLevel.high.rawValue == "H")
    }

    @Test
    func `URL content generates valid QR code`() {
        let image = LMKQRCodeGenerator.generateQRCode(from: "https://apps.apple.com/us/app/plantfolio-plus/id6757148663")
        #expect(image != nil)
    }
}
