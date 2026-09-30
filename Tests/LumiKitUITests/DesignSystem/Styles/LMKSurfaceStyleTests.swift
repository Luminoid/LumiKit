//
//  LMKSurfaceStyleTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - Value types

struct LMKSurfaceStyleTests {
    @Test
    func `merging lets the other style's non-nil fields win`() {
        let base = LMKSurfaceStyle(background: .solid(.red), corners: .capsule, border: .solid(.blue), shadow: .level(.level2), contentInsets: .lmk_all(4))
        let override = LMKSurfaceStyle(corners: .fixed(8), shadow: LMKShadowSource.none)
        let merged = base.merging(override)
        #expect(merged.background == .solid(.red))
        #expect(merged.corners == .fixed(8))
        #expect(merged.border == .solid(.blue))
        #expect(merged.shadow == LMKShadowSource.none)
        #expect(merged.contentInsets == .lmk_all(4))
    }

    @Test
    func `A solid nil background keeps the base solid color`() {
        let base = LMKSurfaceStyle(background: .solid(.red))
        #expect(base.merging(LMKSurfaceStyle(background: .solid(nil))).background == .solid(.red))
        #expect(base.merging(LMKSurfaceStyle(background: .clear)).background == .clear)
        #expect(LMKSurfaceStyle(background: .clear).merging(LMKSurfaceStyle(background: .solid(nil))).background == .solid(nil))
    }

    @Test
    func `Border presets`() {
        #expect(LMKBorderStyle.solid(.red, width: 2) == LMKBorderStyle(color: .red, width: 2))
        #expect(LMKBorderStyle.dashed([4, 2]).dash == [4, 2])
        #expect(LMKBorderStyle.dashed([4, 2]).needsShapeLayer)
        #expect(LMKBorderStyle(inset: 3).needsShapeLayer)
        #expect(!LMKBorderStyle.solid().needsShapeLayer)
        #expect(LMKBorderStyle.none.width == 0)
        #expect(LMKBorderStyle(inset: -5).inset == 0)
    }

    @Test
    func `Shadow sources know whether they draw`() {
        #expect(!LMKShadowSource.none.isVisible)
        #expect(!LMKShadowSource.level(.none).isVisible)
        #expect(LMKShadowSource.level(.level1).isVisible)
        #expect(!LMKShadowSource.custom(LMKShadowStyle(color: .black, offset: .zero, radius: 4, opacity: 0)).isVisible)
        #expect(LMKShadowSource.custom(LMKShadowStyle(color: .black, offset: .zero, radius: 4, opacity: 0.3)).isVisible)
    }

    @Test
    func `Control state styles merge and clamp`() {
        let base = LMKControlStateStyle(background: .clear, alpha: 0.5, scale: 0.9)
        let other = LMKControlStateStyle(foregroundColor: .red, alpha: 2, scale: -1)
        let merged = base.merging(other)
        #expect(merged.background == .clear)
        #expect(merged.foregroundColor == UIColor.red)
        #expect(merged.alpha == 1)
        #expect(merged.scale == 0)
        #expect(LMKControlStateStyle.merge(nil, nil) == nil)
        #expect(LMKControlStateStyle.merge(base, nil) == base)
        #expect(LMKControlStateStyle.merge(nil, other) == other)
    }

    @Test
    func `Inset helpers`() {
        #expect(NSDirectionalEdgeInsets.lmk_all(3) == NSDirectionalEdgeInsets(top: 3, leading: 3, bottom: 3, trailing: 3))
        #expect(NSDirectionalEdgeInsets.lmk_symmetric(vertical: 1, horizontal: 2) == NSDirectionalEdgeInsets(top: 1, leading: 2, bottom: 1, trailing: 2))
    }
}

// MARK: - UIView.lmk_apply(surface:)

