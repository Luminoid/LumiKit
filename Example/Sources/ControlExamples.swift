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

        addSectionHeader("Filled")

        let primaryBtn = LMKButtonFactory.filled(role: .primary, title: "Primary", target: self, action: #selector(showSuccessToast))
        stack.addArrangedSubview(primaryBtn)

        let secondaryBtn = LMKButtonFactory.filled(role: .secondary, title: "Secondary", target: self, action: #selector(showSuccessToast))
        stack.addArrangedSubview(secondaryBtn)

        let destructiveBtn = LMKButtonFactory.filled(role: .destructive, title: "Destructive", target: self, action: #selector(showSuccessToast))
        stack.addArrangedSubview(destructiveBtn)

        let warningBtn = LMKButtonFactory.filled(role: .warning, title: "Warning", target: self, action: #selector(showSuccessToast))
        stack.addArrangedSubview(warningBtn)

        let successBtn = LMKButtonFactory.filled(role: .success, title: "Success", target: self, action: #selector(showSuccessToast))
        stack.addArrangedSubview(successBtn)

        let infoBtn = LMKButtonFactory.filled(role: .info, title: "Info", target: self, action: #selector(showSuccessToast))
        stack.addArrangedSubview(infoBtn)

        addDivider()
        addSectionHeader("Outlined")

        let primaryOutlined = LMKButtonFactory.outlined(role: .primary, title: "Primary", target: self, action: #selector(showInfoToast))
        stack.addArrangedSubview(primaryOutlined)

        let secondaryOutlined = LMKButtonFactory.outlined(role: .secondary, title: "Secondary", target: self, action: #selector(showInfoToast))
        stack.addArrangedSubview(secondaryOutlined)

        let destructiveOutlined = LMKButtonFactory.outlined(role: .destructive, title: "Destructive", target: self, action: #selector(showInfoToast))
        stack.addArrangedSubview(destructiveOutlined)

        addDivider()
        addSectionHeader("Ghost (Text-Only)")

        let ghostPrimary = LMKButtonFactory.ghost(role: .primary, title: "Primary Ghost", target: self, action: #selector(showInfoToast))
        stack.addArrangedSubview(ghostPrimary)

        let ghostDestructive = LMKButtonFactory.ghost(role: .destructive, title: "Destructive Ghost", target: self, action: #selector(showInfoToast))
        stack.addArrangedSubview(ghostDestructive)

        addDivider()
        addSectionHeader("Icon-Only")

        let iconRow = UIStackView()
        iconRow.axis = .horizontal
        iconRow.spacing = LMKSpacing.medium
        iconRow.alignment = .center

        let chevronLeft = LMKButtonFactory.iconOnly(role: .primary, iconName: "chevron.left", target: self, action: #selector(showInfoToast))
        let chevronRight = LMKButtonFactory.iconOnly(role: .primary, iconName: "chevron.right", target: self, action: #selector(showInfoToast))
        let closeBtn = LMKButtonFactory.iconOnly(role: .destructive, iconName: "xmark", target: self, action: #selector(showInfoToast))
        iconRow.addArrangedSubview(chevronLeft)
        iconRow.addArrangedSubview(chevronRight)
        iconRow.addArrangedSubview(closeBtn)
        iconRow.addArrangedSubview(UIView()) // spacer
        stack.addArrangedSubview(iconRow)

        addDivider()
        addSectionHeader("Loading State")

        let loadingBtn = LMKButtonFactory.filled(role: .primary, title: "Tap to Load", target: self, action: #selector(showSuccessToast))
        loadingBtn.isLoading = true
        stack.addArrangedSubview(loadingBtn)

        addDivider()
        addSectionHeader("Typed Handler")
        let typed = LMKButtonFactory.filled(role: .primary, title: "Typed Handler", target: self, action: #selector(showTypedToast))
        stack.addArrangedSubview(typed)
    }

    @objc private func showSuccessToast() {
        LMKToast.showSuccess(message: "Button tapped!", on: self)
    }

    @objc private func showInfoToast() {
        LMKToast.showInfo(message: "Outlined button tapped!", on: self)
    }

    @objc private func showTypedToast() {
        LMKToast.showSuccess(message: "Typed handler tapped!", on: self)
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

        addSectionHeader("Pill (Default)")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Capsule corners, draggable indicator. Try dragging the pill!"))

        let segmented = LMKSegmentedControl(items: ["Item 1", "Item 2", "Item 3"])
        segmented.selectedSegmentIndex = 0
        segmented.valueChangedHandler = { [weak self] index in
            self?.statusLabel.text = "Selected: Item \(index + 1)"
        }
        stack.addArrangedSubview(segmented)
        stack.addArrangedSubview(statusLabel)

        addDivider()
        addSectionHeader("Rounded Corner Style")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "cornerStyle = .rounded — fixed medium corner radius."))

        let roundedLabel = LMKLabelFactory.caption(text: "Selected: List")
        roundedLabel.textAlignment = .center
        let rounded = LMKSegmentedControl(items: ["List", "Grid", "Map"])
        rounded.cornerStyle = .rounded
        rounded.selectedSegmentIndex = 0
        let roundedItems = ["List", "Grid", "Map"]
        rounded.valueChangedHandler = { index in
            roundedLabel.text = "Selected: \(roundedItems[index])"
        }
        stack.addArrangedSubview(rounded)
        stack.addArrangedSubview(roundedLabel)

        addDivider()
        addSectionHeader("Custom Item Padding")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "itemPadding = 24pt for extra breathing room."))

        let paddedLabel = LMKLabelFactory.caption(text: "Selected: Photos")
        paddedLabel.textAlignment = .center
        let padded = LMKSegmentedControl(items: ["Photos", "Videos"])
        padded.itemPadding = LMKSpacing.xxl
        padded.selectedSegmentIndex = 0
        let paddedItems = ["Photos", "Videos"]
        padded.valueChangedHandler = { index in
            paddedLabel.text = "Selected: \(paddedItems[index])"
        }
        stack.addArrangedSubview(padded)
        stack.addArrangedSubview(paddedLabel)

        addDivider()
        addSectionHeader("Many Segments")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Five segments — width adapts to content."))

        let manySegmented = LMKSegmentedControl(items: ["Mon", "Tue", "Wed", "Thu", "Fri"])
        manySegmented.selectedSegmentIndex = 0
        let manyLabel = LMKLabelFactory.caption(text: "Selected: Mon")
        manyLabel.textAlignment = .center
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri"]
        manySegmented.valueChangedHandler = { index in
            manyLabel.text = "Selected: \(days[index])"
        }
        stack.addArrangedSubview(manySegmented)
        stack.addArrangedSubview(manyLabel)

        addDivider()
        addSectionHeader("Scrollable")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Use makeScrollableContainer() for many segments."))

        let scrollableSegmented = LMKSegmentedControl(items: (1 ... 12).map { "Month \($0)" })
        scrollableSegmented.selectedSegmentIndex = 0
        let scrollContainer = scrollableSegmented.makeScrollableContainer()
        scrollContainer.snp.makeConstraints { make in
            make.height.equalTo(40)
        }

        let scrollLabel = LMKLabelFactory.caption(text: "Selected: Month 1")
        scrollLabel.textAlignment = .center
        scrollableSegmented.valueChangedHandler = { index in
            scrollLabel.text = "Selected: Month \(index + 1)"
        }
        stack.addArrangedSubview(scrollContainer)
        stack.addArrangedSubview(scrollLabel)
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

// MARK: - Toggle & Switch

final class SearchToggleDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("LMKSwitch (Custom Switch)")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Custom toggle replacing UISwitch. Rounded track + sliding thumb with spring animation."))

        let toggleLabel = LMKLabelFactory.body(text: "Off")
        toggleLabel.textAlignment = .center

        let toggle = LMKSwitch()
        toggle.valueChangedHandler = { isOn in
            toggleLabel.text = isOn ? "On" : "Off"
        }

        let toggleRow = UIStackView(arrangedSubviews: [LMKLabelFactory.body(text: "Notifications"), UIView(), toggle])
        toggleRow.axis = .horizontal
        toggleRow.alignment = .center
        stack.addArrangedSubview(toggleRow)
        stack.addArrangedSubview(toggleLabel)

        addDivider()
        addSectionHeader("Pre-set Toggle")

        let presetToggle = LMKSwitch()
        presetToggle.setOn(true, animated: false)
        let presetRow = UIStackView(arrangedSubviews: [LMKLabelFactory.body(text: "Dark Mode"), UIView(), presetToggle])
        presetRow.axis = .horizontal
        presetRow.alignment = .center
        stack.addArrangedSubview(presetRow)

        addDivider()
        addSectionHeader("Toggle Button")
        let toggleButton = LMKToggleButton(
            titleForStatusOn: "Notifications On",
            titleForStatusOff: "Notifications Off"
        )
        toggleButton.setTitleColor(LMKColor.primary, for: .normal)
        toggleButton.titleLabel?.font = LMKTypography.bodyMedium
        toggleButton.flipStatusOnTap = true
        toggleButton.status = .off
        toggleButton.snp.makeConstraints { $0.height.equalTo(LMKLayout.minimumTouchTarget) }
        stack.addArrangedSubview(toggleButton)

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

// MARK: - Page Indicator

final class PageIndicatorDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Basic (dots only)")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Default style — all dots same size, active dot uses primary color."))

        let basicLabel = LMKLabelFactory.body(text: "Page 1 of 5")
        basicLabel.textAlignment = .center

        let basicIndicator = LMKPageIndicator()
        basicIndicator.numberOfPages = 5
        basicIndicator.currentPage = 0
        basicIndicator.pageChangedHandler = { page in
            basicLabel.text = "Page \(page + 1) of 5"
        }
        basicIndicator.snp.makeConstraints { $0.height.equalTo(20) }
        stack.addArrangedSubview(basicIndicator)
        stack.addArrangedSubview(basicLabel)

        addDivider()
        addSectionHeader("Expanding Pill")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "expandsActiveDot = true — active dot grows into a pill shape."))

        let pillLabel = LMKLabelFactory.body(text: "Page 1 of 5")
        pillLabel.textAlignment = .center

        let pillIndicator = LMKPageIndicator()
        pillIndicator.numberOfPages = 5
        pillIndicator.currentPage = 0
        pillIndicator.expandsActiveDot = true
        pillIndicator.pageChangedHandler = { page in
            pillLabel.text = "Page \(page + 1) of 5"
        }
        pillIndicator.snp.makeConstraints { $0.height.equalTo(20) }
        stack.addArrangedSubview(pillIndicator)
        stack.addArrangedSubview(pillLabel)

        addDivider()
        addSectionHeader("Many Pages — Windowed (12 pages, max 7 dots)")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "When pages > maxVisibleDots, a sliding window shows 7 dots. Edge dots are smaller."))

        let manyLabel = LMKLabelFactory.body(text: "Page 1 of 12")
        manyLabel.textAlignment = .center

        let manyIndicator = LMKPageIndicator()
        manyIndicator.numberOfPages = 12
        manyIndicator.maxVisibleDots = 7
        manyIndicator.currentPage = 0
        manyIndicator.pageChangedHandler = { page in
            manyLabel.text = "Page \(page + 1) of 12"
        }
        manyIndicator.snp.makeConstraints { $0.height.equalTo(20) }
        stack.addArrangedSubview(manyIndicator)
        stack.addArrangedSubview(manyLabel)

        addDivider()
        addSectionHeader("Many Pages — Windowed + Expanding Pill")

        let manyPillLabel = LMKLabelFactory.body(text: "Page 1 of 15")
        manyPillLabel.textAlignment = .center

        let manyPillIndicator = LMKPageIndicator()
        manyPillIndicator.numberOfPages = 15
        manyPillIndicator.maxVisibleDots = 7
        manyPillIndicator.expandsActiveDot = true
        manyPillIndicator.currentPage = 0
        manyPillIndicator.pageChangedHandler = { page in
            manyPillLabel.text = "Page \(page + 1) of 15"
        }
        manyPillIndicator.snp.makeConstraints { $0.height.equalTo(20) }
        stack.addArrangedSubview(manyPillIndicator)
        stack.addArrangedSubview(manyPillLabel)

        addDivider()
        addSectionHeader("Programmatic Navigation")

        let navIndicator = LMKPageIndicator()
        navIndicator.numberOfPages = 4
        navIndicator.currentPage = 0
        navIndicator.snp.makeConstraints { $0.height.equalTo(20) }
        stack.addArrangedSubview(navIndicator)

        let prevBtn = LMKButton(title: "Previous", style: .ghost(LMKColor.primary))
        prevBtn.tapHandler = { [weak navIndicator] in
            guard let ind = navIndicator, ind.currentPage > 0 else { return }
            ind.currentPage -= 1
        }

        let nextBtn = LMKButton(title: "Next", style: .ghost(LMKColor.primary))
        nextBtn.tapHandler = { [weak navIndicator] in
            guard let ind = navIndicator, ind.currentPage < ind.numberOfPages - 1 else { return }
            ind.currentPage += 1
        }

        let navRow = UIStackView()
        navRow.axis = .horizontal
        navRow.addArrangedSubview(prevBtn)
        navRow.addArrangedSubview(UIView())
        navRow.addArrangedSubview(nextBtn)
        stack.addArrangedSubview(navRow)
    }
}
