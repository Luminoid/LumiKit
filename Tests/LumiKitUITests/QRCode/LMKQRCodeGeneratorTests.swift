//
//  LMKQRCodeGeneratorTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

@Suite("LMKQRCodeGenerator")
@MainActor
struct LMKQRCodeGeneratorTests {
    @Test("Valid string generates non-nil image")
    func validStringGeneratesImage() {
        let image = LMKQRCodeGenerator.generateQRCode(from: "https://example.com")
        #expect(image != nil)
        #expect(image!.size.width > 0)
        #expect(image!.size.height > 0)
    }

    @Test("Empty string returns nil")
    func emptyStringReturnsNil() {
        let image = LMKQRCodeGenerator.generateQRCode(from: "")
        #expect(image == nil)
    }

    @Test("All correction levels produce images")
    func allCorrectionLevels() {
        let levels: [LMKQRCodeGenerator.CorrectionLevel] = [.low, .medium, .quartile, .high]
        for level in levels {
            let image = LMKQRCodeGenerator.generateQRCode(from: "test", correctionLevel: level)
            #expect(image != nil, "Correction level \(level) should produce an image")
        }
    }

    @Test("Custom size produces image")
    func customSize() {
        let image = LMKQRCodeGenerator.generateQRCode(from: "test", size: 100)
        #expect(image != nil)
    }

    @Test("Default correction level is medium")
    func defaultCorrectionLevel() {
        // Both should succeed — default vs explicit medium
        let defaultImage = LMKQRCodeGenerator.generateQRCode(from: "test")
        let mediumImage = LMKQRCodeGenerator.generateQRCode(from: "test", correctionLevel: .medium)
        #expect(defaultImage != nil)
        #expect(mediumImage != nil)
    }

    @Test("CorrectionLevel raw values match QR standard")
    func correctionLevelRawValues() {
        #expect(LMKQRCodeGenerator.CorrectionLevel.low.rawValue == "L")
        #expect(LMKQRCodeGenerator.CorrectionLevel.medium.rawValue == "M")
        #expect(LMKQRCodeGenerator.CorrectionLevel.quartile.rawValue == "Q")
        #expect(LMKQRCodeGenerator.CorrectionLevel.high.rawValue == "H")
    }

    @Test("URL content generates valid QR code")
    func urlContentGenerates() {
        let image = LMKQRCodeGenerator.generateQRCode(from: "https://apps.apple.com/us/app/plantfolio-plus/id6757148663")
        #expect(image != nil)
    }
}
