//
//  BottomSheetExample.swift
//  LumiKitExample
//
//  Bottom Sheet: The base sheet, with keyboard avoidance.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Bottom Sheet

final class BottomSheetDetailViewController: DetailViewController {
    override func setupStackContent() {
        addSectionHeader("Keyboard Avoidance")
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "avoidsKeyboard (default true) lifts the sheet by the keyboard's actual overlap with it, using the keyboard's own "
                + "animation curve, and restores on hide. Starting a drag on the sheet resigns the first responder. Esc and Command-W dismiss."
        ))
        let presentButton = LMKButton(title: "Show Sheet with Text Field", style: .filled(.primary), target: self, action: #selector(showKeyboardSheet))
        stackView.addArrangedSubview(presentButton)

        addDivider()
        addSectionHeader("Style")
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "Style hides the drag indicator and cancel button, retunes the dimming, and restyles the container. onDismiss reports why the sheet went away."
        ))
        let minimalButton = LMKButton(title: "Show Minimal Sheet", style: .filled(.secondary), target: self, action: #selector(showMinimalSheet))
        stackView.addArrangedSubview(minimalButton)
    }

    @objc private func showKeyboardSheet() {
        let sheet = KeyboardAvoidingSheetController()
        sheet.onDismiss = { [weak self] reason in
            guard let self else { return }
            LMKToast.show(.info, "Dismissed: \(reason)", in: self)
        }
        sheet.present(from: self)
    }

    @objc private func showMinimalSheet() {
        let sheet = KeyboardAvoidingSheetController(style: LMKBottomSheetViewController.Style(
            surface: LMKSurfaceStyle(background: .glass(.regular)),
            dimmingAlpha: LMKAlpha.small,
            showsDragIndicator: false,
            showsCancelButton: false
        ))
        sheet.present(from: self)
    }
}

/// Minimal `LMKBottomSheetViewController` subclass with a text field, so the
/// built-in keyboard avoidance has a first responder to react to.
private final class KeyboardAvoidingSheetController: LMKBottomSheetViewController {
    private lazy var titleLabel: UILabel = {
        let label = UILabel.lmk_make(.body, text: "Rename Item")
        label.textAlignment = .center
        return label
    }()

    private lazy var nameField: LMKTextField = {
        let field = LMKTextField()
        field.placeholder = "Name"
        field.leadingIcon = UIImage(systemName: "pencil")
        return field
    }()

    override func setupSheetContent() {
        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(contentLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview().inset(LMKSpacing.large)
        }

        containerView.addSubview(nameField)
        nameField.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(LMKSpacing.large)
            make.leading.trailing.equalToSuperview().inset(LMKSpacing.large)
            make.bottom.equalTo(contentLayoutGuide.snp.bottom).inset(LMKSpacing.xs)
        }
    }
}
