//
//  TextFieldExample.swift
//  LumiKitExample
//
//  Text Field: Validation states, icons, helper text, counter.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Text Field

final class TextFieldDetailViewController: DetailViewController {
    private var liveValidationField: LMKTextField?

    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.lmk_enableKeyboardAdjustment()

        addSectionHeader("Keyboard Avoidance")
        stack
            .addArrangedSubview(UILabel.lmk_make(
                .caption,
                text: "Calls `scrollView.lmk_enableKeyboardAdjustment()` once in viewDidLoad: insets grow to the keyboard overlap and the focused field scrolls into view."
            ))

        addDivider()
        addSectionHeader("Basic")
        let basic = LMKTextField()
        basic.placeholder = "Enter your name"
        basic.helperText = "Your display name"
        stack.addArrangedSubview(basic)

        addDivider()
        addSectionHeader("With Leading Icon")
        let iconField = LMKTextField()
        iconField.placeholder = "Search..."
        iconField.leadingIcon = UIImage(systemName: "magnifyingglass")
        stack.addArrangedSubview(iconField)

        addDivider()
        addSectionHeader("Validation States")

        let normalField = LMKTextField()
        normalField.placeholder = "Normal state"
        normalField.validationState = .normal
        normalField.helperText = "Default appearance"
        stack.addArrangedSubview(normalField)

        let errorField = LMKTextField()
        errorField.placeholder = "Error state"
        errorField.text = "invalid@"
        errorField.validationState = .error("Please enter a valid email address")
        stack.addArrangedSubview(errorField)

        let successField = LMKTextField()
        successField.placeholder = "Success state"
        successField.text = "user@example.com"
        successField.validationState = .success
        stack.addArrangedSubview(successField)

        addDivider()
        addSectionHeader("Live Validation")
        let liveField = LMKTextField()
        liveField.placeholder = "Type at least 3 characters"
        liveField.helperText = "Validates on each keystroke"
        liveField.leadingIcon = UIImage(systemName: "person")
        liveField.textField.addTarget(self, action: #selector(liveValidate(_:)), for: .editingChanged)
        liveValidationField = liveField
        stack.addArrangedSubview(liveField)
    }

    @objc private func liveValidate(_ textField: UITextField) {
        guard let lmkField = liveValidationField else { return }
        let text = textField.text ?? ""
        if text.isEmpty {
            lmkField.validationState = .normal
        } else if text.count < 3 {
            lmkField.validationState = .error("Too short (\(text.count)/3)")
        } else {
            lmkField.validationState = .success
        }
    }
}
