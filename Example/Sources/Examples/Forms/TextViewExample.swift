//
//  TextViewExample.swift
//  LumiKitExample
//
//  Text View: Multi-line input that grows, with a character limit.
//

import LumiKitUI
import UIKit

// MARK: - Text View

final class TextViewDetailViewController: DetailViewController {
    override func setupStackContent() {
        addSectionHeader("Grows With Its Text")
        stackView.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "An LMKTextView starts at minimumHeight and grows line by line as you type; past maximumHeight it stops growing and scrolls. "
                + "Inside an LMKScrollStackViewController the page keeps the focused view above the keyboard."
        ))

        addDivider()
        addSectionHeader("Basic")
        let basic = LMKTextView()
        basic.placeholder = "Enter your notes here..."
        basic.minimumHeight = 120
        stackView.addArrangedSubview(basic)

        addDivider()
        addSectionHeader("With Character Limit and Maximum Height")
        let limited = LMKTextView()
        limited.placeholder = "Limited to 100 characters; scrolls past 200pt"
        limited.maxCharacterCount = 100
        limited.showsCharacterCount = true
        limited.maximumHeight = 200
        stackView.addArrangedSubview(limited)

        addDivider()
        addSectionHeader("Pre-filled with Counter")
        let prefilled = LMKTextView()
        prefilled.text = "This text view already has content. The character counter updates as you type."
        prefilled.maxCharacterCount = 200
        prefilled.showsCharacterCount = true
        stackView.addArrangedSubview(prefilled)
    }
}
