//
//  LMKGradientViewTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKGradientView

@Suite("LMKGradientView")
@MainActor
struct LMKGradientViewTests {
    @Test("Layer class is CAGradientLayer")
    func layerClass() {
        let gradient = LMKGradientView(colors: [.red, .blue])
        #expect(gradient.layer is CAGradientLayer)
    }

    @Test("Direction sets start/end points")
    func directionPoints() throws {
        let gradient = LMKGradientView(colors: [.red, .blue], direction: .leftToRight)
        let gradientLayer = try #require(gradient.layer as? CAGradientLayer)
        #expect(gradientLayer.startPoint == CGPoint(x: 0, y: 0.5))
        #expect(gradientLayer.endPoint == CGPoint(x: 1, y: 0.5))
    }

    @Test("Colors are applied to gradient layer")
    func colorsApplied() throws {
        let gradient = LMKGradientView(colors: [.red, .blue])
        let gradientLayer = try #require(gradient.layer as? CAGradientLayer)
        #expect(gradientLayer.colors?.count == 2)
    }
}
