//
//  TextViewExample.swift
//  LumiKitExample
//
//  Text View: Multi-line input that grows, with a character limit.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Text View

final class TextViewDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.lmk_enableKeyboardAdjustment()

        addSectionHeader("Keyboard Avoidance")
        stack
            .addArrangedSubview(UILabel.lmk_make(.caption, text: "The scroll view keeps the focused field above the keyboard via `lmk_enableKeyboardAdjustment()`."))

        addDivider()
        addSectionHeader("Basic")
        let basic = LMKTextView()
        basic.placeholder = "Enter your notes here..."
        basic.snp.makeConstraints { $0.height.equalTo(120) }
        stack.addArrangedSubview(basic)

        addDivider()
        addSectionHeader("With Character Limit")
        let limited = LMKTextView()
        limited.placeholder = "Limited to 100 characters"
        limited.maxCharacterCount = 100
        limited.showsCharacterCount = true
        limited.snp.makeConstraints { $0.height.equalTo(120) }
        stack.addArrangedSubview(limited)

        addDivider()
        addSectionHeader("Pre-filled with Counter")
        let prefilled = LMKTextView()
        prefilled.text = "This text view already has content. The character counter updates as you type."
        prefilled.maxCharacterCount = 200
        prefilled.showsCharacterCount = true
        prefilled.snp.makeConstraints { $0.height.equalTo(120) }
        stack.addArrangedSubview(prefilled)
    }
}
