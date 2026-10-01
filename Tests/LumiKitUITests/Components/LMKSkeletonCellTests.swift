//
//  LMKSkeletonCellTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKSkeletonView

@MainActor
struct LMKSkeletonViewTests {
    @Test
    func `Default shapes are three lines and each shape gets a view`() {
        let skeleton = LMKSkeletonView()
        #expect(skeleton.shapes == LMKSkeletonView.defaultShapes)
        #expect(skeleton.subviews.first?.subviews.count == 3)
        skeleton.shapes = [.circle(diameter: 40), .line()]
        #expect(skeleton.subviews.first?.subviews.count == 2)
    }

    @Test
    func `The default placeholder shows on the default backgrounds in both appearances`() {
        // `backgroundTertiary` resolved to white in light mode, so shapes vanished on a white page.
        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            let shape = LMKColor.fill.resolvedColor(with: traits)
            for background in [LMKColor.backgroundPrimary, LMKColor.backgroundSecondary] {
                #expect(shape.lmk_hexString != background.resolvedColor(with: traits).lmk_hexString, "\(style.rawValue)")
            }
        }
    }

    @Test
    func `Shapes take the theme's placeholder colors and corners`() {
        let skeleton = LMKSkeletonView(shapes: [.line(), .circle(diameter: 20), .rect(height: 60)])
        skeleton.frame = CGRect(x: 0, y: 0, width: 200, height: 120)
        skeleton.layoutIfNeeded()
        let views = skeleton.subviews.first?.subviews ?? []
        #expect(views.count == 3)
        #expect(views.allSatisfy { $0.backgroundColor === LMKColor.fill })
        #expect(views[0].lmk_cornerStyle == .fixed(LMKCornerRadius.xs))
        #expect(views[1].lmk_cornerStyle == .circle)
        #expect(views[0].bounds.height == 12)
        #expect(views[0].bounds.width == 200)
        #expect(views[1].bounds.size == CGSize(width: 20, height: 20))
        #expect(views[2].bounds.height == 60)
    }

    @Test
    func `Shimmer starts and stops`() {
        let skeleton = LMKSkeletonView()
        #expect(!skeleton.isShimmering)
        skeleton.startShimmer(staggerIndex: 2)
        #expect(skeleton.isShimmering)
        #expect(skeleton.hasShimmerAnimation == LMKAnimation.shouldAnimate)
        skeleton.stopShimmer()
        #expect(!skeleton.isShimmering)
        #expect(!skeleton.hasShimmerAnimation)
    }

    /// What Core Animation does to a layer that left the tree or an app that was backgrounded.
    private static func dropAnimations(of skeleton: LMKSkeletonView) {
        skeleton.layer.sublayers?.compactMap { $0 as? CAGradientLayer }.first?.removeAllAnimations()
    }

    @Test
    func `The shimmer comes back after re-entering a window and after the app returns to the foreground`() {
        let skeleton = LMKSkeletonView()
        skeleton.startShimmer()
        let window = LMKThemeTesting.host(skeleton)
        defer { window.isHidden = true }
        #expect(skeleton.hasShimmerAnimation == LMKAnimation.shouldAnimate)
        skeleton.removeFromSuperview()
        Self.dropAnimations(of: skeleton)
        #expect(!skeleton.hasShimmerAnimation)
        #expect(skeleton.isShimmering)
        window.addSubview(skeleton)
        #expect(skeleton.hasShimmerAnimation == LMKAnimation.shouldAnimate, "re-added on the way back in")

        Self.dropAnimations(of: skeleton)
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        #expect(skeleton.hasShimmerAnimation == LMKAnimation.shouldAnimate, "re-added when the app comes back")

        skeleton.stopShimmer()
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        #expect(!skeleton.hasShimmerAnimation, "a stopped shimmer stays stopped")

        let idle = LMKSkeletonView()
        window.addSubview(idle)
        #expect(!idle.hasShimmerAnimation, "a skeleton that never started does not start on its own")
    }

    @Test
    func `The shimmer mask covers the shapes once they are laid out`() throws {
        let skeleton = LMKSkeletonView(shapes: [.line(), .circle(diameter: 20)])
        let window = LMKThemeTesting.host(skeleton, size: CGSize(width: 300, height: 100))
        defer { window.isHidden = true }
        skeleton.frame = CGRect(x: 0, y: 0, width: 300, height: 100)
        skeleton.layoutIfNeeded()
        let path = try #require(skeleton.shimmerMaskPath)
        #expect(path.boundingBox.width == 300, "the full-width line spans the view")
        #expect(path.boundingBox.minY == 0)
        #expect(path.boundingBox.maxY == 12 + LMKSpacing.small + 20, "line, gap, circle")
    }

    @Test
    func `Shimmer colors follow dark mode`() {
        let skeleton = LMKSkeletonView(shapes: [.line()], style: LMKSkeletonView.Style(shapeColor: .lmk_dynamic(light: .red, dark: .blue)))
        let window = LMKThemeTesting.host(skeleton, style: .light)
        defer { window.isHidden = true }
        func firstHex() -> String? {
            (skeleton.layer.sublayers?.compactMap { $0 as? CAGradientLayer }.first?.colors?.first).map { UIColor(cgColor: $0 as! CGColor).lmk_hexString } // swiftlint:disable:this force_cast
        }
        #expect(firstHex() == UIColor.red.lmk_hexString)
        window.traitOverrides.userInterfaceStyle = .dark
        skeleton.updateTraitsIfNeeded()
        #expect(firstHex() == UIColor.blue.lmk_hexString)
    }

    @Test
    func `An explicit shape width yields to a narrower container`() {
        let skeleton = LMKSkeletonView(shapes: [.line(width: 200), .rect(width: 500, height: 40)])
        skeleton.frame = CGRect(x: 0, y: 0, width: 120, height: 100)
        skeleton.layoutIfNeeded()
        let views = skeleton.subviews.first?.subviews ?? []
        #expect(views[0].bounds.width == 120)
        #expect(views[1].bounds.width == 120)
        skeleton.frame = CGRect(x: 0, y: 0, width: 400, height: 100)
        skeleton.layoutIfNeeded()
        #expect(views[0].bounds.width == 200, "the wish holds once there is room")
    }

    @Test
    func `Accessibility announces loading`() {
        let skeleton = LMKSkeletonView()
        #expect(skeleton.isAccessibilityElement)
        #expect(skeleton.accessibilityTraits.contains(.updatesFrequently))
        #expect(skeleton.accessibilityLabel == LMKSkeletonView.Strings().loadingAccessibilityLabel)
        skeleton.strings = LMKSkeletonView.Strings(loadingAccessibilityLabel: "Cargando")
        #expect(skeleton.accessibilityLabel == "Cargando")
    }

    @Test
    func `Style overrides apply per instance and through the theme`() {
        let skeleton = LMKSkeletonView(shapes: [.line()], style: LMKSkeletonView.Style(shapeColor: .red, lineHeight: 20))
        skeleton.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
        skeleton.layoutIfNeeded()
        let line = skeleton.subviews.first?.subviews.first
        #expect(line?.backgroundColor == UIColor.red)
        #expect(line?.bounds.height == 20)

        var theme = LMKTheme()
        theme.skeleton = LMKSkeletonView.Style(shapeColor: .blue)
        let themed = LMKSkeletonView(shapes: [.line()])
        let window = LMKThemeTesting.host(themed, theme: theme)
        defer { window.isHidden = true }
        #expect(themed.subviews.first?.subviews.first?.backgroundColor == UIColor.blue)

        let timed = LMKSkeletonView(shapes: [.line()], style: LMKSkeletonView.Style(shimmerColor: .white, shimmerDuration: 3, staggerDelay: 0.5))
        let timedWindow = LMKThemeTesting.host(timed)
        defer { timedWindow.isHidden = true }
        timed.startShimmer(staggerIndex: 2)
        let gradient = timed.layer.sublayers?.compactMap { $0 as? CAGradientLayer }.first
        #expect((gradient?.colors?[1]).map { UIColor(cgColor: $0 as! CGColor) } == UIColor.white.resolvedColor(with: timed.traitCollection)) // swiftlint:disable:this force_cast
        if LMKAnimation.shouldAnimate {
            let animation = gradient?.animation(forKey: "shimmer")
            #expect(animation?.duration == 3)
            #expect((animation?.beginTime ?? 0) - CACurrentMediaTime() > 0.8, "two stagger steps of 0.5s")
        }
    }
}

