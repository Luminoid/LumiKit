//
//  LMKSegmentedControl+Layout.swift
//  LumiKit
//
//  Layout modes, segment widths, intrinsic size, and indicator placement.
//

import SnapKit
import UIKit

extension LMKSegmentedControl {
    static let defaultContentInset: CGFloat = 4
    static let defaultIndicatorInset: CGFloat = 2
    static let defaultHeight: CGFloat = 44

    var resolvedLayout: Layout {
        resolved.layout ?? .equalWidth
    }

    // MARK: - Layout mode

    /// Configures scrolling, distribution, spacing, and layout priorities for the resolved layout.
    func applyLayoutMode(_ theme: LMKTheme) {
        let layout = resolvedLayout
        let scrollable = layout.isScrollable
        // Fit-content hugs its titles, but at large Dynamic Type sizes they can outgrow the host;
        // rather than let Auto Layout break one segment's width, the control scrolls sideways
        // (no bounce, so the pill drag still wins while everything fits).
        let scrollsWhenOverflowing = layout == .fitContent
        scrollView.isScrollEnabled = (scrollable || scrollsWhenOverflowing) && isEnabled
        scrollView.clipsToBounds = scrollable || scrollsWhenOverflowing
        scrollView.bounces = scrollable
        panGesture?.isEnabled = !scrollable && isEnabled
        segmentStack.distribution = layout == .equalWidth ? .fillEqually : .fill
        if case let .scrollable(_, spacing) = layout {
            segmentStack.spacing = spacing ?? theme.spacing.medium
        } else {
            segmentStack.spacing = 0
        }
        if scrollable || scrollsWhenOverflowing {
            containerFillWidthConstraint?.deactivate()
            containerMinWidthConstraint?.activate()
        } else {
            containerMinWidthConstraint?.deactivate()
            containerFillWidthConstraint?.activate()
        }
        setContentHuggingPriority(layout == .fitContent ? .required : .defaultHigh, for: .horizontal)
        let resistance: UILayoutPriority = switch layout {
        case .fitContent: .defaultHigh
        case .equalWidth: .defaultHigh
        case .scrollable: .defaultLow
        }
        setContentCompressionResistancePriority(resistance, for: .horizontal)
    }

    // MARK: - Widths

    /// Measures every title at the selected (wider) text style under the current traits.
    func recomputeReferenceWidths() {
        let style = resolved.selectedTextStyle ?? .bodyMedium
        segmentReferenceWidths = items.map { LMKTextMeasurement.width(of: $0, style: style, traits: traitCollection) }
    }

    /// The pinned width of the segment at `index`, or `nil` in the equal-width layout.
    func segmentWidth(at index: Int, theme: LMKTheme) -> CGFloat? {
        guard let reference = segmentReferenceWidths[lmk_safe: index] else { return nil }
        switch resolvedLayout {
        case .equalWidth:
            return nil
        case .fitContent:
            return reference + (resolved.itemPadding ?? theme.spacing.medium) * 2
        case let .scrollable(padding, _):
            return max(reference, theme.layout.minimumTouchTarget) + (padding ?? theme.spacing.large) * 2
        }
    }

    /// Pins each label to its layout width (none in the equal-width layout).
    func applySegmentWidthConstraints(_ theme: LMKTheme) {
        segmentWidthConstraints.forEach { $0.deactivate() }
        segmentWidthConstraints.removeAll()
        guard segmentLabels.count == segmentReferenceWidths.count else { return }
        for (index, label) in segmentLabels.enumerated() {
            guard let width = segmentWidth(at: index, theme: theme) else { continue }
            label.snp.makeConstraints { make in
                segmentWidthConstraints.append(make.width.equalTo(width).constraint)
            }
        }
    }

    /// The content width plus insets at the resolved height.
    func intrinsicSize(theme: LMKTheme) -> CGSize {
        let count = CGFloat(items.count)
        let contentInset = resolved.contentInset ?? Self.defaultContentInset
        let itemPadding = resolved.itemPadding ?? theme.spacing.medium
        let widths: CGFloat = switch resolvedLayout {
        case .equalWidth:
            ((segmentReferenceWidths.max() ?? 0) + itemPadding * 2) * count
        case .fitContent:
            segmentReferenceWidths.reduce(0, +) + itemPadding * 2 * count
        case let .scrollable(padding, spacing):
            segmentReferenceWidths.reduce(0) { $0 + max($1, theme.layout.minimumTouchTarget) }
                + (padding ?? theme.spacing.large) * 2 * count
                + (spacing ?? theme.spacing.medium) * max(count - 1, 0)
        }
        return CGSize(width: widths + contentInset * 2, height: resolvedHeight)
    }

    // MARK: - Indicator

    /// Re-anchors the indicator to the selected label (hidden for no selection) and, when
    /// scrolling, brings the segment into view.
    func moveIndicator(animated: Bool) {
        guard !segmentLabels.isEmpty else { return }
        guard segmentLabels.indices.contains(selectedSegmentIndex) else {
            indicatorLeading?.deactivate()
            indicatorTrailing?.deactivate()
            indicatorLeading = nil
            indicatorTrailing = nil
            indicatorView.isHidden = true
            return
        }

        indicatorView.isHidden = false
        let target = segmentLabels[selectedSegmentIndex]
        let inset = resolved.indicatorInset ?? Self.defaultIndicatorInset
        indicatorLeading?.deactivate()
        indicatorTrailing?.deactivate()
        indicatorView.snp.makeConstraints { make in
            indicatorLeading = make.leading.equalTo(target).offset(inset).constraint
            indicatorTrailing = make.trailing.equalTo(target).offset(-inset).constraint
        }

        if resolvedLayout.isScrollable, !target.bounds.isEmpty {
            let padding = resolved.contentInset ?? Self.defaultContentInset
            let rect = containerView.convert(target.frame, from: segmentStack).insetBy(dx: -padding, dy: 0)
            scrollView.scrollRectToVisible(rect, animated: animated && LMKAnimation.shouldAnimate)
        }

        if animated, LMKAnimation.shouldAnimate {
            UIView.animate(
                withDuration: LMKAnimation.Duration.fast,
                delay: 0,
                usingSpringWithDamping: LMKAnimation.spring.damping,
                initialSpringVelocity: 0,
                options: .curveEaseInOut
            ) { [self] in
                layoutIfNeeded()
            }
        }
    }
}
