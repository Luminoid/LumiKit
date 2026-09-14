//
//  LMKGlassViewTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKGlassView

@MainActor
struct LMKGlassViewTests {
    @Test
    func `isGlass tracks iOS 26 availability`() {
        let view = LMKGlassView()
        if #available(iOS 26, *) {
            #expect(view.isGlass)
            #expect(view.effect is UIGlassEffect)
        } else {
            #expect(!view.isGlass)
            #expect(view.effect is UIBlurEffect)
        }
    }

    @Test
    func `clear style, tint, and interactivity reach the effect`() {
        let view = LMKGlassView(style: .clear, tintColor: .red, isInteractive: true)
        if #available(iOS 26, *) {
            let glass = view.effect as? UIGlassEffect
            #expect(glass?.tintColor == .red)
            #expect(glass?.isInteractive == true)
        } else {
            // Blur fallback carries the tint as a translucent content background.
            #expect(view.contentView.backgroundColor != nil)
        }
    }

    @Test
    func `fixed corner radius applies through the version-appropriate path`() {
        let view = LMKGlassView(cornerRadius: 12)
        #expect(!view.usesConcentricCorners)
        if #available(iOS 26, *) {
            #expect(view.cornerConfiguration == .corners(radius: .fixed(12)))
            view.cornerRadius = 20
            #expect(view.cornerConfiguration == .corners(radius: .fixed(20)))
        } else {
            #expect(view.layer.cornerRadius == 12)
            #expect(view.clipsToBounds)
            view.cornerRadius = 20
            #expect(view.layer.cornerRadius == 20)
        }
    }

    @Test
    func `concentric corners use the radius as the floor on iOS 26`() {
        let view = LMKGlassView(cornerRadius: 10, usesConcentricCorners: true)
        #expect(view.usesConcentricCorners)
        if #available(iOS 26, *) {
            #expect(view.cornerConfiguration == .corners(radius: .containerConcentric(minimum: 10)))
            view.usesConcentricCorners = false
            #expect(view.cornerConfiguration == .corners(radius: .fixed(10)))
        } else {
            #expect(view.layer.cornerRadius == 10)
        }
    }

    @Test
    func `makeContainer hosts glass views in its contentView`() {
        let container = LMKGlassView.makeContainer(spacing: 12)
        let glass = LMKGlassView()
        container.contentView.addSubview(glass)
        #expect(glass.superview === container.contentView)
        if #available(iOS 26, *) {
            #expect((container.effect as? UIGlassContainerEffect)?.spacing == 12)
        } else {
            #expect(container.effect == nil)
        }
    }
}
