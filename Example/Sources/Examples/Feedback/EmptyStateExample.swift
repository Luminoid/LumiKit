//
//  EmptyStateExample.swift
//  LumiKitExample
//
//  Empty State: Full screen, card, and inline, with actions.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Empty State

final class EmptyStateDetailViewController: DetailViewController {
    private let toggleableEmpty = LMKEmptyStateView()
    private var actionInstalled = false

    override func setupStackContent() {
        addSectionHeader("Card Style")
        let cardEmpty = LMKEmptyStateView(style: .card)
        cardEmpty.configure(LMKEmptyStateView.Content(title: "Nothing here yet", message: "Add your first item to get started.", icon: .system("tray")))
        stackView.addArrangedSubview(cardEmpty)

        addDivider()
        addSectionHeader("Inline Style")
        let inlineEmpty = LMKEmptyStateView(style: .inline)
        inlineEmpty.configure(LMKEmptyStateView.Content(
            message: "No results found",
            icon: .system("magnifyingglass"),
            primaryAction: LMKEmptyStateView.Action(title: "Clear") { [weak self] in
                guard let self else { return }
                LMKToast.show(.info, "Filters cleared", in: self)
            }
        ))
        inlineEmpty.snp.makeConstraints { $0.height.greaterThanOrEqualTo(LMKLayout.minimumTouchTarget) }
        stackView.addArrangedSubview(inlineEmpty)

        addDivider()
        addSectionHeader("Full Screen Style")
        let fullEmpty = LMKEmptyStateView(style: .fullScreen)
        fullEmpty.configure(LMKEmptyStateView.Content(message: "Your collection is empty. Start by adding some items!", icon: .system("square.stack.3d.up.slash")))
        fullEmpty.snp.makeConstraints { $0.height.equalTo(200) }
        stackView.addArrangedSubview(fullEmpty)

        addDivider()
        addSectionHeader("Actions")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "Content carries a primary and a secondary action rendered below the message. "
                + "Icon, text, and buttons form one column, so the view sizes itself to its "
                + "content (no height is pinned here); a host-imposed height wins and centers the content instead."))
        let actionEmpty = LMKEmptyStateView(style: .card)
        actionEmpty.configure(LMKEmptyStateView.Content(
            title: "Your library is empty",
            message: "Add an item or import from another app.",
            icon: .system("books.vertical"),
            primaryAction: LMKEmptyStateView.Action(title: "Add Item", icon: "plus") { [weak self] in
                guard let self else { return }
                LMKToast.show(.success, "Action tapped", in: self)
            },
            secondaryAction: LMKEmptyStateView.Action(title: "Import") { [weak self] in
                guard let self else { return }
                LMKToast.show(.info, "Import tapped", in: self)
            }
        ))
        stackView.addArrangedSubview(actionEmpty)

        addDivider()
        addSectionHeader("setAction(_:)")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "setAction adds, replaces, or removes the button after configure, "
                + "for hosts whose call-to-action depends on state (permissions, "
                + "edit rights). Passing a custom style overrides the default filled primary."))
        toggleableEmpty.style = .card
        toggleableEmpty.configure(LMKEmptyStateView.Content(message: "No downloads yet.", icon: .system("arrow.down.circle")))
        stackView.addArrangedSubview(toggleableEmpty)
        let toggleButton = LMKButton(title: "Toggle Action", style: .outlined(.primary), target: self, action: #selector(toggleEmptyStateAction))
        stackView.addArrangedSubview(toggleButton)
    }

    @objc private func toggleEmptyStateAction() {
        actionInstalled.toggle()
        guard actionInstalled else {
            toggleableEmpty.setAction(nil)
            return
        }
        toggleableEmpty.setAction(
            LMKEmptyStateView.Action(title: "Browse", icon: "magnifyingglass", style: .outlined(.primary)) { [weak self] in
                guard let self else { return }
                LMKToast.show(.info, "Browse tapped", in: self)
            }
        )
    }
}
