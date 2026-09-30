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
    func `Shapes take the theme's placeholder colors and corners`() {
        let skeleton = LMKSkeletonView(shapes: [.line(), .circle(diameter: 20), .rect(height: 60)])
        skeleton.frame = CGRect(x: 0, y: 0, width: 200, height: 120)
        skeleton.layoutIfNeeded()
        let views = skeleton.subviews.first?.subviews ?? []
        #expect(views.count == 3)
        #expect(views.allSatisfy { $0.backgroundColor === LMKColor.backgroundTertiary })
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
        skeleton.stopShimmer()
        #expect(!skeleton.isShimmering)
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
        cell.style = LMKSkeletonCell.Style(surface: LMKSurfaceStyle(shadow: LMKShadowSource.none), height: 60, shapes: [.circle(diameter: 30), .line()])
        #expect(cell.containerView.layer.shadowOpacity == 0)
        #expect(cell.skeletonView.shapes == [.circle(diameter: 30), .line()])
    }

    @Test
    func `lmk_startSkeletons and startShimmers do not crash on empty or plain tables`() {
        let tableView = UITableView()
        tableView.lmk_startSkeletons()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "plain")
        LMKSkeletonCell.startShimmers(in: tableView)
    }
}
