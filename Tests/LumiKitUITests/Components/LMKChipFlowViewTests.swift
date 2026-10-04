//
//  LMKChipFlowViewTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKChipFlowViewTests {
    /// A leaf view with a fixed intrinsic size.
    private final class Box: UIView {
        var size: CGSize {
            didSet { invalidateIntrinsicContentSize() }
        }

        init(_ width: CGFloat, _ height: CGFloat = 30) {
            size = CGSize(width: width, height: height)
            super.init(frame: .zero)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var intrinsicContentSize: CGSize {
            size
        }
    }

    private static let style = LMKChipFlowView.Style(spacing: 8, lineSpacing: 6)

    private func makeFlow(_ widths: [CGFloat], width: CGFloat) -> (LMKChipFlowView, [Box]) {
        let boxes = widths.map { Box($0) }
        let flow = LMKChipFlowView(arrangedSubviews: boxes, style: Self.style)
        flow.frame = CGRect(x: 0, y: 0, width: width, height: 0)
        flow.layoutIfNeeded()
        return (flow, boxes)
    }

    @Test
    func `One line when the view is wide enough`() {
        let (flow, boxes) = makeFlow([60, 60, 60, 60], width: 300)
        #expect(boxes.map(\.frame.minX) == [0, 68, 136, 204])
        #expect(boxes.allSatisfy { $0.frame.minY == 0 && $0.frame.size == CGSize(width: 60, height: 30) })
        #expect(flow.intrinsicContentSize.height == 30)
        #expect(flow.intrinsicContentSize.width == UIView.noIntrinsicMetric)
    }

    @Test
    func `Wraps to new lines at a narrow width, from the leading edge`() {
        let (flow, boxes) = makeFlow([60, 60, 60, 60, 60], width: 140)
        #expect(boxes.map(\.frame.minX) == [0, 68, 0, 68, 0])
        #expect(boxes.map(\.frame.minY) == [0, 0, 36, 36, 72])
        #expect(flow.intrinsicContentSize.height == 102)
        #expect(flow.height(forWidth: 400) == 30)
        #expect(flow.height(forWidth: 300) == 66, "332pt of items wrap at 300")
        #expect(flow.height(forWidth: 60) == 174, "one item per line: five 30pt lines and four 6pt gaps")
    }

    @Test
    func `Right to left starts each line at the trailing edge`() {
        let boxes = [Box(60), Box(60), Box(60)]
        let flow = LMKChipFlowView(arrangedSubviews: boxes, style: Self.style)
        flow.semanticContentAttribute = .forceRightToLeft
        flow.frame = CGRect(x: 0, y: 0, width: 140, height: 0)
        flow.layoutIfNeeded()
        #expect(boxes.map(\.frame.maxX) == [140, 72, 140])
        #expect(boxes.map(\.frame.minY) == [0, 0, 36])
    }

    @Test
    func `Hidden items take no space; a wide item is narrowed to the line; shorter items center on the line`() {
        let tall = Box(40, 50)
        let (flow, boxes) = makeFlow([60, 60], width: 300)
        boxes[0].isHidden = true
        flow.addArrangedSubview(tall)
        flow.addArrangedSubview(Box(500))
        flow.layoutIfNeeded()
        #expect(boxes[1].frame.minX == 0)
        #expect(tall.frame.minX == 68)
        #expect(boxes[1].frame.minY == 10, "a 30pt item centers on a 50pt line")
        let wide = flow.arrangedSubviews[3]
        #expect(wide.frame == CGRect(x: 0, y: 56, width: 300, height: 30))
        #expect(flow.intrinsicContentSize.height == 86)
    }

    @Test
    func `Insert, remove, and replace keep the flow and its subviews in step`() {
        let (flow, boxes) = makeFlow([10, 20, 30], width: 300)
        let first = Box(5)
        flow.insertArrangedSubview(first, at: 0)
        #expect(flow.arrangedSubviews.first === first)
        flow.insertArrangedSubview(boxes[2], at: 0)
        #expect(flow.arrangedSubviews.map(\.intrinsicContentSize.width) == [30, 5, 10, 20], "an item already in the flow moves")
        flow.removeArrangedSubview(boxes[0])
        #expect(boxes[0].superview == nil)
        boxes[1].removeFromSuperview()
        #expect(!flow.arrangedSubviews.contains(boxes[1]), "a subview removed directly leaves the flow")
        flow.setArrangedSubviews([first])
        #expect(flow.arrangedSubviews == [first])
        #expect(flow.subviews == [first])
    }

    @Test
    func `In a stack the height follows the width it is given`() {
        let flow = LMKChipFlowView(arrangedSubviews: (0 ..< 5).map { _ in Box(60) }, style: Self.style)
        let stack = UIStackView(arrangedSubviews: [flow])
        stack.axis = .vertical
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 140, height: 400))
        container.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])
        let window = LMKThemeTesting.host(container, size: CGSize(width: 140, height: 400))
        defer { window.isHidden = true }
        for _ in 0 ..< 3 {
            window.layoutIfNeeded()
        }
        #expect(flow.frame.height == 102)

        container.frame.size.width = 400
        for _ in 0 ..< 3 {
            container.setNeedsLayout()
            window.layoutIfNeeded()
        }
        #expect(flow.frame.height == 30)
    }

    @Test
    func `A changed or hidden item re-measures the height after setNeedsLayout`() {
        let boxes = [Box(60), Box(60)]
        let flow = LMKChipFlowView(arrangedSubviews: boxes, style: Self.style)
        let stack = UIStackView(arrangedSubviews: [flow])
        stack.axis = .vertical
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 140, height: 400))
        container.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
        ])
        let window = LMKThemeTesting.host(container, size: CGSize(width: 140, height: 400))
        defer { window.isHidden = true }
        func settle() {
            for _ in 0 ..< 3 {
                window.layoutIfNeeded()
            }
        }
        settle()
        #expect(flow.frame.height == 30)

        // The width stays the same: only the item's new size wraps it to a second line.
        boxes[1].size = CGSize(width: 100, height: 30)
        flow.setNeedsLayout()
        settle()
        #expect(flow.frame.height == 66)

        boxes[1].isHidden = true
        flow.setNeedsLayout()
        settle()
        #expect(flow.frame.height == 30)
    }

    @Test
    func `Fitting sizes report the height for the target width`() {
        let flow = LMKChipFlowView(arrangedSubviews: (0 ..< 5).map { _ in Box(60) }, style: Self.style)
        let fitted = flow.systemLayoutSizeFitting(
            CGSize(width: 140, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        #expect(fitted == CGSize(width: 140, height: 102))
        #expect(flow.sizeThatFits(CGSize(width: 140, height: 0)) == CGSize(width: 140, height: 102))
        #expect(flow.sizeThatFits(.zero) == CGSize(width: 60 * 5 + 8 * 4, height: 30), "unbounded: one line as wide as the items")

        // Before it has a width of its own, the view measures against preferredMaxLayoutWidth.
        #expect(flow.intrinsicContentSize.height == 30)
        flow.preferredMaxLayoutWidth = 140
        #expect(flow.intrinsicContentSize.height == 102)
    }

    @Test
    func `A self-sizing cell takes the wrapped height once laid out at its width`() {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        let flow = LMKChipFlowView(arrangedSubviews: (0 ..< 5).map { _ in Box(60) }, style: Self.style)
        cell.contentView.addSubview(flow)
        flow.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            flow.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
            flow.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
            flow.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
            flow.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
        ])
        cell.frame = CGRect(x: 0, y: 0, width: 140, height: 44)
        cell.layoutIfNeeded()
        let fitted = cell.contentView.systemLayoutSizeFitting(
            CGSize(width: 140, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        #expect(fitted.height == 102)
    }

    @Test
    func `Chips lay out at their own size without overlapping`() {
        let chips = ["Vomiting", "Lethargy", "Sneezing", "Itching"].map { LMKChipView(text: $0) }
        let flow = LMKChipFlowView(arrangedSubviews: chips)
        let window = LMKThemeTesting.host(flow)
        defer { window.isHidden = true }
        flow.frame = CGRect(x: 0, y: 0, width: 200, height: 0)
        flow.layoutIfNeeded()
        let frames = chips.map(\.frame)
        #expect(frames.allSatisfy { $0.width > 0 && $0.height > 0 && $0.maxX <= 200 })
        for (index, frame) in frames.enumerated() {
            for other in frames[(index + 1)...] {
                #expect(!frame.intersects(other))
            }
        }
        #expect(flow.intrinsicContentSize.height >= frames.map(\.maxY).max() ?? 0)
    }

    @Test
    func `Spacing comes from the style, then theme.chipFlow, then the theme's small spacing`() {
        let flow = LMKChipFlowView(arrangedSubviews: [Box(10), Box(10)])
        let window = LMKThemeTesting.host(flow, theme: LMKThemeTesting.distinct)
        defer { window.isHidden = true }
        #expect(flow.resolvedSpacing == 9)
        #expect(flow.resolvedLineSpacing == 9)

        var theme = LMKThemeTesting.distinct
        theme.chipFlow = LMKChipFlowView.Style(spacing: 4)
        flow.applyTheme(theme)
        #expect(flow.resolvedSpacing == 4)
        #expect(flow.resolvedLineSpacing == 9)

        var applied = 0
        flow.didApplyStyle = { _ in applied += 1 }
        flow.style = LMKChipFlowView.Style(lineSpacing: 12)
        #expect(flow.resolvedLineSpacing == 12)
        #expect(applied == 1)
        #expect(LMKChipFlowView.Style(spacing: -3).spacing == 0)
        #expect(LMKChipFlowView.Style(spacing: 2).merging(LMKChipFlowView.Style(lineSpacing: 3)) == LMKChipFlowView.Style(spacing: 2, lineSpacing: 3))
    }

    @Test
    func `Convenience initializers build an empty flow`() {
        #expect(LMKChipFlowView().arrangedSubviews.isEmpty)
        let framed = LMKChipFlowView(frame: CGRect(x: 0, y: 0, width: 50, height: 10))
        #expect(framed.frame.width == 50)
        #expect(framed.intrinsicContentSize.height == 0)
    }
}
