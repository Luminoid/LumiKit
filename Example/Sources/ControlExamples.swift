//
//  ControlExamples.swift
//  LumiKitExample
//
//  Buttons, segmented control, text field, text view, search bar, and toggle examples.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Buttons

final class ButtonsDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("LMKButtonFactory")
        stack.addArrangedSubview(LMKButtonFactory.primary(title: "Primary Action", target: self, action: #selector(tapped)))
        stack.addArrangedSubview(LMKButtonFactory.secondary(title: "Secondary Action", target: self, action: #selector(tapped)))
        stack.addArrangedSubview(LMKButtonFactory.destructive(title: "Delete", target: self, action: #selector(tapped)))
        stack.addArrangedSubview(LMKButtonFactory.warning(title: "Warning", target: self, action: #selector(tapped)))

        addDivider()
        addSectionHeader("LMKButton")
        let button = LMKButton()
        button.setTitle("Tap me (closure-based)", for: .normal)
        button.setTitleColor(LMKColor.primary, for: .normal)
        button.tapHandler = { [weak self] in
            guard let self else { return }
            LMKToast.showSuccess(message: "LMKButton tapped!", on: self)
        }
        stack.addArrangedSubview(button)

        let animatedButton = LMKButton()
        animatedButton.setTitle("With press animation", for: .normal)
        animatedButton.setTitleColor(LMKColor.secondary, for: .normal)
        animatedButton.pressAnimationEnabled = true
        animatedButton.tapHandler = { [weak self] in
            guard let self else { return }
            LMKToast.showInfo(message: "Press animation enabled!", on: self)
        }
        stack.addArrangedSubview(animatedButton)
    }

    @objc private func tapped() {
        LMKToast.showSuccess(message: "Button tapped!", on: self)
    }
}

// MARK: - Segmented Control

final class SegmentedControlDetailViewController: DetailViewController {
    private lazy var statusLabel: UILabel = {
        let label = LMKLabelFactory.body(text: "Selected: Item 1")
        label.textAlignment = .center
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Basic")
        let segmented = LMKSegmentedControl(items: ["Item 1", "Item 2", "Item 3"])
        segmented.selectedSegmentIndex = 0
        segmented.valueChangedHandler = { [weak self] index in
            self?.statusLabel.text = "Selected: Item \(index + 1)"
        }
        stack.addArrangedSubview(segmented)
        stack.addArrangedSubview(statusLabel)

        addDivider()
        addSectionHeader("Typed Handler")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "didValueChangeHandler receives the LMKSegmentedControl instance for direct access to selectedSegmentIndex."))

        let typedSegmented = LMKSegmentedControl(items: ["Day", "Week", "Month"])
        typedSegmented.selectedSegmentIndex = 1
        let typedLabel = LMKLabelFactory.caption(text: "Period: Week")
        typedLabel.textAlignment = .center
        typedSegmented.didValueChangeHandler = { control in
            let titles = ["Day", "Week", "Month"]
            typedLabel.text = "Period: \(titles[control.selectedSegmentIndex])"
        }
        stack.addArrangedSubview(typedSegmented)
        stack.addArrangedSubview(typedLabel)
    }
}

// MARK: - Text Field

final class TextFieldDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

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
        liveField.tag = 100
        stack.addArrangedSubview(liveField)
    }

    @objc private func liveValidate(_ textField: UITextField) {
        guard let lmkField = view.viewWithTag(100) as? LMKTextField else { return }
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

// MARK: - Text View

final class TextViewDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

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
        limited.snp.makeConstraints { $0.height.equalTo(120) }
        stack.addArrangedSubview(limited)

        addDivider()
        addSectionHeader("Pre-filled")
        let prefilled = LMKTextView()
        prefilled.text = "This text view already has content. The character counter updates as you type."
        prefilled.maxCharacterCount = 200
        prefilled.snp.makeConstraints { $0.height.equalTo(120) }
        stack.addArrangedSubview(prefilled)
    }
}

// MARK: - Search & Toggle

final class SearchToggleDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Toggle Button")
        let toggle = LMKToggleButton(
            titleForStatusOn: "Notifications On",
            titleForStatusOff: "Notifications Off"
        )
        toggle.setTitleColor(LMKColor.primary, for: .normal)
        toggle.titleLabel?.font = LMKTypography.bodyMedium
        toggle.flipStatusOnTap = true
        toggle.status = .off
        toggle.snp.makeConstraints { $0.height.equalTo(LMKLayout.minimumTouchTarget) }
        stack.addArrangedSubview(toggle)

        addDivider()
        addSectionHeader("Search Bar")
        let searchBar = LMKSearchBar()
        searchBar.placeholder = "Search items..."
        stack.addArrangedSubview(searchBar)

        addDivider()
        addSectionHeader("Divider")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Horizontal divider below:"))
        stack.addArrangedSubview(LMKDividerView())
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Content continues here"))
    }
}
