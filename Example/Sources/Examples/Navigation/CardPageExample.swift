//
//  CardPageExample.swift
//  LumiKitExample
//
//  Card Page: A header and pages that push inside a card.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Card Page

final class CardPageDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Basic Card Page")
        stack.addArrangedSubview(UILabel.lmk_make(
            .body,
            text: "Header with a leading back item, a centered title, and an optional trailing item. Designed for a UINavigationController with a hidden system nav bar."
        ))
        let basicButton = LMKButton(title: "Show Basic Card Page", style: .filled(.primary), target: self, action: #selector(showBasic))
        stack.addArrangedSubview(basicButton)

        addDivider()
        addSectionHeader("Custom Items")
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "leadingItem with an xmark symbol, no trailing item, and style.showsHeaderSeparator."))
        let customButton = LMKButton(title: "Show Custom Items", style: .filled(.secondary), target: self, action: #selector(showCustomItems))
        stack.addArrangedSubview(customButton)

        addDivider()
        addSectionHeader("Drag Indicator")
        stack.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "style.showsDragIndicator puts a grabber at the top of the header, for a page in a sheet that a drag down dismisses. The header grows by the room it takes."
        ))
        let indicatorButton = LMKButton(title: "Show Drag Indicator", style: .filled(.primary), target: self, action: #selector(showDragIndicator))
        stack.addArrangedSubview(indicatorButton)

        addDivider()
        addSectionHeader("No Items")
        stack.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "leadingItem = nil and no trailing item: a standalone info page with the title spanning the header, and the drag indicator as the way out."
        ))
        let noItemsButton = LMKButton(title: "Show No Items", style: .filled(.secondary), target: self, action: #selector(showNoItems))
        stack.addArrangedSubview(noItemsButton)

        addDivider()
        addSectionHeader("Multi-Page Navigation")
        stack.addArrangedSubview(UILabel.lmk_make(.caption, text: "Push and pop content views with a slide animation. The back button shows while pages are stacked."))
        let multiPageButton = LMKButton(title: "Show Multi-Page", style: .filled(.primary), target: self, action: #selector(showMultiPage))
        stack.addArrangedSubview(multiPageButton)
    }

    private func presentCardPage(_ page: LMKCardPageViewController) {
        let navigation = UINavigationController(rootViewController: page)
        navigation.setNavigationBarHidden(true, animated: false)
        navigation.modalPresentationStyle = .pageSheet
        present(navigation, animated: true)
    }

    @objc private func showBasic() {
        presentCardPage(BasicExampleCardPage(title: "Basic Page"))
    }

    @objc private func showCustomItems() {
        presentCardPage(CustomItemsExampleCardPage(title: "Dismiss Page"))
    }

    @objc private func showDragIndicator() {
        presentCardPage(DragIndicatorExampleCardPage(title: "Drag to Dismiss"))
    }

    @objc private func showNoItems() {
        presentCardPage(NoItemsExampleCardPage(title: "Info Page"))
    }

    @objc private func showMultiPage() {
        presentCardPage(MultiPageExampleCardPage(title: "Root Page"))
    }
}

/// Basic card page: the default back chevron dismisses, a trailing item shows a toast.
private final class BasicExampleCardPage: LMKCardPageViewController {
    override init(title: String, style: Style = Style()) {
        super.init(title: title, style: style)
        trailingItem = .init(systemName: "doc.on.doc") { [weak self] in
            guard let self else { return }
            LMKToast.show(.success, "Trailing item tapped!", in: self)
        }
    }

    override func setupContent() {
        let label = UILabel.lmk_make(.body, text: "This is a basic card page. Tap the back chevron to dismiss, or the trailing item for an action.")
        contentContainerView.addSubview(label)
        label.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview().inset(LMKSpacing.large) }
    }

    override func leadingButtonTapped() {
        dismiss(animated: true)
    }
}

/// Custom leading symbol (xmark), no trailing item, with a separator.
private final class CustomItemsExampleCardPage: LMKCardPageViewController {
    override init(title: String, style: Style = Style()) {
        super.init(title: title, style: style)
        leadingItem = .init(systemName: "xmark", accessibilityLabel: "Close") { [weak self] in self?.dismiss(animated: true) }
        self.style.showsHeaderSeparator = true
    }

    override func setupContent() {
        let label = UILabel.lmk_make(.body, text: "This page uses an xmark leading item, no trailing item, and a header separator line.")
        contentContainerView.addSubview(label)
        label.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview().inset(LMKSpacing.large) }
    }
}

