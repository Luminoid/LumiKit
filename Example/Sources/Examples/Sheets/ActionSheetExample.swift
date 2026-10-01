//
//  ActionSheetExample.swift
//  LumiKitExample
//
//  Action Sheet: Actions with icons, sub-pages, and custom content.
//

import LumiKitCore
import LumiKitUI
import UIKit

// MARK: - Action Sheet

final class ActionSheetDetailViewController: DetailViewController {
    override func setupStackContent() {
        addSectionHeader("Basic Action Sheet")
        let basicButton = LMKButton(title: "Show Action Sheet", style: .filled(.primary), target: self, action: #selector(showBasicSheet))
        stackView.addArrangedSubview(basicButton)

        addDivider()
        addSectionHeader("With Icons")
        let iconButton = LMKButton(title: "Show Action Sheet with Icons", style: .filled(.secondary), target: self, action: #selector(showIconSheet))
        stackView.addArrangedSubview(iconButton)

        addDivider()
        addSectionHeader("With Selection (isSelected)")
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "Actions with isSelected: true show a checkmark; isEnabled: false dims a row. Useful for single-selection options like sort order."
        ))
        let selectionButton = LMKButton(title: "Show Selection Sheet", style: .filled(.primary), target: self, action: #selector(showSelectionSheet))
        stackView.addArrangedSubview(selectionButton)

        addDivider()
        addSectionHeader("Sub-Page Navigation")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "Actions can navigate to sub-pages within the same sheet. Tap back or cancel to return or dismiss."))
        let subPageButton = LMKButton(title: "Show with Sub-Pages", style: .filled(.primary), target: self, action: #selector(showSubPageSheet))
        stackView.addArrangedSubview(subPageButton)

        addDivider()
        addSectionHeader("Custom Content with Confirm")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "A Configuration embeds a self-sizing view (a date picker) with a confirm button; handlers run after the sheet has gone."))
        let contentButton = LMKButton(title: "Show with Date Picker", style: .filled(.secondary), target: self, action: #selector(showContentSheet))
        stackView.addArrangedSubview(contentButton)
    }

    private func toast(_ status: LMKStatus, _ message: String) {
        LMKToast.show(status, message, in: self)
    }

    @objc private func showBasicSheet() {
        LMKActionSheet.present(
            from: self,
            title: "Item Actions",
            message: "Choose an action for this item.",
            actions: [
                .init(title: "Mark as Favorite") { [weak self] in self?.toast(.success, "Added to favorites!") },
                .init(title: "Edit Details") { [weak self] in self?.toast(.info, "Edit tapped") },
                .init(title: "Delete", style: .destructive) { [weak self] in self?.toast(.error, "Delete tapped") },
            ],
            onCancel: { [weak self] in self?.toast(.info, "Cancelled") }
        )
    }

    @objc private func showIconSheet() {
        LMKActionSheet.present(
            from: self,
            title: "Media Actions",
            actions: [
                .init(title: "Take Photo", icon: UIImage(systemName: "camera")) { [weak self] in self?.toast(.info, "Camera tapped") },
                .init(title: "Choose from Library", icon: UIImage(systemName: "photo.on.rectangle")) { [weak self] in self?.toast(.info, "Library tapped") },
                .init(title: "Delete Photo", style: .destructive, icon: UIImage(systemName: "trash")) { [weak self] in self?.toast(.error, "Delete tapped") },
            ]
        )
    }

    @objc private func showSelectionSheet() {
        let sortOptions = ["Date Added", "Name", "Category", "Priority"]
        let currentSort = "Name"
        LMKActionSheet.present(
            from: self,
            title: "Sort By",
            message: "Choose how to sort your items.",
            actions: sortOptions.map { option in
                .init(
                    title: option,
                    icon: UIImage(systemName: option == currentSort ? "arrow.up.arrow.down" : "line.3.horizontal.decrease"),
                    isSelected: option == currentSort,
                    isEnabled: option != "Priority"
                ) { [weak self] in self?.toast(.success, "Sort: \(option)") }
            }
        )
    }

    @objc private func showSubPageSheet() {
        LMKActionSheet.present(
            from: self,
            title: "Photo Actions",
            actions: [
                .init(
                    title: "Edit Category",
                    icon: UIImage(systemName: "tag"),
                    page: .init(
                        title: "Select Category",
                        actions: ["General", "Progress", "Favorite", "Archive"].map { name in
                            .init(title: name) { [weak self] in self?.toast(.success, "Selected: \(name)") }
                        }
                    )
                ),
                .init(
                    title: "Share",
                    icon: UIImage(systemName: "square.and.arrow.up"),
                    page: .init(
                        title: "Share via",
                        actions: [
                            .init(title: "Messages", icon: UIImage(systemName: "message")) { [weak self] in self?.toast(.info, "Messages tapped") },
                            .init(title: "Email", icon: UIImage(systemName: "envelope")) { [weak self] in self?.toast(.info, "Email tapped") },
                            .init(title: "Copy Link", icon: UIImage(systemName: "link")) { [weak self] in self?.toast(.success, "Link copied!") },
                        ]
                    )
                ),
                .init(title: "Delete", style: .destructive, icon: UIImage(systemName: "trash")) { [weak self] in self?.toast(.error, "Delete tapped") },
            ]
        )
    }

    @objc private func showContentSheet() {
        let datePicker = LMKDatePicker.makePicker(LMKDatePicker.Configuration(title: "Date"))
        LMKActionSheet.present(LMKActionSheet.Configuration(
            title: "Select Date",
            message: "The picker sizes itself; no content height needed. Under the Mac idiom the wheels become an inline calendar.",
            contentView: datePicker,
            confirmTitle: "Save",
            onConfirm: { [weak self] in
                self?.toast(.success, "Date: \(LMKDateFormat.string(datePicker.date, date: .medium))")
            }
        ), from: self)
    }
}
