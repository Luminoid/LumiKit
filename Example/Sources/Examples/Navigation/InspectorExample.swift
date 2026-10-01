//
//  InspectorExample.swift
//  LumiKitExample
//
//  Split View Inspector: UISplitViewController.lmk_setInspector and its show, hide, and toggle helpers.
//

import LumiKitUI
import UIKit

// MARK: - Split View Inspector

final class InspectorDetailViewController: DetailViewController {
    override func setupStackContent() {
        addSectionHeader("lmk_setInspector")
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "On iOS 26 a split view controller gains an inspector column: a trailing pane on iPad and Mac for the selected item's details, a sheet in a compact width. "
                + "lmk_setInspector(_:preferredWidth:) installs it, lmk_setInspectorShown(_:) and lmk_toggleInspector() show and hide it. "
                + "Before iOS 26 the calls do nothing and lmk_supportsInspector is false, so the host shows the details another way."
        ))
        stackView.addArrangedSubview(UILabel.lmk_make(.body, text: "Inspector column on this OS: \(UISplitViewController().lmk_supportsInspector ? "available" : "not available")"))
        stackView.addArrangedSubview(LMKButton(title: "Present Split View", style: .filled(.primary)) { [weak self] in
            self?.presentSplitView()
        })
    }

    private func presentSplitView() {
        let split = UISplitViewController(style: .doubleColumn)
        split.setViewController(InspectorPaneViewController(role: .sidebar), for: .primary)
        split.setViewController(InspectorPaneViewController(role: .content), for: .secondary)
        split.lmk_setInspector(InspectorPaneViewController(role: .inspector), preferredWidth: 320)
        split.modalPresentationStyle = .fullScreen
        present(split, animated: true)
    }
}

/// One column of the demo split view.
private final class InspectorPaneViewController: DetailViewController {
    enum Role {
        case sidebar, content, inspector
    }

    private let role: Role

    init(role: Role) {
        self.role = role
        super.init()
        if role == .sidebar {
            // The column's own material (the iOS 26 floating sidebar) shows through.
            style.backgroundColor = .clear
        }
        title = switch role {
        case .sidebar: "Library"
        case .content: "Monstera"
        case .inspector: "Details"
        }
    }

    override func setupStackContent() {
        switch role {
        case .sidebar, .content:
            stackView.addArrangedSubview(UILabel.lmk_make(.body, text: role == .sidebar
                    ? "The primary column. In a compact width it is the first screen."
                    : "The selected item. Toggle the inspector for its details."))
            stackView.addArrangedSubview(LMKButton(title: "Toggle Inspector", style: .tinted()) { [weak self] in
                self?.splitViewController?.lmk_toggleInspector()
            })
            stackView.addArrangedSubview(LMKButton(title: "Close", style: .ghost(.neutral)) { [weak self] in
                self?.splitViewController?.dismiss(animated: true)
            })
        case .inspector:
            for (key, value) in [("Light", "Bright, indirect"), ("Water", "Every 7 days"), ("Humidity", "High")] {
                stackView.addArrangedSubview(UILabel.lmk_make(.captionMedium, text: key, color: LMKColor.textSecondary))
                stackView.addArrangedSubview(UILabel.lmk_make(.body, text: value))
            }
        }
    }
}
