//
//  TextFieldExample.swift
//  LumiKitExample
//
//  Text Field: Validation states, icons, helper text, counter.
//

import LumiKitUI
import UIKit

// MARK: - Text Field

final class TextFieldDetailViewController: DetailViewController {
    override func setupStackContent() {
        addSectionHeader("Keyboard Avoidance")
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "LMKScrollStackViewController installs scrollView.lmk_enableKeyboardAdjustment() for you: insets grow to the keyboard overlap and the focused field scrolls into view. "
                + "On a scroll view of your own, call it once."
        ))

        addDivider()
        addSectionHeader("Basic")
        let basic = LMKTextField()
        basic.placeholder = "Enter your name"
        basic.helperText = "Your display name"
        stackView.addArrangedSubview(basic)

        addDivider()
        addSectionHeader("With Leading Icon")
        let iconField = LMKTextField()
        iconField.placeholder = "Search..."
        iconField.leadingIcon = UIImage(systemName: "magnifyingglass")
        stackView.addArrangedSubview(iconField)

        addDivider()
        addSectionHeader("Validation States")

        let normalField = LMKTextField()
        normalField.placeholder = "Normal state"
        normalField.validationState = .normal
        normalField.helperText = "Default appearance"
        stackView.addArrangedSubview(normalField)

        let errorField = LMKTextField()
        errorField.placeholder = "Error state"
        errorField.text = "invalid@"
        errorField.validationState = .error("Please enter a valid email address")
        stackView.addArrangedSubview(errorField)

        let successField = LMKTextField()
        successField.placeholder = "Success state"
        successField.text = "user@example.com"
        successField.validationState = .success
        stackView.addArrangedSubview(successField)

        addDivider()
        addSectionHeader("Live Validation")
        let liveField = LMKTextField()
        liveField.placeholder = "Type at least 3 characters"
        liveField.helperText = "Validates on each keystroke"
        liveField.leadingIcon = UIImage(systemName: "person")
        liveField.onTextChange = { [weak liveField] text in
            if text.isEmpty {
                liveField?.validationState = .normal
            } else if text.count < 3 {
                liveField?.validationState = .error("Too short (\(text.count)/3)")
            } else {
                liveField?.validationState = .success
            }
        }
        stackView.addArrangedSubview(liveField)

        addDivider()
        addSectionHeader("Clear Button and Counter")
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "showsClearButton adds the kit's clear button while the field has text; maxCharacterCount with showsCharacterCount shows the counter and trims a paste to the limit."
        ))
        let counted = LMKTextField()
        counted.placeholder = "Up to 20 characters"
        counted.text = "Clear me"
        counted.showsClearButton = true
        counted.maxCharacterCount = 20
        counted.showsCharacterCount = true
        stackView.addArrangedSubview(counted)
    }
}
