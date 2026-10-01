//
//  LMKMonthCalendarView+Paging.swift
//  LumiKit
//
//  Interactive month paging: a snapshot of the outgoing grid slides with the
//  finger while the incoming month renders underneath; a flick or a drag past
//  the commit fraction settles forward, anything else snaps back. Reduce
//  Motion (or `Style.paging == .discrete`) turns the swipe into a discrete
//  threshold gesture with no slide. One transition runs at a time: a new
//  drag, slide, or chevron tap finishes the one in flight first, and a
//  completion from an older transition is a no-op (`pagingGeneration`).
//

import LumiKitCore
import UIKit

extension LMKMonthCalendarView {
    /// What a pan that ended with `translation` / `velocity` should do.
    enum PagingDecision: Equatable {
        case commit
        case revert
    }

    /// Whether a pan touch starting at `x` (in the grid container) belongs to this view or to an
    /// outer page controller's edge band.
    func shouldReceivePanTouch(atX x: CGFloat) -> Bool {
        let band = resolvedStyle.reservedEdgeBandWidth ?? Self.defaultReservedEdgeBandWidth
        let width = gridContainer.bounds.width
        guard width > band * 2 else { return true }
        return x > band && x < width - band
    }

    /// The commit rule shared by the interactive and discrete modes.
    func pagingDecision(translation: CGFloat, velocity: CGFloat, width: CGFloat, direction: Int, discrete: Bool) -> PagingDecision {
        let distance = discrete ? (resolvedStyle.discreteSwipeThreshold ?? traitCollection.lmkTheme.layout.minimumTouchTarget) : width * (resolvedStyle.commitFraction ?? Self.defaultCommitFraction)
        let flick = resolvedStyle.flickVelocity ?? Self.defaultFlickVelocity
        let movedEnough = abs(translation) >= distance
        let flicked = abs(velocity) > flick && (velocity < 0) == (direction > 0)
        return movedEnough || flicked ? .commit : .revert
    }

    var usesInteractivePaging: Bool {
        (resolvedStyle.paging ?? .interactive) == .interactive && LMKAnimation.shouldAnimate
    }

    private var isRightToLeft: Bool {
        effectiveUserInterfaceLayoutDirection == .rightToLeft
    }

    /// A logical (leading-to-trailing) distance as a visual x offset.
    private func visual(_ logical: CGFloat) -> CGFloat {
        isRightToLeft ? -logical : logical
    }

