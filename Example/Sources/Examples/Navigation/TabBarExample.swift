//
//  TabBarExample.swift
//  LumiKitExample
//
//  Tab Bar: LMKTabBarController: lazy roots, badges, sidebar, iOS 26 accessory.
//

import LumiKitUI
import UIKit

// MARK: - Tab Bar

final class TabBarDetailViewController: DetailViewController {
    private let sidebarSwitch = TabBarDetailViewController.makeSwitch(label: "Sidebar on iPad")
    private let minimizeSwitch = TabBarDetailViewController.makeSwitch(label: "Minimize on scroll")
    private let opaqueSwitch = TabBarDetailViewController.makeSwitch(label: "Opaque background")

    private static func makeSwitch(label: String) -> LMKSwitch {
        let toggle = LMKSwitch()
        toggle.accessibilityLabel = label
        return toggle
    }

    override func setupStackContent() {
        addSectionHeader("LMKTabBarController")
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "Built on the iOS 18 UITab model: roots are created on first selection, each wrapped in an LMKNavigationController, "
                + "selection goes through identifiers, ⌘1…⌘3 switch tabs on iPad, and the appearance comes from theme.tabBar. "
                + "On iOS 26 the bar can minimize on scroll and host a bottom accessory."
        ))
        stackView.addArrangedSubview(makeRow("Sidebar on iPad / Mac", sidebarSwitch))
        stackView.addArrangedSubview(makeRow("Minimize on scroll (iOS 26)", minimizeSwitch))
        stackView.addArrangedSubview(makeRow("Opaque background (no glass)", opaqueSwitch))
        let present = LMKButton(title: "Present Tab Bar", style: .filled(.primary), target: self, action: #selector(presentTabBar))
        stackView.addArrangedSubview(present)
    }

    private func makeRow(_ title: String, _ control: UIView) -> UIStackView {
        UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.medium, alignment: .center, arrangedSubviews: [UILabel.lmk_make(.body, text: title), UIView(), control])
    }

    @objc private func presentTabBar() {
        let style = LMKTabBarController.Style(
            forcesOpaqueBackground: opaqueSwitch.isOn,
            minimizesOnScroll: minimizeSwitch.isOn,
            prefersSidebarOnIPad: sidebarSwitch.isOn
        )
        let controller = DemoTabBarController(style: style)
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true)
    }
}

private final class DemoTabBarController: LMKTabBarController {
    init(style: Style) {
        super.init(tabs: [
            LMKTab(identifier: "library", title: "Library", systemImage: "books.vertical.fill") { DemoTabRootViewController(name: "Library") },
            LMKTab(identifier: "calendar", title: "Calendar", systemImage: "calendar", badge: .count(3)) { DemoTabRootViewController(name: "Calendar") },
            LMKTab(identifier: "more", title: "More", systemImage: "ellipsis.circle.fill") { DemoTabRootViewController(name: "More") },
        ], style: style)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let accessory = UILabel.lmk_make(.captionMedium, text: "Bottom accessory (iOS 26)", color: LMKColor.textSecondary)
        accessory.textAlignment = .center
        setBottomAccessory(accessory)
    }
}

private final class DemoTabRootViewController: LMKScrollStackViewController {
    private let name: String

    init(name: String) {
        self.name = name
        super.init()
        title = name
    }

    override func setupStackContent() {
        addSectionHeader(name)
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "This root was created the first time its tab was selected. Reorder or badge tabs from the buttons below; tap the selected tab again to pop to the root."
        ))
        let reorder = LMKButton(title: "Reverse tab order", style: .tinted()) { [weak self] in
            guard let tabBar = self?.tabBarController as? LMKTabBarController else { return }
            tabBar.reorderTabs(identifiers: tabBar.identifiers.reversed())
        }
        let badge = LMKButton(title: "Toggle Calendar badge", style: .tinted()) { [weak self] in
            guard let tabBar = self?.tabBarController as? LMKTabBarController else { return }
            tabBar.setBadge(tabBar.tab(identifier: "calendar")?.badge == nil ? .dot : nil, for: "calendar")
        }
        let close = LMKButton(title: "Close", style: .filled(.primary)) { [weak self] in
            self?.tabBarController?.dismiss(animated: true)
        }
        for button in [reorder, badge, close] {
            stackView.addArrangedSubview(button)
        }
        for index in 0 ..< 30 {
            stackView.addArrangedSubview(UILabel.lmk_make(.body, text: "Row \(index + 1) (scroll to see the bar minimize on iOS 26)"))
        }
    }
}
