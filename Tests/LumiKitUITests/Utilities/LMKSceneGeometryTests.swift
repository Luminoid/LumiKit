//
//  LMKSceneGeometryTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKSceneGeometryTests {
    private func makeWindow(width: CGFloat = 390, height: CGFloat = 844) -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: height))
        window.rootViewController = UIViewController()
        window.isHidden = false
        window.layoutIfNeeded()
        return window
    }

    @Test
    func `geometry(of:) reads the window's size, tier, and orientation`() {
        let window = makeWindow()
        let geometry = LMKScene.geometry(of: window)
        #expect(geometry.size == CGSize(width: 390, height: 844))
        #expect(geometry.screenSize == LMKDevice.screenSize(for: window))
        #expect(!geometry.isInteractivelyResizing, "never resizing without a scene")
        #expect(geometry.interfaceOrientation == .unknown, "no scene in the test host")
    }

    @Test
    func `observeGeometry reports once at install and again when the window resizes`() {
        let window = makeWindow()
        var reports: [LMKScene.Geometry] = []
        let observation = LMKScene.observeGeometry(of: window) { reports.append($0) }
        defer { observation.cancel() }

        #expect(reports.count == 1)
        #expect(reports.first?.size == CGSize(width: 390, height: 844))
        #expect(observation.geometry == reports.first)
        #expect(observation.window === window)

        window.frame = CGRect(x: 0, y: 0, width: 800, height: 600)
        window.layoutIfNeeded()
        #expect(reports.count == 2)
        #expect(reports.last?.size == CGSize(width: 800, height: 600))

        // The same size again is not a change.
        window.setNeedsLayout()
        window.layoutIfNeeded()
        #expect(reports.count == 2)
    }

    @Test
    func `cancel detaches the sentinel and stops the callbacks`() {
        let window = makeWindow()
        let subviewsBefore = window.subviews.count
        var reports = 0
        let observation = LMKScene.observeGeometry(of: window) { _ in reports += 1 }
        #expect(window.subviews.count == subviewsBefore + 1)

        observation.cancel()
        #expect(window.subviews.count == subviewsBefore)
        #expect(observation.window == nil)
        window.frame = CGRect(x: 0, y: 0, width: 700, height: 500)
        window.layoutIfNeeded()
        #expect(reports == 1, "only the install report")
    }

    @Test
    func `The sentinel is invisible, non-interactive, and hidden from accessibility`() throws {
        let window = makeWindow()
        let observation = LMKScene.observeGeometry(of: window) { _ in }
        defer { observation.cancel() }
        let sentinel = try #require(window.subviews.first)
        #expect(sentinel.alpha == 0)
        #expect(!sentinel.isUserInteractionEnabled)
        #expect(sentinel.accessibilityElementsHidden)
        #expect(sentinel.frame == window.bounds)
    }

    @Test
    func `observeScreenSize fires only when the tier changes`() {
        let window = makeWindow(width: 390, height: 844)
        var tiers: [LMKDevice.ScreenSize] = []
        let observation = LMKDevice.observeScreenSize(of: window) { tiers.append($0) }
        defer { observation.cancel() }
        #expect(tiers == [.regular])

        // Rotation keeps the portrait width, so the tier holds.
        window.frame = CGRect(x: 0, y: 0, width: 844, height: 390)
        window.layoutIfNeeded()
        #expect(tiers == [.regular])

        // A narrower window drops a tier.
        window.frame = CGRect(x: 0, y: 0, width: 320, height: 568)
        window.layoutIfNeeded()
        #expect(tiers == [.regular, .compact])
    }
}
