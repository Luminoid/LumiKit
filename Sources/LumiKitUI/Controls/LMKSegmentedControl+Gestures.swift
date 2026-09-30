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
        guard let index = segmentIndex(at: location, clampingToEdges: false) else { return }
        select(index)
    }

    // MARK: - Drag

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard isEnabled else { return }
        let location = gesture.location(in: containerView)

        switch gesture.state {
        case .began:
            // Dragging needs a visible indicator, and a touch on or near it.
            guard segmentLabels.indices.contains(selectedSegmentIndex) else {
                gesture.state = .cancelled
                return
            }
            let slack = traitCollection.lmkTheme.spacing.small
            guard indicatorView.frame.insetBy(dx: -slack, dy: -slack).contains(location) else {
                gesture.state = .cancelled
                return
            }
            isDragging = true
            preDragIndex = selectedSegmentIndex
            panStartOffset = location.x - indicatorView.center.x

        case .changed:
            guard isDragging else { return }
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

            let stackLocation = CGPoint(x: targetX - contentInset, y: segmentStack.bounds.midY)
            if let index = segmentIndex(at: stackLocation, clampingToEdges: true),
               index != selectedSegmentIndex, isEnabledForSegment(at: index) {
                selectedSegmentIndex = index
                if resolved.haptics ?? true { LMKHaptics.selection() }
            }

        case .ended, .cancelled:
            guard isDragging else { return }
            isDragging = false
            moveIndicator(animated: true)
            if selectedSegmentIndex != preDragIndex {
                onValueChange?(selectedSegmentIndex)
                sendActions(for: .valueChanged)
            }

        default:
            break
        }
    }

    /// The segment under `point` (in the stack's coordinates). With `clampingToEdges`, a point
    /// past either end maps to the first or last segment.
    func segmentIndex(at point: CGPoint, clampingToEdges: Bool) -> Int? {
        for (index, label) in segmentLabels.enumerated() where label.frame.contains(point) {
            return index
        }
        guard clampingToEdges, !segmentLabels.isEmpty else { return nil }
        if point.x <= 0 { return 0 }
        if point.x >= segmentStack.bounds.width { return segmentLabels.count - 1 }
        return nil
    }

    // MARK: - Touch highlight

    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard isEnabled, let touch = touches.first else { return }
        highlightedSegmentIndex = segmentIndex(at: touch.location(in: segmentStack), clampingToEdges: false)
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
