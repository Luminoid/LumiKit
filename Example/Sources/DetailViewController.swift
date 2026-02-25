//
//  DetailViewController.swift
//  LumiKitExample
//
//  Base class for all example detail pages. Provides a scroll view + vertical stack layout.
//

import LumiKitUI
import SnapKit
import UIKit

class DetailViewController: UIViewController {
    let scrollView = UIScrollView()
    let stack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = LMKColor.backgroundPrimary

        scrollView.keyboardDismissMode = .onDrag
        stack.axis = .vertical
        stack.spacing = LMKSpacing.large

        view.addSubview(scrollView)
        scrollView.addSubview(stack)

        scrollView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        stack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(LMKSpacing.large)
            $0.width.equalToSuperview().offset(-LMKSpacing.large * 2)
        }
    }

    func addSectionHeader(_ text: String) {
        stack.addArrangedSubview(LMKLabelFactory.heading(text: text, level: 3))
    }

    func addDivider() {
        stack.addArrangedSubview(LMKDividerView())
    }
}
