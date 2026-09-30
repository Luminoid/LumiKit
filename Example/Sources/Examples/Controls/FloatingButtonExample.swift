//
//  FloatingButtonExample.swift
//  LumiKitExample
//
//  Floating Button: Draggable action button that snaps to a corner.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Floating Button

final class FloatingButtonDetailViewController: DetailViewController {
    private var floatingButton: LMKFloatingButton?

    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Floating Button")
        stack.addArrangedSubview(UILabel.lmk_make(
            .body,
            text: "A draggable button installed in a view or on the key window. Drag it to reposition: "
                + "it snaps to the nearest edge, stays inside the safe area, and remembers its corner under a positionKey. VoiceOver moves it with custom actions."
        ))

        let showButton = LMKButton(title: "Show Floating Button", style: .filled(.primary), target: self, action: #selector(showFloating))
        stack.addArrangedSubview(showButton)

        addDivider()
        addSectionHeader("Badge")
        let badgeButton = LMKButton(title: "Badge: count 5", style: .outlined(.destructive)) { [weak self] in self?.floatingButton?.badge = .count(5) }
        stack.addArrangedSubview(badgeButton)
        let dotButton = LMKButton(title: "Badge: dot", style: .outlined(.warning)) { [weak self] in self?.floatingButton?.badge = .dot }
        stack.addArrangedSubview(dotButton)
        let hideBadgeButton = LMKButton(title: "Hide Badge", style: .outlined(.neutral)) { [weak self] in self?.floatingButton?.badge = nil }
        stack.addArrangedSubview(hideBadgeButton)

        addDivider()
        addSectionHeader("Style")
        let glassButton = LMKButton(title: "Glass surface, secondary tint", style: .outlined()) { [weak self] in
            self?.floatingButton?.style.surface.background = .glass(.regular, tint: LMKColor.secondary)
        }
        stack.addArrangedSubview(glassButton)
        let disableButton = LMKButton(title: "Toggle enabled", style: .outlined(.neutral)) { [weak self] in
            self?.floatingButton?.isEnabled.toggle()
        }
        stack.addArrangedSubview(disableButton)

        addDivider()
        addSectionHeader("Dismiss")
        let dismissButton = LMKButton(title: "Dismiss Floating Button", style: .filled(.destructive), target: self, action: #selector(dismissFloating))
        stack.addArrangedSubview(dismissButton)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dismissFloating()
    }

    @objc private func showFloating() {
        floatingButton?.dismiss()
        let button = LMKFloatingButton(icon: UIImage(systemName: "ladybug"))
        button.positionKey = "example.floatingButton"
        button.onTap = { [weak self] in
            guard let self else { return }
            LMKToast.show(.info, "Floating button tapped!", in: self)
        }
        button.show(in: nil as UIWindowScene?)
        floatingButton = button
    }

    @objc private func dismissFloating() {
        floatingButton?.dismiss()
        floatingButton = nil
    }
}