// MARK: - LMKSkeletonCell

@MainActor
struct LMKSkeletonCellTests {
    @Test
    func `The cell hosts a skeleton on a card and shimmers while on screen`() {
        let cell = LMKSkeletonCell(style: .default, reuseIdentifier: "test")
        #expect(cell.skeletonView.superview === cell.containerView)
        #expect(cell.containerView.layer.cornerRadius == LMKCornerRadius.medium)
        #expect(cell.containerView.layer.shadowOpacity > 0)
        #expect(cell.skeletonView.shapes == [.rect(height: 80)])
        #expect(!cell.skeletonView.isShimmering)

        let window = LMKThemeTesting.host(cell)
        defer { window.isHidden = true }
        #expect(cell.skeletonView.isShimmering)
        cell.removeFromSuperview()
        #expect(!cell.skeletonView.isShimmering)
    }

    @Test
    func `prepareForReuse stops the shimmer and resets the stagger`() {
        let cell = LMKSkeletonCell(style: .default, reuseIdentifier: "test")
        cell.startShimmer(staggerIndex: 3)
        #expect(cell.staggerIndex == 3)
        cell.prepareForReuse()
        #expect(!cell.skeletonView.isShimmering)
        #expect(cell.staggerIndex == 0)
    }

    @Test
    func `Cell style sets the height, shapes, and card surface`() {
        let cell = LMKSkeletonCell(style: .default, reuseIdentifier: "test")
        cell.style = LMKSkeletonCell.Style(surface: LMKSurfaceStyle(shadow: LMKShadowSource.hidden), height: 60, shapes: [.circle(diameter: 30), .line()])
        #expect(cell.containerView.layer.shadowOpacity == 0)
        #expect(cell.skeletonView.shapes == [.circle(diameter: 30), .line()])
    }

