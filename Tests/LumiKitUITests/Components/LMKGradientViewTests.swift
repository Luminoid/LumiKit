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
    func `Named directions set start and end points`() throws {
        let gradient = LMKGradientView(colors: [.red, .blue], direction: .leftToRight)
        let gradientLayer = try #require(gradient.layer as? CAGradientLayer)
        #expect(gradientLayer.startPoint == CGPoint(x: 0, y: 0.5))
        #expect(gradientLayer.endPoint == CGPoint(x: 1, y: 0.5))
        gradient.direction = .topToBottom
        #expect(gradientLayer.startPoint == CGPoint(x: 0.5, y: 0))
        #expect(LMKGradientView.Direction.named.count == 4)
    }

    @Test
    func `Angle and custom directions`() {
        let down = LMKGradientView.Direction.angle(0)
        #expect(abs(down.startPoint.y - 0) < 0.001)
        #expect(abs(down.endPoint.y - 1) < 0.001)
        let right = LMKGradientView.Direction.angle(90)
        #expect(abs(right.startPoint.x - 0) < 0.001)
        #expect(abs(right.endPoint.x - 1) < 0.001)
        let custom = LMKGradientView.Direction.custom(start: CGPoint(x: 0.1, y: 0.2), end: CGPoint(x: 0.9, y: 0.8))
        #expect(custom.startPoint == CGPoint(x: 0.1, y: 0.2))
        #expect(custom.endPoint == CGPoint(x: 0.9, y: 0.8))
    }

    @Test
    func `Radial kind switches the layer type`() throws {
        let gradient = LMKGradientView(colors: [.white, .clear], kind: .radial)
        let gradientLayer = try #require(gradient.layer as? CAGradientLayer)
        #expect(gradientLayer.type == .radial)
        #expect(gradientLayer.startPoint == CGPoint(x: 0.5, y: 0.5))
        gradient.kind = .linear
        #expect(gradientLayer.type == .axial)
    }

    @Test
    func `Colors are resolved and re-stamped on dark mode`() throws {
        let gradient = LMKGradientView(colors: [.lmk_dynamic(light: .red, dark: .blue), .black])
        let gradientLayer = try #require(gradient.layer as? CAGradientLayer)
        #expect(gradientLayer.colors?.count == 2)
        let window = LMKThemeTesting.host(gradient, style: .light)
        defer { window.isHidden = true }
        func firstHex() -> String? {
            (gradientLayer.colors?.first).map { UIColor(cgColor: $0 as! CGColor).lmk_hexString } // swiftlint:disable:this force_cast
        }
        #expect(firstHex() == UIColor.red.lmk_hexString)
        window.traitOverrides.userInterfaceStyle = .dark
        gradient.updateTraitsIfNeeded()
        #expect(firstHex() == UIColor.blue.lmk_hexString)
    }
}