    // MARK: - Gesture

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = visual(gesture.translation(in: gridContainer).x)
        let vertical = gesture.translation(in: gridContainer).y
        switch gesture.state {
        case .changed:
            // Only a drag this gesture began follows the finger; a settle or a slide in flight
            // is finished by `beginDrag`, never fed the translation.
            guard !isDragging else {
                updateDrag(translation: translation)
                return
            }
            guard abs(translation) > 4, abs(translation) > abs(vertical) else { return }
            if usesInteractivePaging {
                beginDrag(translation: translation)
            }
        case .ended, .cancelled, .failed:
            let velocity = visual(gesture.velocity(in: gridContainer).x)
            if isDragging {
                endDrag(translation: translation, velocity: velocity, cancelled: gesture.state != .ended)
            } else if gesture.state == .ended, abs(translation) > abs(vertical) {
                let direction = translation < 0 ? 1 : -1
                if pagingDecision(translation: translation, velocity: velocity, width: gridContainer.bounds.width, direction: direction, discrete: true) == .commit {
                    requestMonthChange(to: visibleMonth.adding(months: direction, calendar: calendar), direction: direction, animated: false)
                }
            }
        default:
            break
        }
    }

    // MARK: - Interactive drag

    /// Starts following the finger toward the neighbouring month. A settle or a slide still in
    /// flight completes first, so its month is committed (and reported) before the new drag.
    func beginDrag(translation: CGFloat) {
        settlePaging()
        let direction = translation < 0 ? 1 : -1
        let neighbor = visibleMonth.adding(months: direction, calendar: calendar)
        guard canShow(neighbor), neighbor != visibleMonth else { return }
        isPaging = true
        isDragging = true
        dragDirection = direction
        dragTarget = neighbor
        installSnapshot()
        minimumRenderedRows = max(rowCount(for: visibleMonth), rowCount(for: neighbor))
        renderedMonth = neighbor
        render()
        updateDrag(translation: translation)
    }

    func updateDrag(translation: CGFloat) {
        let width = gridContainer.bounds.width
        let clamped = dragDirection > 0 ? max(min(translation, 0), -width) : min(max(translation, 0), width)
        pagingSnapshot?.transform = CGAffineTransform(translationX: visual(clamped), y: 0)
        gridStack.transform = CGAffineTransform(translationX: visual(clamped + CGFloat(dragDirection) * width), y: 0)
    }

    /// Settles the drag: forward past the commit rule, back otherwise.
    func endDrag(translation: CGFloat, velocity: CGFloat, cancelled: Bool) {
        guard isDragging else { return }
        isDragging = false
        let width = gridContainer.bounds.width
        let direction = dragDirection
        let decision = cancelled ? .revert : pagingDecision(translation: translation, velocity: velocity, width: width, direction: direction, discrete: false)
        let snapshot = pagingSnapshot
        let target = dragTarget
        let animations: () -> Void = { [weak self] in
            guard let self else { return }
            if decision == .commit {
                snapshot?.transform = CGAffineTransform(translationX: visual(CGFloat(-direction) * width), y: 0)
                gridStack.transform = .identity
            } else {
                snapshot?.transform = .identity
                gridStack.transform = CGAffineTransform(translationX: visual(CGFloat(direction) * width), y: 0)
            }
        }
        runTransition(curve: .easeOut, animations: animations) { [weak self] in
            guard let self else { return }
            if decision == .commit, let target {
                finishInteractivePaging(to: target)
            } else {
                renderedMonth = visibleMonth
                render()
            }
        }
    }

    /// Drops a drag or a transition in flight without changing the month (a reload landed
    /// mid-swipe); the pending completion becomes a no-op.
    func cancelPagingIfNeeded() {
        cancelSnapBack()
        guard isPaging else { return }
        pagingGeneration += 1
        pagingAnimator?.stopAnimation(true)
        pagingAnimator = nil
        pagingCompletion = nil
        if isDragging {
            panGesture.isEnabled = false
            panGesture.isEnabled = true
        }
        clearTransition()
        renderedMonth = visibleMonth
        render()
    }

    /// Brings the view to rest before a new transition: a settle or a slide in flight completes
    /// now (its month is committed and reported), a live drag is dropped, an unanswered proposal
    /// snaps back.
    func settlePaging() {
        if isDragging {
            cancelPagingIfNeeded()
        } else if let completion = pagingCompletion {
            pagingAnimator?.stopAnimation(true)
            pagingAnimator = nil
            pagingCompletion = nil
            completion.fire()
        }
        if !isPaging, renderedMonth != visibleMonth {
            cancelSnapBack()
            renderedMonth = visibleMonth
            render()
        }
    }

    // MARK: - Programmatic slide

    /// Slides to `month` in `direction` (1 = forward) and makes it the visible month.
    func slide(to month: LMKCalendarMonth, direction: Int, completion: (() -> Void)?) {
        settlePaging()
        guard LMKAnimation.shouldAnimate, window != nil, gridContainer.bounds.width > 0 else {
            visibleMonth = month
            renderedMonth = month
            render()
            completion?()
            return
        }
        isPaging = true
        installSnapshot()
        let width = gridContainer.bounds.width
        minimumRenderedRows = max(rowCount(for: visibleMonth), rowCount(for: month))
        visibleMonth = month
        renderedMonth = month
        render()
        gridStack.transform = CGAffineTransform(translationX: visual(CGFloat(direction) * width), y: 0)
        let snapshot = pagingSnapshot
        runTransition(curve: .easeInOut, animations: { [weak self] in
            guard let self else { return }
            snapshot?.transform = CGAffineTransform(translationX: visual(CGFloat(-direction) * width), y: 0)
            gridStack.transform = .identity
        }, finish: { [weak self] in
            guard let self else { return }
            render()
            completion?()
        })
    }

    // MARK: - Transition plumbing

    /// Puts an image of the outgoing grid over it (a plain view when no snapshot can be taken,
    /// so the paging state machine runs the same way off screen).
    private func installSnapshot() {
        pagingSnapshot?.removeFromSuperview()
        let snapshot = gridStack.snapshotView(afterScreenUpdates: false) ?? UIView()
        snapshot.frame = gridStack.frame
        snapshot.isUserInteractionEnabled = false
        gridContainer.addSubview(snapshot)
        pagingSnapshot = snapshot
    }

    /// Removes the snapshot and resets the grid to rest, keeping `isPaging` semantics in one place.
    private func clearTransition() {
        pagingSnapshot?.removeFromSuperview()
        pagingSnapshot = nil
        gridStack.transform = .identity
        minimumRenderedRows = 0
        isPaging = false
        isDragging = false
        dragDirection = 0
        dragTarget = nil
    }

    /// Runs `animations` as the one owned transition; `finish` runs exactly once, after the
    /// animation or straight away without a window, unless a newer transition superseded it.
    private func runTransition(curve: UIView.AnimationCurve, animations: @escaping () -> Void, finish: @escaping () -> Void) {
        pagingGeneration += 1
        let generation = pagingGeneration
        let complete: () -> Void = { [weak self] in
            guard let self, generation == pagingGeneration else { return }
            pagingAnimator = nil
            pagingCompletion = nil
            clearTransition()
            finish()
        }
        guard LMKAnimation.shouldAnimate, window != nil else {
            animations()
            complete()
            return
        }
        let duration = resolvedStyle.transitionDuration ?? traitCollection.lmkTheme.animation.slow
        let animator = UIViewPropertyAnimator(duration: duration, curve: curve, animations: animations)
        let once = LMKOnceCompletion(after: duration, complete)
        animator.addCompletion { _ in once.fire() }
        pagingAnimator = animator
        pagingCompletion = once
        animator.startAnimation()
    }
}
