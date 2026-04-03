//
//  ControlExamples.swift
//  LumiKitExample
//
//  Buttons, segmented control, text field, text view, search bar, and toggle examples.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Button Role Helpers

extension LMKButtonRole {
    fileprivate static let allRoles: [LMKButtonRole] = [.primary, .secondary, .destructive, .warning, .success, .info]

    fileprivate var displayName: String {
        switch self {
        case .primary: "Primary"
        case .secondary: "Secondary"
        case .destructive: "Destructive"
        case .warning: "Warning"
        case .success: "Success"
        case .info: "Info"
        }
    }

    @MainActor fileprivate var color: UIColor {
        switch self {
        case .primary: LMKColor.primary
        case .secondary: LMKColor.secondary
        case .destructive: LMKColor.error
        case .warning: LMKColor.warning
        case .success: LMKColor.success
        case .info: LMKColor.info
        }
    }
}

// MARK: - Buttons

final class ButtonsDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Filled")
        for role in LMKButtonRole.allRoles {
            let btn = LMKButton(title: role.displayName, style: .filled(role.color))
            btn.tapHandler = { [weak self] in
                guard let self else { return }
                LMKToast.showSuccess(message: "Filled \(role.displayName) tapped", on: self)
            }
            stack.addArrangedSubview(btn)
        }

        addDivider()
        addSectionHeader("Outlined")
        for role in [LMKButtonRole.primary, .secondary, .destructive] {
            let btn = LMKButton(title: role.displayName, style: .outlined(role.color))
            btn.tapHandler = { [weak self] in
                guard let self else { return }
                LMKToast.showInfo(message: "Outlined \(role.displayName) tapped", on: self)
            }
            stack.addArrangedSubview(btn)
        }

        addDivider()
        addSectionHeader("Ghost (Text-Only)")
        for role in [LMKButtonRole.primary, .destructive] {
            let btn = LMKButton(title: "\(role.displayName) Ghost", style: .ghost(role.color))
            btn.tapHandler = { [weak self] in
                guard let self else { return }
                LMKToast.showInfo(message: "Ghost \(role.displayName) tapped", on: self)
            }
            stack.addArrangedSubview(btn)
        }

        addDivider()
        addSectionHeader("Icon-Only")
        let iconRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.medium, alignment: .center)
        let icons: [(String, LMKButtonRole)] = [("chevron.left", .primary), ("chevron.right", .primary), ("xmark", .destructive)]
        for (iconName, role) in icons {
            let btn = LMKButton(frame: .zero)
            btn.applyIconStyle(.iconOnly(role.color), iconName: iconName)
            btn.tapHandler = { [weak self] in
                guard let self else { return }
                LMKToast.showInfo(message: "\(iconName) tapped", on: self)
            }
            iconRow.addArrangedSubview(btn)
        }
        iconRow.addArrangedSubview(UIView())
        stack.addArrangedSubview(iconRow)

        addDivider()
        addSectionHeader("Loading State")
        let loadingBtn = LMKButton(title: "Tap to Load", style: .filled(LMKColor.primary))
        loadingBtn.isLoading = true
        stack.addArrangedSubview(loadingBtn)

        addDivider()
        addSectionHeader("didTapHandler")
        let typedBtn = LMKButton(title: "Button Reference Handler", style: .filled(LMKColor.primary))
        typedBtn.didTapHandler = { [weak self] button in
            guard let self else { return }
            button.isLoading = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                button.isLoading = false
                LMKToast.showSuccess(message: "Async operation complete", on: self)
            }
        }
        stack.addArrangedSubview(typedBtn)
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
    private var liveValidationField: LMKTextField?

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

// MARK: - Switch

final class SwitchDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Basic")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Custom toggle replacing UISwitch. Rounded track + sliding thumb with spring animation."))

        let toggleLabel = LMKLabelFactory.body(text: "Off")
        toggleLabel.textAlignment = .center

        let toggle = LMKSwitch()
        toggle.valueChangedHandler = { isOn in
            toggleLabel.text = isOn ? "On" : "Off"
        }

        let toggleRow = UIStackView(lmk_axis: .horizontal, alignment: .center, arrangedSubviews: [LMKLabelFactory.body(text: "Notifications"), UIView(), toggle])
        stack.addArrangedSubview(toggleRow)
        stack.addArrangedSubview(toggleLabel)

        addDivider()
        addSectionHeader("Pre-set State")

        let presetToggle = LMKSwitch()
        presetToggle.setOn(true, animated: false)
        let presetRow = UIStackView(lmk_axis: .horizontal, alignment: .center, arrangedSubviews: [LMKLabelFactory.body(text: "Dark Mode"), UIView(), presetToggle])
        stack.addArrangedSubview(presetRow)
    }
}

// MARK: - Toggle Button

final class ToggleButtonDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Basic")
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
    }
}

// MARK: - Search Bar

final class SearchBarDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Basic")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Uses backgroundTertiary — best visible on grouped/secondary backgrounds."))
        let basicBar = LMKSearchBar()
        basicBar.placeholder = "Search items..."
        stack.addArrangedSubview(basicBar)

        addDivider()
        addSectionHeader("On Secondary Background")
        let container = UIView()
        container.backgroundColor = LMKColor.backgroundSecondary
        container.layer.cornerRadius = LMKCornerRadius.medium

        let searchBar = LMKSearchBar()
        searchBar.placeholder = "Search plants..."
        container.addSubview(searchBar)
        searchBar.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(LMKSpacing.medium)
        }
        stack.addArrangedSubview(container)
    }
}

// MARK: - Divider

final class DividerDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Horizontal")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Pixel-perfect separator between content sections:"))
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

        let navRow = UIStackView(lmk_axis: .horizontal)
        navRow.addArrangedSubview(prevBtn)
        navRow.addArrangedSubview(UIView())
        navRow.addArrangedSubview(nextBtn)
        stack.addArrangedSubview(navRow)
    }
}
