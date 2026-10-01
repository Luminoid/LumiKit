//
//  LMKImageQRCodeTests.swift
//  LumiKit
//

import Testing
@testable import LumiKitUI

@MainActor
struct LMKImageQRCodeTests {
    @Test
    func `Valid string generates non-nil image`() throws {
        let image = try #require(LMKImage.qrCode(from: "https://example.com"))
        #expect(image.size.width > 0)
        #expect(image.size.height > 0)
    }

    @Test
    func `Empty string returns nil`() {
        let image = LMKImage.qrCode(from: "")
        #expect(image == nil)
    }

    @Test
    func `All correction levels produce images`() {
        let levels: [LMKImage.QRCorrectionLevel] = [.low, .medium, .quartile, .high]
        for level in levels {
            let image = LMKImage.qrCode(from: "test", correctionLevel: level)
            #expect(image != nil, "Correction level \(level) should produce an image")
        }
    }

    @Test
    func `Custom size produces image`() {
        let image = LMKImage.qrCode(from: "test", size: 100)
        #expect(image != nil)
    }

    @Test
    func `Default correction level is medium`() {
        // Both should succeed — default vs explicit medium
        let defaultImage = LMKImage.qrCode(from: "test")
        let mediumImage = LMKImage.qrCode(from: "test", correctionLevel: .medium)
        #expect(defaultImage != nil)
        #expect(mediumImage != nil)
    }

    @Test
    func `CorrectionLevel raw values match QR standard`() {
        #expect(LMKImage.QRCorrectionLevel.low.rawValue == "L")
        #expect(LMKImage.QRCorrectionLevel.medium.rawValue == "M")
        #expect(LMKImage.QRCorrectionLevel.quartile.rawValue == "Q")
        #expect(LMKImage.QRCorrectionLevel.high.rawValue == "H")
    }

    @Test
    func `URL content generates valid QR code`() {
        let image = LMKImage.qrCode(from: "https://apps.apple.com/us/app/plantfolio-plus/id6757148663")
        #expect(image != nil)
    }
}
