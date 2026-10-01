//
//  NavigationControllerExample.swift
//  LumiKitExample
//
//  Navigation Controller: Swipe back with the system bar hidden.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Navigation Controller

final class NavigationControllerDetailViewController: DetailViewController {
    override func setupStackContent() {
        addSectionHeader("Swipe back with the system bar hidden")
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "LMKNavigationController keeps the edge swipe working when the system navigation bar is hidden, which is every screen that draws an LMKNavigationBar. "
                + "The demo stack's bars follow the OS: glass capsules on iOS 26, tinted items over a hairline before. Push a few screens, then swipe from the left edge to pop."
        ))

        let presentButton = LMKButton(title: "Present Demo Stack", style: .filled(.primary),
                                      target: self,
                                      action: #selector(presentDemoStack))
        stackView.addArrangedSubview(presentButton)
    }

    @objc private func presentDemoStack() {
        let root = SwipeDemoViewController(depth: 1)
        let nav = LMKNavigationController(rootViewController: root)
        nav.setNavigationBarHidden(true, animated: false)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }
}

private final class SwipeDemoViewController: UIViewController {
    private let depth: Int

    init(depth: Int) {
        self.depth = depth
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = LMKColor.backgroundPrimary

        let navBar = LMKNavigationBar()
        navBar.title = "Screen \(depth)"
        if depth > 1 {
            navBar.showsBackButton = true
            navBar.onBack = { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
        } else {
            navBar.setLeftItems([
                .init(title: "Close") { [weak self] in
                    self?.dismiss(animated: true)
                },
            ])
        }
        navBar.install(in: view)

        let caption = UILabel.lmk_make(.caption, text: depth > 1
            ? "Swipe from the left edge to pop back, or tap the chevron."
            : "Push a screen, then try the edge-swipe gesture to pop.")
        caption.textAlignment = .center
        caption.numberOfLines = 0

        let pushButton = LMKButton(title: "Push Screen \(depth + 1)", style: .filled(.primary),
                                   target: self,
                                   action: #selector(push))

        let column = UIStackView(arrangedSubviews: [caption, pushButton])
        column.axis = .vertical
        column.spacing = LMKSpacing.large
        column.alignment = .fill
        view.addSubview(column)
        column.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(LMKSpacing.large)
            make.centerY.equalToSuperview()
        }
    }

    @objc private func push() {
        navigationController?.pushViewController(SwipeDemoViewController(depth: depth + 1), animated: true)
    }
}
