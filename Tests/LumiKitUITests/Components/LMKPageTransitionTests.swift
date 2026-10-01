//
//  LMKPageTransitionTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKPageTransitionTests {
    @Test
    func `Without a window the swap is immediate and the completion runs once`() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
        let first = UIView()
        let second = UIView()
        var completions = 0
        LMKPageTransition.run(in: container, from: nil, to: first, direction: .forward, duration: 0.3, animated: true) { completions += 1 }
        #expect(first.superview === container)
        #expect(completions == 1)
        LMKPageTransition.run(in: container, from: first, to: second, direction: .forward, duration: 0.3, animated: true) { completions += 1 }
        #expect(first.superview == nil)
        #expect(second.superview === container)
        #expect(completions == 2)
        container.layoutIfNeeded()
        #expect(second.frame == container.bounds)
    }

    @Test
    func `An animated slide restores the outgoing view, so a page kept on a stack can come back`() async {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
        window.addSubview(container)
        window.isHidden = false
        defer { window.isHidden = true }
        let first = UIView()
        let second = UIView()
        first.alpha = 0.5
        LMKPageTransition.run(in: container, from: nil, to: second, direction: .none, duration: 0.2, animated: false)
        container.layoutIfNeeded()
        #expect(second.alpha == 1)

        var completions = 0
        LMKPageTransition.run(in: container, from: second, to: first, direction: .forward, duration: 0.2, animated: true) { completions += 1 }
        #expect(first.alpha == 1, "the incoming view starts opaque whatever it was before")
        await LMKWait.until { completions == 1 }
        #expect(completions == 1)
        #expect(second.superview == nil)
        #expect(second.alpha == 1, "the outgoing view leaves as it came")
        #expect(second.transform == .identity)
        #expect(!second.translatesAutoresizingMaskIntoConstraints, "SnapKit had switched the translation off; it stays off")
        #expect(first.transform == .identity)

        // Back: the view that slid out slides in again, visible.
        LMKPageTransition.run(in: container, from: first, to: second, direction: .backward, duration: 0.2, animated: true) { completions += 1 }
        #expect(second.superview === container)
        #expect(second.alpha == 1)
        await LMKWait.until { completions == 2 }
        #expect(first.superview == nil)
        #expect(first.alpha == 1)
        container.layoutIfNeeded()
        #expect(second.frame == container.bounds)
    }
}
