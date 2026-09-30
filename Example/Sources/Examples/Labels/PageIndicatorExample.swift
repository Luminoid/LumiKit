//
//  PageIndicatorExample.swift
//  LumiKitExample
//
//  Page Indicator: Page dots with an expanding pill and a window.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Page Indicator

final class PageIndicatorDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Basic (dots only)")
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "Default style: all dots same size, active dot uses primary color."))

        let basicLabel = UILabel.lmk_make(.body, text: "Page 1 of 5")
        basicLabel.textAlignment = .center

        let basicIndicator = LMKPageIndicator()
        basicIndicator.numberOfPages = 5
        basicIndicator.currentPage = 0
        basicIndicator.onPageChange = { page in
            basicLabel.text = "Page \(page + 1) of 5"
        }
        basicIndicator.snp.makeConstraints { $0.height.equalTo(20) }
        stack.addArrangedSubview(basicIndicator)
        stack.addArrangedSubview(basicLabel)

        addDivider()
        addSectionHeader("Expanding Pill")
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "expandsActiveDot = true: active dot grows into a pill shape."))

        let pillLabel = UILabel.lmk_make(.body, text: "Page 1 of 5")
        pillLabel.textAlignment = .center

        let pillIndicator = LMKPageIndicator()
        pillIndicator.numberOfPages = 5
        pillIndicator.currentPage = 0
        pillIndicator.expandsActiveDot = true
        pillIndicator.onPageChange = { page in
            pillLabel.text = "Page \(page + 1) of 5"
        }
        pillIndicator.snp.makeConstraints { $0.height.equalTo(20) }
        stack.addArrangedSubview(pillIndicator)
        stack.addArrangedSubview(pillLabel)

        addDivider()
        addSectionHeader("Many Pages — Windowed (12 pages, max 7 dots)")
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "When pages > maxVisibleDots, a sliding window shows 7 dots. Edge dots are smaller."))

        let manyLabel = UILabel.lmk_make(.body, text: "Page 1 of 12")
        manyLabel.textAlignment = .center

        let manyIndicator = LMKPageIndicator()
        manyIndicator.numberOfPages = 12
        manyIndicator.maxVisibleDots = 7
        manyIndicator.currentPage = 0
        manyIndicator.onPageChange = { page in
            manyLabel.text = "Page \(page + 1) of 12"
        }
        manyIndicator.snp.makeConstraints { $0.height.equalTo(20) }
        stack.addArrangedSubview(manyIndicator)
        stack.addArrangedSubview(manyLabel)

        addDivider()
        addSectionHeader("Many Pages — Windowed + Expanding Pill")

        let manyPillLabel = UILabel.lmk_make(.body, text: "Page 1 of 15")
        manyPillLabel.textAlignment = .center

        let manyPillIndicator = LMKPageIndicator()
        manyPillIndicator.numberOfPages = 15
        manyPillIndicator.maxVisibleDots = 7
        manyPillIndicator.expandsActiveDot = true
        manyPillIndicator.currentPage = 0
        manyPillIndicator.onPageChange = { page in
            manyPillLabel.text = "Page \(page + 1) of 15"
        }
        manyPillIndicator.snp.makeConstraints { $0.height.equalTo(20) }
        stack.addArrangedSubview(manyPillIndicator)
        stack.addArrangedSubview(manyPillLabel)

        addDivider()
        addSectionHeader("Programmatic Navigation")

        let navIndicator = LMKPageIndicator()
        navIndicator.numberOfPages = 4
        navIndicator.currentPage = 0
        navIndicator.snp.makeConstraints { $0.height.equalTo(20) }
        stack.addArrangedSubview(navIndicator)

        let prevBtn = LMKButton(title: "Previous", style: .ghost(.primary))
        prevBtn.onTap = { [weak navIndicator] in
            guard let ind = navIndicator, ind.currentPage > 0 else { return }
            ind.currentPage -= 1
        }

        let nextBtn = LMKButton(title: "Next", style: .ghost(.primary))
        nextBtn.onTap = { [weak navIndicator] in
            guard let ind = navIndicator, ind.currentPage < ind.numberOfPages - 1 else { return }
            ind.currentPage += 1
        }

        let navRow = UIStackView(lmk_axis: .horizontal)
        navRow.addArrangedSubview(prevBtn)
        navRow.addArrangedSubview(UIView())
        navRow.addArrangedSubview(nextBtn)
        stack.addArrangedSubview(navRow)
    }
}
