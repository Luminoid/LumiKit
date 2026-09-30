//
//  LMKAnimationTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKAnimation

@MainActor
struct LMKAnimationTests {
    @Test
    func `Duration values are positive`() {
        #expect(LMKAnimation.Duration.slow > 0)
        #expect(LMKAnimation.Duration.moderate > 0)
        #expect(LMKAnimation.Duration.instant > 0)
        #expect(LMKAnimation.Duration.slow > 0)
        #expect(LMKAnimation.Duration.fast > 0)
    }

    @Test
    func `Spring damping is in valid range`() {
        let damping = LMKAnimation.spring.damping
        #expect(damping > 0 && damping <= 1)
    }

    @Test
    func `tableViewRowAnimation returns valid value`() {
        let animation = LMKAnimation.tableViewRowAnimation
        // Should be either .automatic or .none depending on Reduce Motion
        #expect(animation == .automatic || animation == .none)
    }

    // MARK: - Additional Duration Tests

    @Test
    func `All duration values are positive`() {
        #expect(LMKAnimation.Duration.slow > 0)
        #expect(LMKAnimation.Duration.moderate > 0)
        #expect(LMKAnimation.Duration.normal > 0)
        #expect(LMKAnimation.Duration.normal > 0)
        #expect(LMKAnimation.Duration.fast > 0)
        #expect(LMKAnimation.Duration.instant > 0)
        #expect(LMKAnimation.Duration.emphasis > 0)
        #expect(LMKAnimation.Duration.slow > 0)
        #expect(LMKAnimation.Duration.fast > 0)
        #expect(LMKAnimation.Duration.moderate > 0)
        #expect(LMKAnimation.Duration.moderate > 0)
        #expect(LMKAnimation.Duration.moderate > 0)
    }

    @Test
    func `Duration values are reasonable (< 2 seconds)`() {
        // Animations should be quick (< 2 seconds)
        #expect(LMKAnimation.Duration.slow < 2.0)
        #expect(LMKAnimation.Duration.moderate < 2.0)
        #expect(LMKAnimation.Duration.instant < 2.0)
        #expect(LMKAnimation.Duration.slow < 2.0)
    }

    // MARK: - Curve Tests

    @Test
    func `Animation curves are defined`() {
        _ = LMKAnimation.Curve.easeInOut.options
        _ = LMKAnimation.Curve.easeOut.options
        _ = LMKAnimation.Curve.easeIn.options
        // Test passes if no crashes occur
    }

    // MARK: - Button Press Animation Tests

    @Test
    func `animateButtonPressDown respects shouldAnimate`() {
        let button = UIButton()
        button.frame = CGRect(x: 0, y: 0, width: 100, height: 44)

        LMKAnimation.animateButtonPressDown(button)
        // Test completes without crashing
    }

    @Test
    func `animateButtonPressUp calls completion`() {
        let button = UIButton()
        button.frame = CGRect(x: 0, y: 0, width: 100, height: 44)

        var completionCalled = false
        LMKAnimation.animateButtonPressUp(button) {
            completionCalled = true
        }

        // With Reduce Motion or instant animations, completion should be called immediately
        if !LMKAnimation.shouldAnimate {
            #expect(completionCalled)
        }
    }

    @Test
    func `animateButtonPress works without completion`() {
        let button = UIButton()
        button.frame = CGRect(x: 0, y: 0, width: 100, height: 44)

        LMKAnimation.animateButtonPress(button)
        // Test completes without crashing
    }

    @Test
    func `Press animation accepts plain UIControl`() {
        let control = UIControl(frame: CGRect(x: 0, y: 0, width: 100, height: 44))

        LMKAnimation.animateButtonPressDown(control)
        LMKAnimation.animateButtonPressUp(control)
        LMKAnimation.animateButtonPress(control)
        // Test completes without crashing
    }

    // MARK: - Success Feedback Tests

    @Test
    func `animateSuccessFeedback adds checkmark view`() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))

        LMKAnimation.animateSuccessFeedback(on: view)

        // Checkmark should be added as a subview
        #expect(!view.subviews.isEmpty)
    }

    @Test
    func `animateSuccessFeedback removes duplicate checkmarks`() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))

        // Add success feedback twice
        LMKAnimation.animateSuccessFeedback(on: view)
        let firstCount = view.subviews.count

        LMKAnimation.animateSuccessFeedback(on: view)
        let secondCount = view.subviews.count

        // Should still have the same number of subviews (old checkmark removed)
        #expect(firstCount == secondCount)
    }

    // MARK: - Error Shake Tests

    @Test
    func `animateErrorShake completes without crashing`() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 44))

        var completionCalled = false
        LMKAnimation.animateErrorShake(on: view) {
            completionCalled = true
        }

        // With Reduce Motion, completion should be called
        if !LMKAnimation.shouldAnimate {
            #expect(completionCalled)
        }
    }

    // MARK: - Photo Load Tests

    @Test
    func `animatePhotoLoad completes without crashing`() {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        imageView.alpha = 1.0

        LMKAnimation.animatePhotoLoad(on: imageView)

        // Test completes successfully (alpha will be 0 or 1 depending on Reduce Motion)
    }

    // MARK: - Fade Tests

    @Test
    func `fadeIn completes without crashing`() {
        let view = UIView()
        view.alpha = 1.0

        LMKAnimation.fadeIn(view)

        // Test completes successfully (alpha will be 0 or 1 depending on Reduce Motion and timing)
    }

    @Test
    func `fadeOut with completion`() {
        let view = UIView()
        view.alpha = 1.0

        var completionCalled = false
        LMKAnimation.fadeOut(view) {
            completionCalled = true
        }

        if !LMKAnimation.shouldAnimate {
            #expect(completionCalled)
        }
    }

    // MARK: - List Update Tests

    @Test
    func `animateListUpdate calls animations block`() {
        var animationsCalled = false

        LMKAnimation.animateListUpdate(animations: {
            animationsCalled = true
        })

        #expect(animationsCalled)
    }
}
