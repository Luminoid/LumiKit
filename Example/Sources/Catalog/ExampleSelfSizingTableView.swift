//
//  ExampleSelfSizingTableView.swift
//  LumiKitExample
//
//  A non-scrolling table that reports its content height as its intrinsic
//  size, so a demo table inside a stack grows with its rows (Dynamic Type)
//  instead of clipping them at a fixed height.
//

import UIKit

final class ExampleSelfSizingTableView: UITableView {
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        isScrollEnabled = false
        rowHeight = UITableView.automaticDimension
        estimatedRowHeight = 64
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var measuredWidth: CGFloat = 0

    override var contentSize: CGSize {
        didSet {
            guard contentSize.height != oldValue.height else { return }
            invalidateIntrinsicContentSize()
        }
    }

    /// Rows self-size against the width they were measured at; a stack host hands the table its
    /// final width late, so re-measure every row once the width settles.
    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0, bounds.width != measuredWidth else { return }
        measuredWidth = bounds.width
        reloadData()
        super.layoutSubviews()
        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }
}
