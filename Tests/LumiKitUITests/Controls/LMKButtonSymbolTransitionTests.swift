//
//  LMKButtonSymbolTransitionTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKButtonSymbolTransitionTests {
    @Test
    func `Symbol swaps cross-fade on iOS 26 unless the style opts out`() {
        let button = LMKButton(style: .iconOnly())
        button.setSymbol("play.fill")
        #expect(button.image != nil)

        if #available(iOS 26, *) {
            if LMKAnimation.shouldAnimate {
                #expect(button.configuration?.symbolContentTransition != nil, "on by default")
            }
            button.style = LMKButton.Style(animatesSymbolChanges: false)
            #expect(button.configuration?.symbolContentTransition == nil)
        }

        let merged = LMKButton.Style(animatesSymbolChanges: false).merging(LMKButton.Style(symbolWeight: .bold))
        #expect(merged.animatesSymbolChanges == false)
        #expect(LMKButton.Style().merging(LMKButton.Style(animatesSymbolChanges: true)).animatesSymbolChanges == true)

        button.setSymbol("pause.fill", weight: .bold)
        #expect(button.image != nil, "the swap itself never depends on the transition")
    }
}
