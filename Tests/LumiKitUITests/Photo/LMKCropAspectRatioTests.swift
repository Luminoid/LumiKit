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
}
