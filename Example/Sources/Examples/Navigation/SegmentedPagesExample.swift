//
//  SegmentedPagesExample.swift
//  LumiKitExample
//
//  Segmented Pages: Pages under a segmented control, swiped with the finger.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Segmented Pages

final class SegmentedPagesDetailViewController: DetailViewController {
    override func setupStackContent() {
        addSectionHeader("Tab container with interactive swipe paging")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "LMKSegmentedPageViewController pages between child view controllers selected by a "
                + "top LMKSegmentedControl. Drag horizontally, or swipe with two fingers on a trackpad, and both pages track the "
                + "gesture; release past the halfway point (or flick) to commit, otherwise it springs back. "
                + "Tapping a segment slides without the drag. Pages can opt into edge-only panning "
                + "via usesFullWidthSwipe(forPageAt:) so a map or custom grid keeps its interior drags. On the Mac the control "
                + "sits in the center of the window toolbar, where the navigation bar lives."))

        let presentButton = LMKButton(title: "Present Segmented Pages", style: .filled(.primary),
                                      target: self,
                                      action: #selector(presentDemo))
        stackView.addArrangedSubview(presentButton)
    }

    @objc private func presentDemo() {
        let nav = UINavigationController(rootViewController: SegmentedPagesDemoViewController())
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
}

private final class SegmentedPagesDemoViewController: LMKSegmentedPageViewController {
    init() {
        super.init(titles: ["First", "Second", "Third"])
        // The Mac window toolbar shows the title beside the control; the iPhone bar shows the control alone.
        title = "Segmented Pages"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(close)
        )
    }

    override func makePages() -> [UIViewController] {
        [
            SegmentedDemoPageViewController(index: 0, tint: LMKColor.primary),
            SegmentedDemoPageViewController(index: 1, tint: LMKColor.success),
            SegmentedDemoPageViewController(index: 2, tint: LMKColor.warning),
        ]
    }

    @objc private func close() {
        dismiss(animated: true)
    }
}

private final class SegmentedDemoPageViewController: UIViewController {
    private let index: Int
    private let tint: UIColor

    init(index: Int, tint: UIColor) {
        self.index = index
        self.tint = tint
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = tint.withAlphaComponent(LMKAlpha.xs)

        let titleLabel = UILabel.lmk_make(.h1, text: "Page \(index + 1)")
        let caption = UILabel.lmk_make(.caption, text: "Swipe left or right, or tap a segment above.")
        caption.textAlignment = .center
        caption.numberOfLines = 0

        let column = UIStackView(arrangedSubviews: [titleLabel, caption])
        column.axis = .vertical
        column.spacing = LMKSpacing.medium
        column.alignment = .center
        view.addSubview(column)
        column.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(LMKSpacing.large)
            make.centerY.equalToSuperview()
        }
    }
}
