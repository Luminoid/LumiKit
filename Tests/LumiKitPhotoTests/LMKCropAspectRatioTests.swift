//
//  LMKCropAspectRatioTests.swift
//  LumiKit
//

import LumiKitUI
import Testing
import UIKit
@testable import LumiKitPhoto

// MARK: - LMKCropAspectRatio

struct CropAspectRatioTests {
    @Test
    func `Square is 1 and free is nil`() {
        #expect(LMKCropAspectRatio.square.ratio == 1.0)
        #expect(LMKCropAspectRatio.free.ratio == nil)
    }

    @Test
    func `All cases have display names`() {
        for ratio in LMKCropAspectRatio.allCases {
            #expect(!ratio.displayName.isEmpty)
        }
        #expect(LMKCropAspectRatio.sixteenNine.displayName == "16:9")
        #expect(LMKCropAspectRatio.free.displayName == LMKPhotoCropViewController.strings.free)
    }

    @Test
    func `Numeric ratios`() throws {
        #expect(try abs(#require(LMKCropAspectRatio.fourThree.ratio) - 4.0 / 3.0) < 0.001)
        #expect(try abs(#require(LMKCropAspectRatio.threeTwo.ratio) - 1.5) < 0.001)
        #expect(try abs(#require(LMKCropAspectRatio.sixteenNine.ratio) - 16.0 / 9.0) < 0.001)
        #expect(try abs(#require(LMKCropAspectRatio.twoThree.ratio) - 2.0 / 3.0) < 0.001)
        #expect(try abs(#require(LMKCropAspectRatio.threeFour.ratio) - 0.75) < 0.001)
        #expect(try abs(#require(LMKCropAspectRatio.nineSixteen.ratio) - 9.0 / 16.0) < 0.001)
    }

    @Test
    func `Landscape ratios exceed 1 and portrait ratios stay below`() throws {
        for ratio in [LMKCropAspectRatio.fourThree, .threeTwo, .sixteenNine] {
            #expect(try #require(ratio.ratio) > 1.0)
        }
        for ratio in [LMKCropAspectRatio.twoThree, .threeFour, .nineSixteen] {
            #expect(try #require(ratio.ratio) < 1.0)
        }
        for ratio in LMKCropAspectRatio.allCases {
            if let value = ratio.ratio {
                #expect(value > 0)
            }
        }
    }

    @Test
    func `Eight cases, six of them standard`() {
        #expect(LMKCropAspectRatio.allCases.count == 8)
        #expect(LMKCropAspectRatio.standard.count == 6)
        #expect(LMKCropAspectRatio.standard.first == .square)
        #expect(LMKCropAspectRatio.standard.last == .free)
        #expect(!LMKCropAspectRatio.standard.contains(.sixteenNine))
    }
}
