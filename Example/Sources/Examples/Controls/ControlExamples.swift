//
//  ControlExamples.swift
//  LumiKitExample
//
//  Buttons, segmented control, switch, toggle button, text field, text view, and search bar examples.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Button Role Helpers

private extension LMKButtonRole {
    static let allRoles: [LMKButtonRole] = [.primary, .secondary, .destructive, .warning, .success, .info]

    var displayName: String {
        switch self {
        case .primary: "Primary"
        case .secondary: "Secondary"
        case .destructive: "Destructive"
        case .warning: "Warning"
        case .success: "Success"
        case .info: "Info"
        }
    }

    @MainActor var color: UIColor {
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
        addSectionHeader("Fit Content + Unselected")
        stack
            .addArrangedSubview(LMKLabelFactory
                .caption(
                    text: "fitsSegmentsToContent = true sizes each segment to its own text width. "
                        + "selectedSegmentIndex = -1 hides the indicator and renders every label unselected "
                        + "(matches UISegmentedControl.noSegment)."
                ))

        let ratingLabel = LMKLabelFactory.caption(text: "Rating: (none)")
        ratingLabel.textAlignment = .center
        let ratingSegment = LMKSegmentedControl(
            items: (1 ... 5).map { String(repeating: "\u{2605}", count: $0) }
        )
        ratingSegment.fitsSegmentsToContent = true
        ratingSegment.selectedSegmentIndex = -1
        ratingSegment.valueChangedHandler = { index in
            ratingLabel.text = "Rating: \(index + 1) star\(index == 0 ? "" : "s")"
        }

        // Wrap in a horizontal row with a trailing spacer so the control
        // sits at its intrinsic width instead of stretching with the parent stack.
        let ratingRow = UIStackView(
            lmk_axis: .horizontal,
            alignment: .center,
            arrangedSubviews: [ratingSegment, UIView()]
        )
        stack.addArrangedSubview(ratingRow)
        stack.addArrangedSubview(ratingLabel)

        let clearRatingButton = LMKButton(title: "Clear Rating", style: .ghost(LMKColor.primary))
        clearRatingButton.tapHandler = { [weak ratingSegment, weak ratingLabel] in
            ratingSegment?.selectedSegmentIndex = -1
            ratingLabel?.text = "Rating: (none)"
        }
        let clearRow = UIStackView(
            lmk_axis: .horizontal,
            alignment: .center,
            arrangedSubviews: [clearRatingButton, UIView()]
        )
        stack.addArrangedSubview(clearRow)

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

        addDivider()
        addSectionHeader("Scrollable + Fit Content")
        stack.addArrangedSubview(LMKLabelFactory.caption(
            text: "Combine makeScrollableContainer() with fitsSegmentsToContent = true to let each segment "
                + "size exactly to its text (plus itemPadding). Good for tag/filter bars where labels vary a lot. "
                + "itemPadding = 24pt for breathing room, itemSpacing = 4pt for a tight chip-style gap."
        ))

        let filters = [
            "All", "New", "Favorites", "Recently Updated",
            "Needs Attention", "Overdue", "Under Care",
            "Outdoor", "Indoor",
        ]
        let fitScrollSegmented = LMKSegmentedControl(items: filters)
        fitScrollSegmented.fitsSegmentsToContent = true
        fitScrollSegmented.itemPadding = LMKSpacing.xxl
        fitScrollSegmented.itemSpacing = LMKSpacing.xs
        fitScrollSegmented.selectedSegmentIndex = 0
        let fitScrollContainer = fitScrollSegmented.makeScrollableContainer()
        fitScrollContainer.snp.makeConstraints { make in
            make.height.equalTo(40)
        }

        let fitScrollLabel = LMKLabelFactory.caption(text: "Selected: All")
        fitScrollLabel.textAlignment = .center
        fitScrollSegmented.valueChangedHandler = { index in
            fitScrollLabel.text = "Selected: \(filters[index])"
        }
        stack.addArrangedSubview(fitScrollContainer)
        stack.addArrangedSubview(fitScrollLabel)
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

// MARK: - Slider

final class SliderDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Basic (continuous)")
        stack.addArrangedSubview(LMKLabelFactory.caption(
            text: "Bare slider — no caption, no readout. Range 0…1, continuous."
        ))
        let basicLabel = LMKLabelFactory.body(text: "Value: 0.00")
        basicLabel.textAlignment = .center
        let basic = LMKSlider()
        basic.valueChangedHandler = { value in
            basicLabel.text = String(format: "Value: %.2f", value)
        }
        stack.addArrangedSubview(basic)
        stack.addArrangedSubview(basicLabel)

        addDivider()
        addSectionHeader("Caption + Live Readout")
        stack.addArrangedSubview(LMKLabelFactory.caption(
            text: "caption + valueFormatter render a header row above the track. Range 0…100, continuous."
        ))
        let withCaption = LMKSlider()
        withCaption.caption = "Brightness"
        withCaption.minimumValue = 0
        withCaption.maximumValue = 100
        withCaption.value = 40
        withCaption.valueFormatter = { "\(Int($0))%" }
        stack.addArrangedSubview(withCaption)

        addDivider()
        addSectionHeader("Stepped (snap to multiples)")
        stack.addArrangedSubview(LMKLabelFactory.caption(
            text: "step = 10 snaps to 0, 10, 20, …, 100. The slider thumb glides during drag and "
                + "lands on exact multiples on release. Useful for indexed parameters (severity, "
                + "zoom levels, quantized intensity)."
        ))
        let stepped = LMKSlider()
        stepped.caption = "Severity"
        stepped.minimumValue = 0
        stepped.maximumValue = 100
        stepped.step = 10
        stepped.value = 50
        stepped.valueFormatter = { "\(Int($0))" }
        stack.addArrangedSubview(stepped)

        addDivider()
        addSectionHeader("Negative Range")
        stack.addArrangedSubview(LMKLabelFactory.caption(
            text: "Range −2…+2 (EV stops). step = 0.5. Formatter shows signed value."
        ))
        let ev = LMKSlider()
        ev.caption = "Exposure"
        ev.minimumValue = -2
        ev.maximumValue = 2
        ev.step = 0.5
        ev.value = 0
        ev.valueFormatter = { value in
            value > 0 ? String(format: "+%.1f EV", value) : String(format: "%.1f EV", value)
        }
        stack.addArrangedSubview(ev)

        addDivider()
        addSectionHeader("Programmatic Reset")
        stack.addArrangedSubview(LMKLabelFactory.caption(
            text: "Programmatic value changes are silent — valueChangedHandler only fires on user drag. "
                + "Tap Reset to see the slider animate without re-firing the handler."
        ))
        let resetSlider = LMKSlider()
        resetSlider.caption = "Volume"
        resetSlider.minimumValue = 0
        resetSlider.maximumValue = 1
        resetSlider.value = 0.75
        resetSlider.valueFormatter = { String(format: "%.0f%%", $0 * 100) }
        stack.addArrangedSubview(resetSlider)

        let resetButton = LMKButton(title: "Reset to 50%", style: .ghost(LMKColor.primary))
        resetButton.tapHandler = { [weak resetSlider] in
            resetSlider?.setValue(0.5, animated: true)
        }
        let resetRow = UIStackView(
            lmk_axis: .horizontal,
            alignment: .center,
            arrangedSubviews: [resetButton, UIView()]
        )
        stack.addArrangedSubview(resetRow)
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

// MARK: - Text Field

final class TextFieldDetailViewController: DetailViewController {
    private lazy var keyboardHelper = LMKKeyboardInsetHelper(scrollView: scrollView, rootView: view)
    private var liveValidationField: LMKTextField?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboardHelper.startObserving()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboardHelper.stopObserving()
    }

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
    private lazy var keyboardHelper = LMKKeyboardInsetHelper(scrollView: scrollView, rootView: view)

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboardHelper.startObserving()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboardHelper.stopObserving()
    }

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
        searchBar.placeholder = "Search items..."
        container.addSubview(searchBar)
        searchBar.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(LMKSpacing.medium)
        }
        stack.addArrangedSubview(container)
    }
}
