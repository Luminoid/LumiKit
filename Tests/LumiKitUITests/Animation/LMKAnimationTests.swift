//
//  LMKAnimationTests.swift
//  LumiKit
//
//  `UIView.animate` writes the model value at once and runs its completion after the
//  duration in the xctest host, so the assertions read model values and poll completions.
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKAnimation

@MainActor
struct LMKAnimationTests {
    @Test
    func `Durations are positive, ordered, and under two seconds`() {
        let durations = [
            LMKAnimation.Duration.instant, LMKAnimation.Duration.fast, LMKAnimation.Duration.normal,
            LMKAnimation.Duration.moderate, LMKAnimation.Duration.slow, LMKAnimation.Duration.emphasis,
        ]
        #expect(durations.allSatisfy { $0 > 0 && $0 < 2 })
        #expect(durations == durations.sorted(), "the steps grow from instant to emphasis")
        #expect(LMKAnimation.Duration.shimmer > 0)
    }

    @Test
    func `Spring damping is in valid range and clamped`() {
        let damping = LMKAnimation.spring.damping
        #expect(damping > 0 && damping <= 1)
        #expect(LMKAnimation.Spring(damping: 2).damping == 1)
        #expect(LMKAnimation.Spring(damping: -1).damping == 0)
    }

    @Test
    func `tableViewRowAnimation follows Reduce Motion`() {
        let animation = LMKAnimation.tableViewRowAnimation
        #expect(animation == (LMKAnimation.shouldAnimate ? .automatic : .none))
    }

    // MARK: - Curve Tests

    @Test
    func `Curves map to their UIKit and Core Animation forms`() {
        #expect(LMKAnimation.Curve.easeIn.options == .curveEaseIn)
        #expect(LMKAnimation.Curve.easeOut.options == .curveEaseOut)
        #expect(LMKAnimation.Curve.easeInOut.options == .curveEaseInOut)
        #expect(LMKAnimation.Curve.linear.options == .curveLinear)
        #expect(LMKAnimation.Curve.easeIn.animationCurve == .easeIn)
        #expect(LMKAnimation.Curve.linear.animationCurve == .linear)
        #expect(LMKAnimation.Curve.easeInOut.timingFunction == CAMediaTimingFunction(name: .easeInEaseOut))
        #expect(LMKAnimation.Curve.allCases.count == 4)
    }

    // MARK: - Button Press Animation Tests

    @Test
    func `animateButtonPressDown scales the control by pressScale`() {
        let button = UIButton()
        button.frame = CGRect(x: 0, y: 0, width: 100, height: 44)

        LMKAnimation.animateButtonPressDown(button)
        let expected = LMKAnimation.shouldAnimate ? LMKAnimation.pressScale : 1
        #expect(button.transform.a == expected)
        #expect(button.transform.d == expected)
    }

    @Test
    func `animateButtonPressUp restores the transform and calls completion`() async {
        let button = UIButton()
        button.frame = CGRect(x: 0, y: 0, width: 100, height: 44)
        button.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)

        var completionCalled = false
        LMKAnimation.animateButtonPressUp(button) {
            completionCalled = true
        }

