//
//  CardPanelExample.swift
//  LumiKitExample
//
//  Card Panel: A floating card in an overlay window.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Card Panel

final class CardPanelDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Tap to Dismiss")
        stack.addArrangedSubview(UILabel.lmk_make(.body, text: "A floating card panel in its own overlay window with a light dimming. Tap outside the card or tap dismiss to close."))
        let basicButton = LMKButton(title: "Show Card Panel", style: .filled(.primary), target: self, action: #selector(showBasicPanel))
        stack.addArrangedSubview(basicButton)

        addDivider()
        addSectionHeader("No Background Dismiss")
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "dismissesOnBackgroundTap = false: no dimming, touches outside the card pass through. Dismiss via the button inside the card."))
        let noDismissButton = LMKButton(title: "Show No-Dismiss Panel", style: .filled(.secondary), target: self, action: #selector(showNoDismissPanel))
        stack.addArrangedSubview(noDismissButton)

        addDivider()
        addSectionHeader("Modal Presentation")
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "presentation = .modal shows the panel as a full-screen modal over the host, so it stacks with other modals."))
        let modalButton = LMKButton(title: "Show Modal Panel", style: .filled(.secondary), target: self, action: #selector(showModalPanel))
        stack.addArrangedSubview(modalButton)

        addDivider()
        addSectionHeader("Panel + Card Page")
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "A card panel hosting an LMKCardPageViewController with multi-page navigation inside; the close item dismisses the panel."))
        let combinedButton = LMKButton(title: "Show Combined", style: .filled(.secondary), target: self, action: #selector(showCombinedPanel))
        stack.addArrangedSubview(combinedButton)
    }

    @objc private func showBasicPanel() {
        let content = BasicPanelContentViewController()
        let panel = LMKCardPanelViewController(rootViewController: content)
        content.panel = panel
        panel.present(from: self)
    }

    @objc private func showNoDismissPanel() {
        let content = BasicPanelContentViewController()
        let panel = LMKCardPanelViewController(rootViewController: content)
        panel.dismissesOnBackgroundTap = false
        content.panel = panel
        panel.present(from: self)
    }

    @objc private func showModalPanel() {
        let content = BasicPanelContentViewController()
        let panel = LMKCardPanelViewController(rootViewController: content)
        panel.presentation = .modal
        content.panel = panel
        panel.present(from: self)
    }

    @objc private func showCombinedPanel() {
        let page = PanelCardPageExample(title: "Panel Page")
        let panel = LMKCardPanelViewController(rootViewController: page)
        page.panel = panel
        panel.present(from: self)
    }
}

/// Simple content inside a card panel.
private final class BasicPanelContentViewController: UIViewController {
    weak var panel: LMKCardPanelViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = LMKColor.backgroundPrimary

        let stack = UIStackView(lmk_axis: .vertical, spacing: LMKSpacing.large)
        stack.alignment = .center

        let imageView = UIImageView(image: UIImage(systemName: "rectangle.inset.filled", withConfiguration: UIImage.SymbolConfiguration(pointSize: LMKLayout.symbolHero, weight: .regular)))
        imageView.tintColor = LMKColor.primary
        imageView.contentMode = .scaleAspectFit
        stack.addArrangedSubview(imageView)

        let label = UILabel.lmk_make(.body, text: "This is a card panel. Tap outside the card (when allowed) or tap dismiss to close.")
        label.textAlignment = .center
        stack.addArrangedSubview(label)
        stack.addArrangedSubview(LMKButton(title: "Dismiss", style: .filled(.destructive)) { [weak self] in self?.panel?.dismiss() })

        view.addSubview(stack)
        stack.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(LMKSpacing.large)
        }
    }
}

/// Card page hosted inside a card panel.
private final class PanelCardPageExample: LMKCardPageViewController {
    weak var panel: LMKCardPanelViewController?

    override init(title: String, style: Style = Style()) {
        super.init(title: title, style: style)
        leadingItem = nil
        self.style.showsHeaderSeparator = true
        trailingItem = .init(systemName: "xmark.circle.fill", accessibilityLabel: "Close") { [weak self] in self?.panel?.dismiss() }
    }

    override func setupContent() {
        let stack = UIStackView(lmk_axis: .vertical, spacing: LMKSpacing.large)
        stack.addArrangedSubview(UILabel.lmk_make(.body, text: "Card page inside a card panel. Navigate between pages, and dismiss with the close item."))
        stack.addArrangedSubview(LMKButton(title: "Push Settings", style: .outlined(.primary)) { [weak self] in self?.pushDetailPage(title: "Settings", icon: "gearshape") })
        stack.addArrangedSubview(LMKButton(title: "Push Profile", style: .outlined(.secondary)) { [weak self] in self?.pushDetailPage(title: "Profile", icon: "person.circle") })
        contentContainerView.addSubview(stack)
        stack.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview().inset(LMKSpacing.large) }
    }

    private func pushDetailPage(title: String, icon: String) {
        let contentStack = UIStackView(lmk_axis: .vertical, spacing: LMKSpacing.large)
        contentStack.alignment = .center

        let imageView = UIImageView(image: UIImage(systemName: icon, withConfiguration: UIImage.SymbolConfiguration(pointSize: LMKLayout.symbolHero, weight: .regular)))
        imageView.tintColor = LMKColor.primary
        imageView.contentMode = .scaleAspectFit
        contentStack.addArrangedSubview(imageView)

        let label = UILabel.lmk_make(.body, text: "This is the \(title) page inside the card panel. Tap back to return.")
        label.textAlignment = .center
        contentStack.addArrangedSubview(label)

        let wrapper = UIView()
        wrapper.addSubview(contentStack)
        contentStack.snp.makeConstraints {
            $0.top.equalToSuperview().offset(LMKSpacing.xxl)
            $0.leading.trailing.equalToSuperview().inset(LMKSpacing.large)
        }
        pushContentView(wrapper, title: title)
    }
}