/// A grabber over the header of a page in a sheet.
private final class DragIndicatorExampleCardPage: LMKCardPageViewController {
    override init(title: String, style: Style = Style()) {
        super.init(title: title, style: style)
        leadingItem = .init(systemName: "xmark", accessibilityLabel: "Close") { [weak self] in self?.dismiss(animated: true) }
        self.style.showsHeaderSeparator = true
        self.style.showsDragIndicator = true
    }

    override func setupContent() {
        let label = UILabel.lmk_make(.body, text: "The drag indicator says the sheet can be pulled down. Size and color come from style.dragIndicatorSize and style.dragIndicatorColor.")
        contentContainerView.addSubview(label)
        label.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview().inset(LMKSpacing.large) }
    }
}

/// No items: a standalone info page.
private final class NoItemsExampleCardPage: LMKCardPageViewController {
    override init(title: String, style: Style = Style()) {
        super.init(title: title, style: style)
        leadingItem = nil
        self.style.showsHeaderSeparator = true
        self.style.showsDragIndicator = true
    }

    override func setupContent() {
        let label = UILabel.lmk_make(.body, text: "No header items. The title spans the header. Swipe down to dismiss this sheet.")
        contentContainerView.addSubview(label)
        label.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview().inset(LMKSpacing.large) }
    }
}

/// Multi-page navigation with push and pop.
private final class MultiPageExampleCardPage: LMKCardPageViewController {
    override init(title: String, style: Style = Style()) {
        super.init(title: title, style: style)
        self.style.showsHeaderSeparator = true
        trailingItem = .init(systemName: "doc.on.doc") { [weak self] in
            guard let self else { return }
            LMKToast.show(.success, "Copied!", in: self)
        }
    }

    override func setupContent() {
        let stack = UIStackView(lmk_axis: .vertical, spacing: LMKSpacing.large)
        stack.addArrangedSubview(UILabel.lmk_make(.body, text: "Tap a button to push a new content page with a slide animation. The back button appears for navigation."))
        stack.addArrangedSubview(LMKButton(title: "Push Settings Page", style: .outlined(.primary)) { [weak self] in self?.pushPage(title: "Settings", icon: "gearshape") })
        stack.addArrangedSubview(LMKButton(title: "Push Profile Page", style: .outlined(.secondary)) { [weak self] in self?.pushPage(title: "Profile", icon: "person.circle") })
        stack.addArrangedSubview(LMKButton(title: "Push About Page", style: .outlined(.info)) { [weak self] in self?.pushPage(title: "About", icon: "info.circle") })
        contentContainerView.addSubview(stack)
        stack.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview().inset(LMKSpacing.large) }
    }

    override func leadingButtonTapped() {
        dismiss(animated: true)
    }

    private func pushPage(title: String, icon: String) {
        let contentStack = UIStackView(lmk_axis: .vertical, spacing: LMKSpacing.large)
        contentStack.alignment = .center

        let imageView = UIImageView(image: UIImage(systemName: icon, withConfiguration: UIImage.SymbolConfiguration(pointSize: LMKLayout.symbolHero, weight: .regular)))
        imageView.tintColor = LMKColor.primary
        imageView.contentMode = .scaleAspectFit
        contentStack.addArrangedSubview(imageView)

        let label = UILabel.lmk_make(.body, text: "This is the \(title) page. Tap back to return to the root page with a slide animation.")
        label.textAlignment = .center
        contentStack.addArrangedSubview(label)
        contentStack.addArrangedSubview(LMKButton(title: "Push Another Level", style: .outlined(.secondary)) { [weak self] in self?.pushNestedPage() })

        let wrapper = UIView()
        wrapper.addSubview(contentStack)
        contentStack.snp.makeConstraints {
            $0.top.equalToSuperview().offset(LMKSpacing.xxl)
            $0.leading.trailing.equalToSuperview().inset(LMKSpacing.large)
        }
        pushContentView(wrapper, title: title)
    }

    private func pushNestedPage() {
        let label = UILabel.lmk_make(.body, text: "Nested page, multiple levels deep. Each back tap pops one level.")
        label.textAlignment = .center
        let wrapper = UIView()
        wrapper.addSubview(label)
        label.snp.makeConstraints {
            $0.top.equalToSuperview().offset(LMKSpacing.xxl)
            $0.leading.trailing.equalToSuperview().inset(LMKSpacing.large)
        }
        pushContentView(wrapper, title: "Nested")
    }
}
