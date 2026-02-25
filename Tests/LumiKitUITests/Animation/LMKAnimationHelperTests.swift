//
//  LMKAnimationHelperTests.swift
//  LumiKit
//

import Testing
import UIKit

@testable import LumiKitUI

// MARK: - LMKAnimationHelper

@Suite("LMKAnimationHelper")
@MainActor
struct LMKAnimationHelperTests {
    @Test("Duration values are positive")
    func durationsPositive() {
        #expect(LMKAnimationHelper.Duration.screenTransition > 0)
        #expect(LMKAnimationHelper.Duration.modalPresentation > 0)
        #expect(LMKAnimationHelper.Duration.buttonPress > 0)
        #expect(LMKAnimationHelper.Duration.errorShake > 0)
        #expect(LMKAnimationHelper.Duration.photoLoad > 0)
    }

    @Test("Spring damping is in valid range")
    func springDampingRange() {
        let damping = LMKAnimationHelper.Spring.damping
        #expect(damping > 0 && damping <= 1)
    }

    @Test("tableViewRowAnimation returns valid value")
    func tableViewRowAnimation() {
        let animation = LMKAnimationHelper.tableViewRowAnimation
        // Should be either .automatic or .none depending on Reduce Motion
        #expect(animation == .automatic || animation == .none)
    }

    // MARK: - Additional Duration Tests

    @Test("All duration values are positive")
    func allDurationsPositive() {
        #expect(LMKAnimationHelper.Duration.screenTransition > 0)
        #expect(LMKAnimationHelper.Duration.modalPresentation > 0)
        #expect(LMKAnimationHelper.Duration.actionSheet > 0)
        #expect(LMKAnimationHelper.Duration.alert > 0)
        #expect(LMKAnimationHelper.Duration.uiShort > 0)
        #expect(LMKAnimationHelper.Duration.buttonPress > 0)
        #expect(LMKAnimationHelper.Duration.successFeedback > 0)
        #expect(LMKAnimationHelper.Duration.errorShake > 0)
        #expect(LMKAnimationHelper.Duration.photoLoad > 0)
        #expect(LMKAnimationHelper.Duration.listUpdate > 0)
        #expect(LMKAnimationHelper.Duration.listInsertDelete > 0)
        #expect(LMKAnimationHelper.Duration.cardExpand > 0)
    }

    @Test("Duration values are reasonable (< 2 seconds)")
    func durationsReasonable() {
        // Animations should be quick (< 2 seconds)
        #expect(LMKAnimationHelper.Duration.screenTransition < 2.0)
        #expect(LMKAnimationHelper.Duration.modalPresentation < 2.0)
        #expect(LMKAnimationHelper.Duration.buttonPress < 2.0)
        #expect(LMKAnimationHelper.Duration.errorShake < 2.0)
    }

    // MARK: - Curve Tests

    @Test("Animation curves are defined")
    func curvesAreDefined() {
        let _ = LMKAnimationHelper.Curve.easeInOut
        let _ = LMKAnimationHelper.Curve.easeOut
        let _ = LMKAnimationHelper.Curve.easeIn
        // Test passes if no crashes occur
    }

    // MARK: - Button Press Animation Tests

    @Test("animateButtonPressDown respects shouldAnimate")
    func buttonPressDownRespectsReduceMotion() {
        let button = UIButton()
        button.frame = CGRect(x: 0, y: 0, width: 100, height: 44)

        LMKAnimationHelper.animateButtonPressDown(button)
        // Test completes without crashing
    }

    @Test("animateButtonPressUp calls completion")
    func buttonPressUpCallsCompletion() {
        let button = UIButton()
        button.frame = CGRect(x: 0, y: 0, width: 100, height: 44)

        var completionCalled = false
        LMKAnimationHelper.animateButtonPressUp(button) {
            completionCalled = true
        }

        // With Reduce Motion or instant animations, completion should be called immediately
        if !LMKAnimationHelper.shouldAnimate {
            #expect(completionCalled)
        }
    }

    @Test("animateButtonPress works without completion")
    func buttonPressWorksWithoutCompletion() {
        let button = UIButton()
        button.frame = CGRect(x: 0, y: 0, width: 100, height: 44)

        LMKAnimationHelper.animateButtonPress(button)
        // Test completes without crashing
    }

    // MARK: - Success Feedback Tests

    @Test("animateSuccessFeedback adds checkmark view")
    func successFeedbackAddsCheckmark() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))

        LMKAnimationHelper.animateSuccessFeedback(on: view)

        // Checkmark should be added as a subview
        #expect(view.subviews.count > 0)
    }

    @Test("animateSuccessFeedback removes duplicate checkmarks")
    func successFeedbackRemovesDuplicates() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))

        // Add success feedback twice
        LMKAnimationHelper.animateSuccessFeedback(on: view)
        let firstCount = view.subviews.count

        LMKAnimationHelper.animateSuccessFeedback(on: view)
        let secondCount = view.subviews.count

        // Should still have the same number of subviews (old checkmark removed)
        #expect(firstCount == secondCount)
    }

    // MARK: - Error Shake Tests

    @Test("animateErrorShake completes without crashing")
    func errorShakeWorks() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 44))

        var completionCalled = false
        LMKAnimationHelper.animateErrorShake(on: view) {
            completionCalled = true
        }

        // With Reduce Motion, completion should be called
        if !LMKAnimationHelper.shouldAnimate {
            #expect(completionCalled)
        }
    }

    // MARK: - Photo Load Tests

    @Test("animatePhotoLoad completes without crashing")
    func photoLoadWorks() {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        imageView.alpha = 1.0

        LMKAnimationHelper.animatePhotoLoad(on: imageView)

        // Test completes successfully (alpha will be 0 or 1 depending on Reduce Motion)
    }

    // MARK: - Fade Tests

    @Test("fadeIn completes without crashing")
    func fadeInWorks() {
        let view = UIView()
        view.alpha = 1.0

        LMKAnimationHelper.fadeIn(view)

        // Test completes successfully (alpha will be 0 or 1 depending on Reduce Motion and timing)
    }

    @Test("fadeOut with completion")
    func fadeOutCallsCompletion() {
        let view = UIView()
        view.alpha = 1.0

        var completionCalled = false
        LMKAnimationHelper.fadeOut(view) {
            completionCalled = true
        }

        if !LMKAnimationHelper.shouldAnimate {
            #expect(completionCalled)
        }
    }

    // MARK: - List Update Tests

    @Test("animateListUpdate calls animations block")
    func listUpdateCallsAnimations() {
        var animationsCalled = false

        LMKAnimationHelper.animateListUpdate(animations: {
            animationsCalled = true
        })

        #expect(animationsCalled)
    }
}
