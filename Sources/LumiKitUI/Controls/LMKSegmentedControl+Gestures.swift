//
//  LMKSegmentedControl+Gestures.swift
//  LumiKit
//
//  Tap selection, indicator dragging, and touch highlighting.
//

import UIKit

extension LMKSegmentedControl {
    // MARK: - Selection as a user action

    /// Selects `index` the way a tap does: animates the indicator, plays the haptic, and
    /// fires `onValueChange` and `.valueChanged`. Ignored while disabled or for a disabled segment.
    func select(_ index: Int) {
        guard isEnabled, items.indices.contains(index), isEnabledForSegment(at: index), index != selectedSegmentIndex else { return }
        setSelectedSegmentIndex(index, animated: true)
        if resolved.haptics ?? true { LMKHaptics.selection() }
        onValueChange?(index)
        sendActions(for: .valueChanged)
    }

    // MARK: - Tap

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        guard isEnabled else { return }
        let location = gesture.location(in: segmentStack)
        guard let index = segmentIndex(atX: location.x, clampingToEdges: true) else { return }
        select(index)
    }

    // MARK: - Drag

    /// The indicator pan begins only for a horizontal drag that starts on the pill, so a vertical
    /// drag scrolls an ancestor and a drag elsewhere on the control leaves a pager or the back
    /// swipe alone. UIKit fails the ancestors' recognizers once a pan begins, which is too late
    /// to cancel from the action.
    override public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === panGesture, let pan = gestureRecognizer as? UIPanGestureRecognizer else {
            return super.gestureRecognizerShouldBegin(gestureRecognizer)
        }
        let location = pan.location(in: containerView)
        let translation = pan.translation(in: containerView)
        let touchDown = CGPoint(x: location.x - translation.x, y: location.y - translation.y)
        return indicatorPanShouldBegin(velocity: pan.velocity(in: containerView), touchDown: touchDown)
    }

    /// Whether a pan with `velocity` whose touch landed at `touchDown` (in `containerView`) drags the indicator.
    func indicatorPanShouldBegin(velocity: CGPoint, touchDown: CGPoint) -> Bool {
        guard isEnabled, segmentLabels.indices.contains(selectedSegmentIndex), abs(velocity.x) > abs(velocity.y) else { return false }
        let slack = traitCollection.lmkTheme.spacing.small
        return indicatorView.frame.insetBy(dx: -slack, dy: -slack).contains(touchDown)
    }

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: containerView)

        switch gesture.state {
        case .began:
            guard isEnabled, segmentLabels.indices.contains(selectedSegmentIndex) else { return }
            isDragging = true
            preDragIndex = selectedSegmentIndex
            panStartOffset = location.x - indicatorView.center.x

        case .changed:
            guard isDragging, isEnabled else { return }
            let contentInset = resolved.contentInset ?? Self.defaultContentInset
            let indicatorInset = resolved.indicatorInset ?? Self.defaultIndicatorInset
            let halfWidth = indicatorView.bounds.width / 2
            let totalInset = contentInset + indicatorInset
            let minX = totalInset + halfWidth
            let maxX = containerView.bounds.width - totalInset - halfWidth
            let targetX = min(max(location.x - panStartOffset, minX), maxX)

            // Follow the finger directly; the constraints come back on release.
            indicatorLeading?.deactivate()
            indicatorTrailing?.deactivate()
            indicatorView.center.x = targetX

            if let index = segmentIndex(atX: targetX - contentInset, clampingToEdges: true),
               index != selectedSegmentIndex, isEnabledForSegment(at: index) {
                selectedSegmentIndex = index
                if resolved.haptics ?? true { LMKHaptics.selection() }
            }

        case .ended:
            endIndicatorDrag(committing: true)

        case .cancelled, .failed:
            endIndicatorDrag(committing: false)

        default:
            break
        }
    }

    /// Ends a drag: re-anchors the indicator and, when `committing`, reports a changed selection;
    /// otherwise the selection returns to the pre-drag segment. A no-op when no drag is running.
    func endIndicatorDrag(committing: Bool) {
        guard isDragging else { return }
        isDragging = false
        if !committing, selectedSegmentIndex != preDragIndex {
            suppressesIndicatorMove = true
            selectedSegmentIndex = preDragIndex
            suppressesIndicatorMove = false
        }
        moveIndicator(animated: true)
        if committing, selectedSegmentIndex != preDragIndex {
            onValueChange?(selectedSegmentIndex)
            sendActions(for: .valueChanged)
        }
    }

    /// The segment whose horizontal span contains `x` (in the stack's coordinates), whatever the
    /// vertical position: the expanded hit band and the content-inset ring around the segments
    /// map to the segment under them. With `clampingToEdges`, a point past either end maps to the
    /// outermost segment on that side; a point in a gap between scrollable segments maps to none.
    func segmentIndex(atX x: CGFloat, clampingToEdges: Bool) -> Int? {
        for (index, label) in segmentLabels.enumerated() where x >= label.frame.minX && x <= label.frame.maxX {
            return index
        }
        guard clampingToEdges,
              let leftmost = segmentLabels.indices.min(by: { segmentLabels[$0].frame.minX < segmentLabels[$1].frame.minX }),
              let rightmost = segmentLabels.indices.max(by: { segmentLabels[$0].frame.maxX < segmentLabels[$1].frame.maxX })
        else { return nil }
        if x < segmentLabels[leftmost].frame.minX { return leftmost }
        if x > segmentLabels[rightmost].frame.maxX { return rightmost }
        return nil
    }

    // MARK: - Touch highlight

    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard isEnabled, let touch = touches.first else { return }
        highlightedSegmentIndex = segmentIndex(atX: touch.location(in: segmentStack).x, clampingToEdges: true)
        updateSegmentAppearance()
    }

    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        clearHighlight()
    }

    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        clearHighlight()
    }

    private func clearHighlight() {
        guard highlightedSegmentIndex != nil else { return }
        highlightedSegmentIndex = nil
        updateSegmentAppearance()
    }
}