        #expect(button.transform == .identity)
        await LMKWait.until { completionCalled }
        #expect(completionCalled)
    }

    @Test
    func `animateButtonPress ends at identity and reports completion`() async {
        let control = UIControl(frame: CGRect(x: 0, y: 0, width: 100, height: 44))

        var completionCalled = false
        LMKAnimation.animateButtonPress(control) { completionCalled = true }

        #expect(control.transform == .identity)
        await LMKWait.until { completionCalled }
        #expect(completionCalled)
    }

    // MARK: - Success Feedback Tests

    @Test
    func `animateSuccessFeedback adds one centered checkmark and replaces an earlier one`() async {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))

        LMKAnimation.animateSuccessFeedback(on: view)
        let first = view.subviews.first as? UIImageView
        #expect(view.subviews.count == 1)
        #expect(first?.center == CGPoint(x: 100, y: 100))
        #expect(first?.tintColor == LMKColor.success)

        var completionCalled = false
        LMKAnimation.animateSuccessFeedback(on: view) { completionCalled = true }
        #expect(view.subviews.count == 1, "the earlier checkmark is removed before the new one is added")
        #expect(view.subviews.first !== first)

        await LMKWait.until { completionCalled }
        #expect(completionCalled)
        #expect(view.subviews.isEmpty, "the checkmark is removed once the feedback completes")
    }

    // MARK: - Error Shake Tests

    @Test
    func `animateErrorShake adds the shake animation and completes`() async {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 44))

        var completionCalled = false
        LMKAnimation.animateErrorShake(on: view) {
            completionCalled = true
        }

        if LMKAnimation.shouldAnimate {
            #expect(view.layer.animation(forKey: "shake") != nil)
        } else {
            #expect(view.layer.sublayers?.contains { $0.name == "lmk.errorFlash" } == true)
        }
        await LMKWait.until { completionCalled }
        #expect(completionCalled)
    }

    /// The regression: the Reduce Motion flash wrote the view's own border and restored a
    /// hard-coded width of 0, so an outlined field lost its border after one error.
    @Test
    func `The Reduce Motion flash leaves the view's border and alpha untouched`() async {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.blue.cgColor
        view.layer.cornerRadius = 8
        view.alpha = 0.5

        var completionCalled = false
        LMKAnimation.flashErrorBorder(on: view, completion: { completionCalled = true })
        let flash = view.layer.sublayers?.first { $0.name == "lmk.errorFlash" }
        #expect(flash != nil)
        #expect(flash?.cornerRadius == 8)
        #expect(flash?.borderWidth ?? 0 > 0)
        #expect(view.layer.borderWidth == 1)
        #expect(view.layer.borderColor == UIColor.blue.cgColor)
        #expect(view.alpha == 0.5)

        LMKAnimation.flashErrorBorder(on: view, completion: nil)
        #expect(view.layer.sublayers?.count(where: { $0.name == "lmk.errorFlash" }) == 1, "a second flash replaces the first")

        await LMKWait.until { completionCalled }
        #expect(completionCalled)
        #expect(view.layer.borderWidth == 1)
        #expect(view.alpha == 0.5)
    }

    // MARK: - Photo Load and Fade Tests

    @Test
    func `animatePhotoLoad ends at full alpha and identity`() async {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        imageView.alpha = 0.3

        var completionCalled = false
        LMKAnimation.animatePhotoLoad(on: imageView) { completionCalled = true }

        #expect(imageView.alpha == 1)
        #expect(imageView.transform == .identity)
        await LMKWait.until { completionCalled }
        #expect(completionCalled)
    }

    @Test
    func `fadeIn and fadeOut set the target alpha and complete`() async {
        let view = UIView()
        view.alpha = 0.5

        var fadedIn = false
        LMKAnimation.fadeIn(view) { fadedIn = true }
        #expect(view.alpha == 1)
        await LMKWait.until { fadedIn }
        #expect(fadedIn)

        var fadedOut = false
        LMKAnimation.fadeOut(view) { fadedOut = true }
        #expect(view.alpha == 0)
        await LMKWait.until { fadedOut }
        #expect(fadedOut)
    }

    // MARK: - List Update Tests

    @Test
    func `animateListUpdate runs the animations block and completes`() async {
        var animationsCalled = false
        var completionCalled = false

        LMKAnimation.animateListUpdate(animations: { animationsCalled = true }, completion: { completionCalled = true })

        #expect(animationsCalled)
        await LMKWait.until { completionCalled }
        #expect(completionCalled)
    }
}

// MARK: - LMKOnceCompletion

@MainActor
struct LMKOnceCompletionTests {
    @Test
    func `fire runs the completion once`() {
        var count = 0
        let once = LMKOnceCompletion(after: 10) { count += 1 }
        once.fire()
        once.fire()
        #expect(count == 1)
    }

    @Test
    func `The fallback fires after the duration when nothing calls fire`() async {
        var count = 0
        let once = LMKOnceCompletion(after: 0.05) { count += 1 }
        await LMKWait.until { count == 1 }
        #expect(count == 1)
        once.fire()
        #expect(count == 1, "the fallback consumed the completion")
    }

    @Test
    func `Releasing the completion cancels its fallback`() async {
        var count = 0
        var once: LMKOnceCompletion? = LMKOnceCompletion(after: 0.05) { count += 1 }
        _ = once
        once = nil
        try? await Task.sleep(for: .milliseconds(200))
        #expect(count == 0)
    }
}
