//
//  LMKMonthCalendarView+Paging.swift
//  LumiKit
//
//  Interactive month paging: a snapshot of the outgoing grid slides with the
//  finger while the incoming month renders underneath; a flick or a drag past
//  the commit fraction settles forward, anything else snaps back. Reduce
//  Motion (or `Style.paging == .discrete`) turns the swipe into a discrete
//  threshold gesture with no slide.
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
        let band = resolvedStyle.reservedEdgeBandWidth ?? 24
        let width = gridContainer.bounds.width
        guard width > band * 2 else { return true }
        return x > band && x < width - band
    }

    /// The commit rule shared by the interactive and discrete modes.
    func pagingDecision(translation: CGFloat, velocity: CGFloat, width: CGFloat, direction: Int, discrete: Bool) -> PagingDecision {
        let distance = discrete ? (resolvedStyle.discreteSwipeThreshold ?? traitCollection.lmkTheme.layout.minimumTouchTarget) : width * (resolvedStyle.commitFraction ?? 0.4)
        let flick = resolvedStyle.flickVelocity ?? 300
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
            guard !isPaging else {
                updateDrag(translation: translation)
                return
            }
            guard abs(translation) > 4, abs(translation) > abs(vertical) else { return }
            if usesInteractivePaging {
                beginDrag(translation: translation)
            }
        case .ended, .cancelled, .failed:
            let velocity = visual(gesture.velocity(in: gridContainer).x)
            if isPaging {
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

    private static let snapshotTag = 0x4C4D_4B43 // "LMKC"

    private var dragSnapshot: UIView? {
        gridContainer.viewWithTag(Self.snapshotTag)
    }

    private func beginDrag(translation: CGFloat) {
        let direction = translation < 0 ? 1 : -1
        let neighbor = visibleMonth.adding(months: direction, calendar: calendar)
        guard canShow(neighbor), let snapshot = gridStack.snapshotView(afterScreenUpdates: false) else { return }
        isPaging = true
        dragDirection = direction
        dragTarget = neighbor
        snapshot.tag = Self.snapshotTag
        snapshot.frame = gridStack.frame
        gridContainer.addSubview(snapshot)
        minimumRenderedRows = max(rowCount(for: visibleMonth), rowCount(for: neighbor))
        renderedMonth = neighbor
        render()
        updateDrag(translation: translation)
    }

    private func updateDrag(translation: CGFloat) {
        let width = gridContainer.bounds.width
        let clamped = dragDirection > 0 ? max(min(translation, 0), -width) : min(max(translation, 0), width)
        dragSnapshot?.transform = CGAffineTransform(translationX: visual(clamped), y: 0)
        gridStack.transform = CGAffineTransform(translationX: visual(clamped + CGFloat(dragDirection) * width), y: 0)
    }

    private func endDrag(translation: CGFloat, velocity: CGFloat, cancelled: Bool) {
        let width = gridContainer.bounds.width
        let direction = dragDirection
        let decision = cancelled ? .revert : pagingDecision(translation: translation, velocity: velocity, width: width, direction: direction, discrete: false)
        let snapshot = dragSnapshot
        let target = dragTarget
        let duration = resolvedStyle.transitionDuration ?? LMKAnimation.Duration.slow
        let animates = LMKAnimation.shouldAnimate && window != nil

        let finish: () -> Void = { [weak self] in
            guard let self else { return }
            snapshot?.removeFromSuperview()
            gridStack.transform = .identity
            minimumRenderedRows = 0
            isPaging = false
            dragDirection = 0
            dragTarget = nil
            if decision == .commit, let target {
                finishInteractivePaging(to: target)
            } else {
                renderedMonth = visibleMonth
                render()
            }
        }
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
        guard animates else {
            animations()
            finish()
            return
        }
        let animator = UIViewPropertyAnimator(duration: duration, curve: .easeOut, animations: animations)
        let once = LMKOnceCompletion(after: duration, finish)
        animator.addCompletion { _ in once.fire() }
        animator.startAnimation()
    }

    /// Drops a drag in flight without changing the month (a reload landed mid-swipe).
    func cancelPagingIfNeeded() {
        guard isPaging else { return }
        panGesture.isEnabled = false
        panGesture.isEnabled = true
        dragSnapshot?.removeFromSuperview()
        gridStack.transform = .identity
        minimumRenderedRows = 0
        isPaging = false
        dragDirection = 0
        dragTarget = nil
        renderedMonth = visibleMonth
    }

    // MARK: - Programmatic slide

    /// Slides to `month` in `direction` (1 = forward) and makes it the visible month.
    func slide(to month: LMKCalendarMonth, direction: Int, completion: (() -> Void)?) {
        guard LMKAnimation.shouldAnimate, window != nil, gridContainer.bounds.width > 0, let snapshot = gridStack.snapshotView(afterScreenUpdates: false) else {
            visibleMonth = month
            renderedMonth = month
            render()
            completion?()
            return
        }
        isPaging = true
        snapshot.tag = Self.snapshotTag
        snapshot.frame = gridStack.frame
        gridContainer.addSubview(snapshot)
        let width = gridContainer.bounds.width
        minimumRenderedRows = max(rowCount(for: visibleMonth), rowCount(for: month))
        visibleMonth = month
        renderedMonth = month
        render()
        gridStack.transform = CGAffineTransform(translationX: visual(CGFloat(direction) * width), y: 0)
        let duration = resolvedStyle.transitionDuration ?? LMKAnimation.Duration.slow
        let finish: () -> Void = { [weak self] in
            guard let self else { return }
            snapshot.removeFromSuperview()
            gridStack.transform = .identity
            minimumRenderedRows = 0
            isPaging = false
            render()
            completion?()
        }
        let animator = UIViewPropertyAnimator(duration: duration, curve: .easeInOut) { [weak self] in
            guard let self else { return }
            snapshot.transform = CGAffineTransform(translationX: visual(CGFloat(-direction) * width), y: 0)
            gridStack.transform = .identity
        }
        let once = LMKOnceCompletion(after: duration, finish)
        animator.addCompletion { _ in once.fire() }
        animator.startAnimation()
    }
}
