//
//  LMKCropAspectRatioTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKCropAspectRatio

struct CropAspectRatioTests {
    @Test
    func `Square ratio is 1.0`() {
        #expect(LMKCropAspectRatio.square.ratio == 1.0)
    }

    @Test
    func `Free ratio is nil`() {
        #expect(LMKCropAspectRatio.free.ratio == nil)
    }

    @Test
    func `All cases have display names`() {
        for ratio in LMKCropAspectRatio.allCases {
            #expect(!ratio.displayName.isEmpty)
        }
    }

    @Test
    func `4:3 ratio is approximately 1.33`() throws {
        let ratio = try #require(LMKCropAspectRatio.fourThree.ratio)
        #expect(abs(ratio - 4.0 / 3.0) < 0.001)
    }

    @Test
    func `3:2 ratio is 1.5`() throws {
        let ratio = try #require(LMKCropAspectRatio.threeTwo.ratio)
        #expect(abs(ratio - 1.5) < 0.001)
    }

    @Test
    func `2:3 ratio is approximately 0.67`() throws {
        let ratio = try #require(LMKCropAspectRatio.twoThree.ratio)
        #expect(abs(ratio - 2.0 / 3.0) < 0.001)
    }

    @Test
    func `3:4 ratio is 0.75`() throws {
        let ratio = try #require(LMKCropAspectRatio.threeFour.ratio)
        #expect(abs(ratio - 0.75) < 0.001)
    }

    @Test
    func `All aspect ratios are positive`() {
        for aspectRatio in LMKCropAspectRatio.allCases {
            if let ratio = aspectRatio.ratio {
                #expect(ratio > 0)
            }
        }
    }

    @Test
    func `Landscape ratios are greater than 1`() throws {
        #expect(try #require(LMKCropAspectRatio.fourThree.ratio) > 1.0)
        #expect(try #require(LMKCropAspectRatio.threeTwo.ratio) > 1.0)
    }

    @Test
    func `Portrait ratios are less than 1`() throws {
        #expect(try #require(LMKCropAspectRatio.twoThree.ratio) < 1.0)
        #expect(try #require(LMKCropAspectRatio.threeFour.ratio) < 1.0)
    }

    @Test
    func `Square ratio equals 1`() {
        #expect(LMKCropAspectRatio.square.ratio == 1.0)
    }

    @Test
    func `All cases are accounted for`() {
        let expectedCount = 6 // square, fourThree, threeTwo, twoThree, threeFour, free
        #expect(LMKCropAspectRatio.allCases.count == expectedCount)
    }
}
