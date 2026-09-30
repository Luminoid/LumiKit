//
//  UIViewLayoutDirectionTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct UIViewLayoutDirectionTests {
    @Test
    func `Forcing a direction sets the semantic attribute and the iOS 26 alignment trait`() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let label = UILabel()
        window.addSubview(label)

        #expect(window.lmk_forcedLayoutDirection == nil)
        window.lmk_forceLayoutDirection(.rightToLeft)
        #expect(window.semanticContentAttribute == .forceRightToLeft)
        #expect(window.lmk_forcedLayoutDirection == .rightToLeft)
        #expect(window.effectiveUserInterfaceLayoutDirection == .rightToLeft)
        #expect(label.semanticContentAttribute == .unspecified, "descendants inherit through the window's trait, they are not stamped")
        if #available(iOS 26, *) {
            #expect(window.traitOverrides.contains(UITraitResolvesNaturalAlignmentWithBaseWritingDirection.self))
            window.updateTraitsIfNeeded()
            #expect(window.traitCollection.resolvesNaturalAlignmentWithBaseWritingDirection)
        }

        window.lmk_forceLayoutDirection(.leftToRight)
        #expect(window.semanticContentAttribute == .forceLeftToRight)
        #expect(window.lmk_forcedLayoutDirection == .leftToRight)

        window.lmk_forceLayoutDirection(nil)
        #expect(window.semanticContentAttribute == .unspecified)
        #expect(window.lmk_forcedLayoutDirection == nil)
        if #available(iOS 26, *) {
            #expect(!window.traitOverrides.contains(UITraitResolvesNaturalAlignmentWithBaseWritingDirection.self))
        }
    }
}
