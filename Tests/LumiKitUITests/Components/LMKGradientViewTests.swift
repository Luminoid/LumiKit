//
//  LMKGradientViewTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKGradientView

@MainActor
struct LMKGradientViewTests {
    @Test
    func `Layer class is CAGradientLayer`() {
        let gradient = LMKGradientView(colors: [.red, .blue])
        #expect(gradient.layer is CAGradientLayer)
    }

    @Test
    func `Direction sets start/end points`() throws {
        let gradient = LMKGradientView(colors: [.red, .blue], direction: .leftToRight)
        let gradientLayer = try #require(gradient.layer as? CAGradientLayer)
        #expect(gradientLayer.startPoint == CGPoint(x: 0, y: 0.5))
        #expect(gradientLayer.endPoint == CGPoint(x: 1, y: 0.5))
    }

    @Test
    func `Colors are applied to gradient layer`() throws {
        let gradient = LMKGradientView(colors: [.red, .blue])
        let gradientLayer = try #require(gradient.layer as? CAGradientLayer)
        #expect(gradientLayer.colors?.count == 2)
    }
}
