//
//  LMKCropAspectRatioTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - LMKCropAspectRatio

@Suite("LMKCropAspectRatio")
struct CropAspectRatioTests {
    @Test("Square ratio is 1.0")
    func squareRatio() {
        #expect(LMKCropAspectRatio.square.ratio == 1.0)
    }

    @Test("Free ratio is nil")
    func freeRatio() {
        #expect(LMKCropAspectRatio.free.ratio == nil)
    }

    @Test("All cases have display names")
    func allCasesHaveDisplayNames() {
        for ratio in LMKCropAspectRatio.allCases {
            #expect(!ratio.displayName.isEmpty)
        }
    }

    @Test("4:3 ratio is approximately 1.33")
    func fourThreeRatio() {
        let ratio = LMKCropAspectRatio.fourThree.ratio!
        #expect(abs(ratio - 4.0 / 3.0) < 0.001)
    }

    @Test("3:2 ratio is 1.5")
    func threeTwoRatio() {
        let ratio = LMKCropAspectRatio.threeTwo.ratio!
        #expect(abs(ratio - 1.5) < 0.001)
    }

    @Test("2:3 ratio is approximately 0.67")
    func twoThreeRatio() {
        let ratio = LMKCropAspectRatio.twoThree.ratio!
        #expect(abs(ratio - 2.0 / 3.0) < 0.001)
    }

    @Test("3:4 ratio is 0.75")
    func threeFourRatio() {
        let ratio = LMKCropAspectRatio.threeFour.ratio!
        #expect(abs(ratio - 0.75) < 0.001)
    }

    @Test("All aspect ratios are positive")
    func allRatiosPositive() {
        for aspectRatio in LMKCropAspectRatio.allCases {
            if let ratio = aspectRatio.ratio {
                #expect(ratio > 0)
            }
        }
    }

    @Test("Landscape ratios are greater than 1")
    func landscapeRatios() {
        #expect(LMKCropAspectRatio.fourThree.ratio! > 1.0)
        #expect(LMKCropAspectRatio.threeTwo.ratio! > 1.0)
    }

    @Test("Portrait ratios are less than 1")
    func portraitRatios() {
        #expect(LMKCropAspectRatio.twoThree.ratio! < 1.0)
        #expect(LMKCropAspectRatio.threeFour.ratio! < 1.0)
    }

    @Test("Square ratio equals 1")
    func squareRatioEqualsOne() {
        #expect(LMKCropAspectRatio.square.ratio == 1.0)
    }

    @Test("All cases are accounted for")
    func allCasesCoverage() {
        let expectedCount = 6 // square, fourThree, threeTwo, twoThree, threeFour, free
        #expect(LMKCropAspectRatio.allCases.count == expectedCount)
    }
}