    @Test
    func `A recycled cell that stays on screen keeps shimmering, and a placeholder takes no highlight`() {
        let cell = LMKSkeletonCell(style: .default, reuseIdentifier: "test")
        let window = LMKThemeTesting.host(cell)
        defer { window.isHidden = true }
        cell.startShimmer(staggerIndex: 4)
        cell.prepareForReuse()
        #expect(cell.staggerIndex == 0)
        #expect(cell.skeletonView.isShimmering, "still in the window, so still loading")

        let subviewsBefore = cell.containerView.subviews.count + cell.skeletonView.subviews.count
        let contentBackground = cell.contentView.backgroundColor
        cell.setHighlighted(true, animated: false)
        cell.setSelected(true, animated: false)
        #expect(cell.selectionStyle == .none)
        #expect(cell.containerView.subviews.count + cell.skeletonView.subviews.count == subviewsBefore, "no dark overlay on a loading placeholder")
        #expect(cell.contentView.backgroundColor == contentBackground)
    }

    @Test
    func `The card's height constraints sit below the table's encapsulated height`() {
        let cell = LMKSkeletonCell(style: .default, reuseIdentifier: "test")
        let vertical = cell.contentView.constraints.filter { ($0.firstItem === cell.containerView || $0.secondItem === cell.containerView) && [.bottom, .height].contains($0.firstAttribute) }
        #expect(!vertical.isEmpty)
        #expect(vertical.allSatisfy { $0.priority.rawValue < UILayoutPriority.required.rawValue })
        let ownHeight = cell.containerView.constraints.first { $0.firstAttribute == .height }
        #expect(ownHeight?.priority.rawValue == 999)
    }

    @Test
    func `lmk_startSkeletons and startShimmers are safe on empty or plain tables (no assertion beyond not crashing)`() {
        let tableView = UITableView()
        tableView.lmk_startSkeletons()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "plain")
        LMKSkeletonCell.startShimmers(in: tableView)
    }
}
