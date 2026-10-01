//
//  KeyboardDismissExample.swift
//  LumiKitExample
//
//  Keyboard Dismiss: Dismiss on Return and on a tap outside a field.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Keyboard Dismiss

final class KeyboardDismissDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // One call on the view controller: tapping anywhere outside a field
        // dismisses the keyboard without swallowing control taps.
        lmk_dismissKeyboardOnTap()
    }

    override func setupStackContent() {
        addSectionHeader("lmk_dismissKeyboardOnReturn (UITextField)")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "Single-line fields have nothing to insert on Return, so Return "
                + "dismisses the keyboard: the return key becomes Done and the field "
                + "resigns on .editingDidEndOnExit."))

        let plainField = UITextField()
        plainField.placeholder = "Tap here, then press Return"
        // A plain UITextField in the kit's look: form styling plus a Dynamic Type text style.
        plainField.lmk_applyFormStyle()
        plainField.lmk_apply(.body)
        plainField.lmk_dismissKeyboardOnReturn()
        stackView.addArrangedSubview(plainField)
        plainField.snp.makeConstraints { $0.height.greaterThanOrEqualTo(LMKLayout.minimumTouchTarget) }

        addDivider()
        addSectionHeader("lmk_dismissKeyboardOnReturn (LMKTextField)")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "LMKTextField forwards the same call to its wrapped UITextField."))

        let lmkField = LMKTextField()
        lmkField.placeholder = "Same behavior on LMKTextField"
        lmkField.lmk_dismissKeyboardOnReturn()
        stackView.addArrangedSubview(lmkField)

        addDivider()
        addSectionHeader("lmk_dismissKeyboardOnTap (UIViewController)")
        stackView.addArrangedSubview(UILabel.lmk_make(.caption, text: "This page called lmk_dismissKeyboardOnTap() in viewDidLoad: focus a "
                + "field, then tap anywhere else on the page to dismiss the keyboard. "
                + "The button below still receives its tap."))

        let probeButton = LMKButton(title: "Taps still land here", style: .outlined(.primary), target: self, action: #selector(probeTapped))
        stackView.addArrangedSubview(probeButton)
    }

    @objc private func probeTapped() {
        LMKToast.show(.info, "Button tap received", in: self)
    }
}