@MainActor
struct UIViewSurfaceTests {
    @Test
    func `Solid surface sets color, corners, shadow, and border`() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        let resolved = view.lmk_apply(
            surface: LMKSurfaceStyle(background: .solid(.red), corners: .fixed(6), border: .solid(.blue, width: 2), shadow: .level(.level2), contentInsets: .lmk_all(5)),
            defaults: LMKSurfaceStyle(background: .solid(.green), corners: .capsule)
        )
        #expect(view.backgroundColor == UIColor.red)
        #expect(view.layer.cornerRadius == 6)
        #expect(view.layer.masksToBounds == false, "a shadow disables masking")
        #expect(view.layer.shadowOpacity > 0)
        #expect(view.layer.borderWidth == 2)
        #expect(resolved.contentInsets == .lmk_all(5))
        #expect(view.lmk_resolvedSurface == resolved)
        #expect(view.lmk_surfaceBackgroundView == nil)
    }

    @Test
    func `Defaults fill the fields the surface leaves nil`() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        view.lmk_apply(surface: LMKSurfaceStyle(background: .solid(nil)), defaults: LMKSurfaceStyle(background: .solid(.green), corners: .fixed(9)))
        #expect(view.backgroundColor == UIColor.green)
        #expect(view.layer.cornerRadius == 9)
        #expect(view.layer.masksToBounds, "no shadow keeps masking on")
    }

    @Test
    func `Gradient, blur, and glass backgrounds insert a background view`() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        view.lmk_apply(surface: LMKSurfaceStyle(background: .gradient(colors: [.red, .blue], direction: .leftToRight), corners: .fixed(4)))
        #expect(view.lmk_surfaceBackgroundView is LMKGradientView)
        #expect(view.subviews.first === view.lmk_surfaceBackgroundView)
        #expect(view.backgroundColor == UIColor.clear)

        view.lmk_apply(surface: LMKSurfaceStyle(background: .blur(.systemMaterial)))
        #expect(view.lmk_surfaceBackgroundView is UIVisualEffectView)
        #expect(!(view.lmk_surfaceBackgroundView is LMKGlassView))

        view.lmk_apply(surface: LMKSurfaceStyle(background: .glass(.regular, tint: .red), corners: .fixed(12)))
        #expect((view.lmk_surfaceBackgroundView as? LMKGlassView)?.cornerRadius == 12)

        view.lmk_apply(surface: LMKSurfaceStyle(background: .solid(.red)))
        #expect(view.lmk_surfaceBackgroundView == nil)
        #expect(view.subviews.isEmpty)
    }

    @Test
    func `A non-solid background with a shadow gets a shadow path`() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        view.lmk_apply(surface: LMKSurfaceStyle(background: .blur(.systemMaterial), corners: .fixed(8), shadow: .level(.level3)))
        #expect(view.layer.shadowPath != nil)
        view.lmk_apply(surface: LMKSurfaceStyle(background: .solid(.red), corners: .fixed(8), shadow: .level(.level3)))
        #expect(view.layer.shadowPath == nil)
    }

    @Test
    func `Dashed and inset borders stroke a shape layer that follows the bounds`() throws {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        view.lmk_apply(surface: LMKSurfaceStyle(corners: .fixed(8), border: .dashed([4, 2], color: .red, width: 2)))
        #expect(view.layer.borderWidth == 0)
        let shape = try #require(view.layer.sublayers?.compactMap { $0 as? CAShapeLayer }.first)
        #expect(shape.lineDashPattern == [4, 2])
        #expect(shape.lineWidth == 2)
        #expect(shape.path != nil)
        let before = shape.path?.boundingBox

        view.frame = CGRect(x: 0, y: 0, width: 200, height: 40)
        view.lmk_layoutSurfaceIfNeeded()
        #expect(shape.path?.boundingBox != before)

        view.lmk_apply(surface: LMKSurfaceStyle(border: .solid(.red, width: 1)))
        #expect(view.layer.sublayers?.contains { $0 is CAShapeLayer } != true)
        #expect(view.layer.borderWidth == 1)
    }

    @Test
    func `An explicit no-border override removes a default border`() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        view.lmk_apply(surface: LMKSurfaceStyle(border: LMKBorderStyle.none), defaults: LMKSurfaceStyle(border: .solid(.red, width: 2)))
        #expect(view.layer.borderWidth == 0)
    }

    @Test
    func `Capsule surfaces track the bounds through lmk_layoutSurfaceIfNeeded`() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 40))
        view.lmk_apply(surface: LMKSurfaceStyle(background: .solid(.red), corners: .capsule))
        #expect(view.layer.cornerRadius == 20)
        view.frame = CGRect(x: 0, y: 0, width: 100, height: 60)
        view.lmk_layoutSurfaceIfNeeded()
        #expect(view.layer.cornerRadius == 30)
    }
}
