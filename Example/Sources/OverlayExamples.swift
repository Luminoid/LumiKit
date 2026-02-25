//
//  OverlayExamples.swift
//  LumiKitExample
//
//  Action sheet, date picker, user tip, card page, card panel, and floating button examples.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Action Sheet

final class ActionSheetDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Basic Action Sheet")
        let basicButton = LMKButtonFactory.primary(title: "Show Action Sheet", target: self, action: #selector(showBasicSheet))
        stack.addArrangedSubview(basicButton)

        addDivider()
        addSectionHeader("With Icons")
        let iconButton = LMKButtonFactory.secondary(title: "Show Action Sheet with Icons", target: self, action: #selector(showIconSheet))
        stack.addArrangedSubview(iconButton)

        addDivider()
        addSectionHeader("Sub-Page Navigation")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Actions can navigate to sub-pages within the same sheet. Tap back or cancel to return/dismiss."))
        let subPageButton = LMKButtonFactory.primary(title: "Show with Sub-Pages", target: self, action: #selector(showSubPageSheet))
        stack.addArrangedSubview(subPageButton)

        addDivider()
        addSectionHeader("Sub-Page with Content View")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Sub-pages can embed custom views (e.g. a date picker) with a confirm button."))
        let contentButton = LMKButtonFactory.secondary(title: "Show with Date Picker", target: self, action: #selector(showContentSubPageSheet))
        stack.addArrangedSubview(contentButton)
    }

    @objc private func showBasicSheet() {
        LMKActionSheet.present(
            in: self,
            title: "Item Actions",
            message: "Choose an action for this item.",
            actions: [
                .init(title: "Mark as Favorite") { [weak self] in
                    guard let self else { return }
                    LMKToast.showSuccess(message: "Added to favorites!", on: self)
                },
                .init(title: "Edit Details") { [weak self] in
                    guard let self else { return }
                    LMKToast.showInfo(message: "Edit tapped", on: self)
                },
                .init(title: "Delete", style: .destructive) { [weak self] in
                    guard let self else { return }
                    LMKToast.showError(message: "Delete tapped", on: self)
                },
            ]
        )
    }

    @objc private func showIconSheet() {
        LMKActionSheet.present(
            in: self,
            title: "Media Actions",
            actions: [
                .init(title: "Take Photo", icon: UIImage(systemName: "camera")) { [weak self] in
                    guard let self else { return }
                    LMKToast.showInfo(message: "Camera tapped", on: self)
                },
                .init(title: "Choose from Library", icon: UIImage(systemName: "photo.on.rectangle")) { [weak self] in
                    guard let self else { return }
                    LMKToast.showInfo(message: "Library tapped", on: self)
                },
                .init(title: "Delete Photo", style: .destructive, icon: UIImage(systemName: "trash")) { [weak self] in
                    guard let self else { return }
                    LMKToast.showError(message: "Delete tapped", on: self)
                },
            ]
        )
    }

    @objc private func showSubPageSheet() {
        LMKActionSheet.present(
            in: self,
            title: "Photo Actions",
            actions: [
                .init(
                    title: "Edit Category",
                    icon: UIImage(systemName: "tag"),
                    page: .init(
                        title: "Select Category",
                        actions: ["Flower", "Progress", "Leaf", "Issue"].map { name in
                            .init(title: name) { [weak self] in
                                guard let self else { return }
                                LMKToast.showSuccess(message: "Selected: \(name)", on: self)
                            }
                        }
                    )
                ),
                .init(
                    title: "Share",
                    icon: UIImage(systemName: "square.and.arrow.up"),
                    page: .init(
                        title: "Share via",
                        actions: [
                            .init(title: "Messages", icon: UIImage(systemName: "message")) { [weak self] in
                                guard let self else { return }
                                LMKToast.showInfo(message: "Messages tapped", on: self)
                            },
                            .init(title: "Email", icon: UIImage(systemName: "envelope")) { [weak self] in
                                guard let self else { return }
                                LMKToast.showInfo(message: "Email tapped", on: self)
                            },
                            .init(title: "Copy Link", icon: UIImage(systemName: "link")) { [weak self] in
                                guard let self else { return }
                                LMKToast.showSuccess(message: "Link copied!", on: self)
                            },
                        ]
                    )
                ),
                .init(title: "Delete", style: .destructive, icon: UIImage(systemName: "trash")) { [weak self] in
                    guard let self else { return }
                    LMKToast.showError(message: "Delete tapped", on: self)
                },
            ]
        )
    }

    @objc private func showContentSubPageSheet() {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.date = Date()

        LMKActionSheet.present(
            in: self,
            title: "Photo Actions",
            actions: [
                .init(
                    title: "Edit Date",
                    icon: UIImage(systemName: "calendar"),
                    page: .init(
                        title: "Select Date",
                        contentView: datePicker,
                        contentHeight: 200,
                        confirmTitle: "Save",
                        onConfirm: { [weak self] in
                            guard let self else { return }
                            let formatter = DateFormatter()
                            formatter.dateStyle = .medium
                            LMKToast.showSuccess(message: "Date: \(formatter.string(from: datePicker.date))", on: self)
                        }
                    )
                ),
                .init(title: "Crop", icon: UIImage(systemName: "crop")) { [weak self] in
                    guard let self else { return }
                    LMKToast.showInfo(message: "Crop tapped", on: self)
                },
                .init(title: "Delete", style: .destructive, icon: UIImage(systemName: "trash")) { [weak self] in
                    guard let self else { return }
                    LMKToast.showError(message: "Delete tapped", on: self)
                },
            ]
        )
    }
}

// MARK: - Date Picker

final class DatePickerDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Single Date")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "General-purpose date picker with optional min/max bounds."))
        let singleButton = LMKButtonFactory.primary(title: "Pick a Date", target: self, action: #selector(showSinglePicker))
        stack.addArrangedSubview(singleButton)

        addDivider()
        addSectionHeader("Future Date")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Restricted to future dates — useful for scheduling. Today can be excluded."))
        let futureButton = LMKButtonFactory.secondary(title: "Pick Future Date", target: self, action: #selector(showFuturePicker))
        stack.addArrangedSubview(futureButton)

        addDivider()
        addSectionHeader("Past Date")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Restricted to past dates — useful for logging events."))
        let pastButton = LMKButtonFactory.secondary(title: "Pick Past Date", target: self, action: #selector(showPastPicker))
        stack.addArrangedSubview(pastButton)

        addDivider()
        addSectionHeader("Date Range")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Two date pickers for From/To selection with live enforcement — dates auto-swap if inverted."))
        let rangeButton = LMKButtonFactory.primary(title: "Pick Date Range", target: self, action: #selector(showRangePicker))
        stack.addArrangedSubview(rangeButton)

        addDivider()
        addSectionHeader("Date with Notes")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Date picker with an embedded text field for adding context."))
        let notesButton = LMKButtonFactory.secondary(title: "Pick Date with Notes", target: self, action: #selector(showDateWithNotes))
        stack.addArrangedSubview(notesButton)
    }

    @objc private func showSinglePicker() {
        LMKDatePickerHelper.presentDatePicker(
            on: self,
            title: "Select Date",
            message: "Choose any date",
            defaultDate: Date()
        ) { [weak self] date in
            guard let self else { return }
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            LMKToast.showSuccess(message: "Selected: \(formatter.string(from: date))", on: self)
        }
    }

    @objc private func showFuturePicker() {
        LMKDatePickerHelper.presentFutureDatePicker(
            on: self,
            title: "Schedule",
            message: "Choose a future date"
        ) { [weak self] date in
            guard let self else { return }
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            LMKToast.showSuccess(message: "Scheduled: \(formatter.string(from: date))", on: self)
        }
    }

    @objc private func showPastPicker() {
        LMKDatePickerHelper.presentPastDatePicker(
            on: self,
            title: "Log Event",
            message: "When did this happen?"
        ) { [weak self] date in
            guard let self else { return }
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            LMKToast.showSuccess(message: "Logged: \(formatter.string(from: date))", on: self)
        }
    }

    @objc private func showRangePicker() {
        LMKDatePickerHelper.presentDateRangePicker(
            on: self,
            title: "Date Range",
            message: "Select a start and end date"
        ) { [weak self] start, end in
            guard let self else { return }
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            LMKToast.showSuccess(message: "\(formatter.string(from: start)) \u{2192} \(formatter.string(from: end))", on: self)
        }
    }

    @objc private func showDateWithNotes() {
        LMKDatePickerHelper.presentDatePickerWithTextField(
            on: self,
            title: "Add Entry",
            message: "Pick a date and add a note",
            defaultDate: Date()
        ) { [weak self] date, text in
            guard let self else { return }
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            let note = text?.isEmpty == false ? text! : "(no note)"
            LMKToast.showSuccess(message: "\(formatter.string(from: date)): \(note)", on: self)
        }
    }
}

// MARK: - User Tip

final class UserTipDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Center Style")
        let centerButton = LMKButton()
        centerButton.setTitle("Show Centered Tip", for: .normal)
        centerButton.setTitleColor(LMKColor.primary, for: .normal)
        centerButton.titleLabel?.font = LMKTypography.bodyMedium
        centerButton.snp.makeConstraints { $0.height.equalTo(LMKLayout.minimumTouchTarget) }
        centerButton.tapHandler = { [weak self] in
            guard let self else { return }
            LMKUserTip.show(
                title: "Did you know?",
                message: "You can long-press any item to see more options. Try it out!",
                icon: UIImage(systemName: "lightbulb"),
                style: .center,
                on: self
            )
        }
        stack.addArrangedSubview(centerButton)

        addDivider()
        addSectionHeader("Pointed Style")

        let targetChip = LMKChipView(text: "Target View", style: .filled)
        stack.addArrangedSubview(targetChip)

        let pointedButton = LMKButton()
        pointedButton.setTitle("Show Pointed Tip", for: .normal)
        pointedButton.setTitleColor(LMKColor.secondary, for: .normal)
        pointedButton.titleLabel?.font = LMKTypography.bodyMedium
        pointedButton.snp.makeConstraints { $0.height.equalTo(LMKLayout.minimumTouchTarget) }
        pointedButton.tapHandler = { [weak self] in
            guard let self else { return }
            LMKUserTip.show(
                message: "This tip points at the target view above",
                style: .pointed(sourceView: targetChip, arrowDirection: .automatic),
                on: self
            )
        }
        stack.addArrangedSubview(pointedButton)

        addDivider()
        addSectionHeader("Message Only")
        let simpleButton = LMKButton()
        simpleButton.setTitle("Show Simple Tip", for: .normal)
        simpleButton.setTitleColor(LMKColor.info, for: .normal)
        simpleButton.titleLabel?.font = LMKTypography.bodyMedium
        simpleButton.snp.makeConstraints { $0.height.equalTo(LMKLayout.minimumTouchTarget) }
        simpleButton.tapHandler = { [weak self] in
            guard let self else { return }
            LMKUserTip.show(
                message: "Swipe down to refresh the list. New items will appear at the top.",
                on: self
            )
        }
        stack.addArrangedSubview(simpleButton)
    }
}

// MARK: - Card Page

final class CardPageDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Basic Card Page")
        stack.addArrangedSubview(LMKLabelFactory.body(text: "Header with back/trailing buttons, configurable strings, and content container. Designed for use inside a UINavigationController with hidden system nav bar."))
        let basicButton = LMKButtonFactory.primary(title: "Show Basic Card Page", target: self, action: #selector(showBasic))
        stack.addArrangedSubview(basicButton)

        addDivider()
        addSectionHeader("Custom Buttons")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Custom leading symbol (xmark), hidden trailing button, and header separator."))
        let customButton = LMKButtonFactory.secondary(title: "Show Custom Buttons", target: self, action: #selector(showCustomButtons))
        stack.addArrangedSubview(customButton)

        addDivider()
        addSectionHeader("No Buttons")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Both buttons hidden — standalone info page with expanded title area."))
        let noButtonsButton = LMKButtonFactory.secondary(title: "Show No Buttons", target: self, action: #selector(showNoButtons))
        stack.addArrangedSubview(noButtonsButton)

        addDivider()
        addSectionHeader("Multi-Page Navigation")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Push/pop content views with slide animation. The back button auto-shows when pages are stacked."))
        let multiPageButton = LMKButtonFactory.primary(title: "Show Multi-Page", target: self, action: #selector(showMultiPage))
        stack.addArrangedSubview(multiPageButton)
    }

    private func presentCardPage(_ page: LMKCardPageController) {
        let nav = UINavigationController(rootViewController: page)
        nav.setNavigationBarHidden(true, animated: false)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }

    @objc private func showBasic() {
        presentCardPage(BasicExampleCardPage(title: "Basic Page"))
    }

    @objc private func showCustomButtons() {
        presentCardPage(CustomButtonsExampleCardPage(title: "Dismiss Page"))
    }

    @objc private func showNoButtons() {
        presentCardPage(NoButtonsExampleCardPage(title: "Info Page"))
    }

    @objc private func showMultiPage() {
        presentCardPage(MultiPageExampleCardPage(title: "Root Page"))
    }
}

// MARK: - Card Page Examples

/// Basic card page with default configuration.
private final class BasicExampleCardPage: LMKCardPageController {
    override func setupContent() {
        let label = LMKLabelFactory.body(text: "This is a basic card page with default header buttons. Tap the back chevron to dismiss, or the trailing button for an action.")
        contentContainerView.addSubview(label)
        label.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(LMKSpacing.large)
        }
    }

    override func leadingButtonTapped() {
        dismiss(animated: true)
    }

    override func trailingButtonTapped() {
        LMKToast.showSuccess(message: "Trailing button tapped!", on: self)
    }
}

/// Custom leading symbol (xmark), no trailing, with separator.
private final class CustomButtonsExampleCardPage: LMKCardPageController {
    override var leadingButtonSymbol: String { "xmark" }
    override var showsTrailingButton: Bool { false }
    override var showsHeaderSeparator: Bool { true }

    override func setupContent() {
        let label = LMKLabelFactory.body(text: "This page uses a custom xmark leading button, hides the trailing button, and shows a header separator line.")
        contentContainerView.addSubview(label)
        label.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(LMKSpacing.large)
        }
    }

    override func leadingButtonTapped() {
        dismiss(animated: true)
    }
}

/// No buttons — standalone info page.
private final class NoButtonsExampleCardPage: LMKCardPageController {
    override var showsLeadingButton: Bool { false }
    override var showsTrailingButton: Bool { false }
    override var showsHeaderSeparator: Bool { true }

    override func setupContent() {
        let label = LMKLabelFactory.body(text: "Both buttons are hidden. The title area expands to full width. Swipe down to dismiss this sheet.")
        contentContainerView.addSubview(label)
        label.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(LMKSpacing.large)
        }
    }
}

/// Multi-page navigation with push/pop.
private final class MultiPageExampleCardPage: LMKCardPageController {
    override var showsHeaderSeparator: Bool { true }

    override func setupContent() {
        let stack = UIStackView(lmk_axis: .vertical, spacing: LMKSpacing.large)

        let label = LMKLabelFactory.body(text: "Tap a button to push a new content page with slide animation. The back button auto-appears for navigation.")
        stack.addArrangedSubview(label)

        let pages = [
            ("Settings", "gearshape", LMKColor.primary),
            ("Profile", "person.circle", LMKColor.secondary),
            ("About", "info.circle", LMKColor.info),
        ]

        for (name, icon, color) in pages {
            let button = LMKButton()
            button.setTitle("Push \(name) Page", for: .normal)
            button.setTitleColor(color, for: .normal)
            button.titleLabel?.font = LMKTypography.bodyMedium
            button.snp.makeConstraints { $0.height.equalTo(LMKLayout.minimumTouchTarget) }
            button.tapHandler = { [weak self] in
                self?.pushPage(title: name, icon: icon)
            }
            stack.addArrangedSubview(button)
        }

        contentContainerView.addSubview(stack)
        stack.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(LMKSpacing.large)
        }
    }

    override func leadingButtonTapped() {
        dismiss(animated: true)
    }

    override func trailingButtonTapped() {
        LMKToast.showSuccess(message: "Copied!", on: self)
    }

    private func pushPage(title: String, icon: String) {
        let contentStack = UIStackView(lmk_axis: .vertical, spacing: LMKSpacing.large)
        contentStack.alignment = .center

        let config = UIImage.SymbolConfiguration(pointSize: 48, weight: .regular)
        let imageView = UIImageView(image: UIImage(systemName: icon, withConfiguration: config))
        imageView.tintColor = LMKColor.primary
        imageView.contentMode = .scaleAspectFit
        contentStack.addArrangedSubview(imageView)

        let label = LMKLabelFactory.body(text: "This is the \(title) page. Tap back to return to the root page with a slide animation.")
        label.textAlignment = .center
        contentStack.addArrangedSubview(label)

        let nestedButton = LMKButton()
        nestedButton.setTitle("Push Another Level", for: .normal)
        nestedButton.setTitleColor(LMKColor.secondary, for: .normal)
        nestedButton.titleLabel?.font = LMKTypography.bodyMedium
        nestedButton.tapHandler = { [weak self] in
            self?.pushNestedPage()
        }
        contentStack.addArrangedSubview(nestedButton)

        let wrapper = UIView()
        wrapper.addSubview(contentStack)
        contentStack.snp.makeConstraints {
            $0.top.equalToSuperview().offset(LMKSpacing.xxl)
            $0.leading.trailing.equalToSuperview().inset(LMKSpacing.large)
        }

        pushContentView(wrapper, title: title)
    }

    private func pushNestedPage() {
        let label = LMKLabelFactory.body(text: "Nested page — multiple levels deep. Each back tap pops one level.")
        label.textAlignment = .center

        let wrapper = UIView()
        wrapper.addSubview(label)
        label.snp.makeConstraints {
            $0.top.equalToSuperview().offset(LMKSpacing.xxl)
            $0.leading.trailing.equalToSuperview().inset(LMKSpacing.large)
        }

        pushContentView(wrapper, title: "Nested")
    }
}

// MARK: - Card Panel

final class CardPanelDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Card Panel")
        stack.addArrangedSubview(LMKLabelFactory.body(text: "A floating card panel that appears above all content. Touches outside the card pass through to views underneath."))
        let basicButton = LMKButtonFactory.primary(title: "Show Card Panel", target: self, action: #selector(showBasicPanel))
        stack.addArrangedSubview(basicButton)

        addDivider()
        addSectionHeader("Panel + Card Page")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Card panel hosting an LMKCardPageController with multi-page navigation inside."))
        let combinedButton = LMKButtonFactory.secondary(title: "Show Combined", target: self, action: #selector(showCombinedPanel))
        stack.addArrangedSubview(combinedButton)
    }

    @objc private func showBasicPanel() {
        guard let window = view.window else { return }
        let content = BasicPanelContentViewController()
        let panel = LMKCardPanelController(rootViewController: content)
        content.panel = panel
        LMKCardPanelController.show(panel, in: window)
    }

    @objc private func showCombinedPanel() {
        guard let window = view.window else { return }
        let page = PanelCardPageExample(title: "Panel Page")
        let panel = LMKCardPanelController(rootViewController: page)
        page.panel = panel
        LMKCardPanelController.show(panel, in: window)
    }
}

/// Simple content inside a card panel.
private final class BasicPanelContentViewController: UIViewController {
    weak var panel: LMKCardPanelController?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = LMKColor.backgroundPrimary

        let stack = UIStackView(lmk_axis: .vertical, spacing: LMKSpacing.large)
        stack.alignment = .center

        let config = UIImage.SymbolConfiguration(pointSize: 48, weight: .regular)
        let imageView = UIImageView(image: UIImage(systemName: "rectangle.inset.filled", withConfiguration: config))
        imageView.tintColor = LMKColor.primary
        imageView.contentMode = .scaleAspectFit
        stack.addArrangedSubview(imageView)

        let label = LMKLabelFactory.body(text: "This is a basic card panel. Tap outside to interact with views behind, or tap dismiss to close.")
        label.textAlignment = .center
        stack.addArrangedSubview(label)

        let dismissButton = LMKButtonFactory.destructive(title: "Dismiss", target: self, action: #selector(dismissPanel))
        stack.addArrangedSubview(dismissButton)

        view.addSubview(stack)
        stack.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(LMKSpacing.large)
        }
    }

    @objc private func dismissPanel() {
        panel?.dismissPanel()
    }
}

/// Card page hosted inside a card panel — combined experience.
private final class PanelCardPageExample: LMKCardPageController {
    weak var panel: LMKCardPanelController?

    override var showsLeadingButton: Bool { false }
    override var showsHeaderSeparator: Bool { true }
    override var trailingButtonSymbol: String { "xmark.circle.fill" }

    override func setupContent() {
        let stack = UIStackView(lmk_axis: .vertical, spacing: LMKSpacing.large)

        let label = LMKLabelFactory.body(text: "Card page inside a card panel. Navigate between pages, and dismiss with the close button.")
        stack.addArrangedSubview(label)

        let pages = [
            ("Settings", "gearshape", LMKColor.primary),
            ("Profile", "person.circle", LMKColor.secondary),
        ]

        for (name, icon, color) in pages {
            let button = LMKButton()
            button.setTitle("Push \(name)", for: .normal)
            button.setTitleColor(color, for: .normal)
            button.titleLabel?.font = LMKTypography.bodyMedium
            button.snp.makeConstraints { $0.height.equalTo(LMKLayout.minimumTouchTarget) }
            button.tapHandler = { [weak self] in
                self?.pushDetailPage(title: name, icon: icon)
            }
            stack.addArrangedSubview(button)
        }

        contentContainerView.addSubview(stack)
        stack.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(LMKSpacing.large)
        }
    }

    override func leadingButtonTapped() {
        panel?.dismissPanel()
    }

    override func trailingButtonTapped() {
        panel?.dismissPanel()
    }

    private func pushDetailPage(title: String, icon: String) {
        let contentStack = UIStackView(lmk_axis: .vertical, spacing: LMKSpacing.large)
        contentStack.alignment = .center

        let config = UIImage.SymbolConfiguration(pointSize: 48, weight: .regular)
        let imageView = UIImageView(image: UIImage(systemName: icon, withConfiguration: config))
        imageView.tintColor = LMKColor.primary
        imageView.contentMode = .scaleAspectFit
        contentStack.addArrangedSubview(imageView)

        let label = LMKLabelFactory.body(text: "This is the \(title) page inside the card panel. Tap back to return.")
        label.textAlignment = .center
        contentStack.addArrangedSubview(label)

        let wrapper = UIView()
        wrapper.addSubview(contentStack)
        contentStack.snp.makeConstraints {
            $0.top.equalToSuperview().offset(LMKSpacing.xxl)
            $0.leading.trailing.equalToSuperview().inset(LMKSpacing.large)
        }

        pushContentView(wrapper, title: title)
    }
}

// MARK: - Floating Button

final class FloatingButtonDetailViewController: DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Floating Button")
        stack.addArrangedSubview(LMKLabelFactory.body(text: "A draggable button that stays on top of all content. Drag it to reposition — it snaps to the nearest edge."))

        let showButton = LMKButtonFactory.primary(title: "Show Floating Button", target: self, action: #selector(showFloating))
        stack.addArrangedSubview(showButton)

        addDivider()
        addSectionHeader("Badge")
        let badgeButton = LMKButton()
        badgeButton.setTitle("Show Badge (count: 5)", for: .normal)
        badgeButton.setTitleColor(LMKColor.error, for: .normal)
        badgeButton.titleLabel?.font = LMKTypography.bodyMedium
        badgeButton.snp.makeConstraints { $0.height.equalTo(LMKLayout.minimumTouchTarget) }
        badgeButton.tapHandler = {
            LMKFloatingButton.current?.showBadge(count: 5)
        }
        stack.addArrangedSubview(badgeButton)

        let dotButton = LMKButton()
        dotButton.setTitle("Show Dot Badge", for: .normal)
        dotButton.setTitleColor(LMKColor.warning, for: .normal)
        dotButton.titleLabel?.font = LMKTypography.bodyMedium
        dotButton.snp.makeConstraints { $0.height.equalTo(LMKLayout.minimumTouchTarget) }
        dotButton.tapHandler = {
            LMKFloatingButton.current?.showBadge()
        }
        stack.addArrangedSubview(dotButton)

        let hideBadgeButton = LMKButton()
        hideBadgeButton.setTitle("Hide Badge", for: .normal)
        hideBadgeButton.setTitleColor(LMKColor.textSecondary, for: .normal)
        hideBadgeButton.titleLabel?.font = LMKTypography.bodyMedium
        hideBadgeButton.snp.makeConstraints { $0.height.equalTo(LMKLayout.minimumTouchTarget) }
        hideBadgeButton.tapHandler = {
            LMKFloatingButton.current?.hideBadge()
        }
        stack.addArrangedSubview(hideBadgeButton)

        addDivider()
        addSectionHeader("Dismiss")
        let dismissButton = LMKButtonFactory.destructive(title: "Dismiss Floating Button", target: self, action: #selector(dismissFloating))
        stack.addArrangedSubview(dismissButton)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        LMKFloatingButton.dismissCurrent()
    }

    @objc private func showFloating() {
        LMKFloatingButton.show(icon: UIImage(systemName: "ladybug")) { [weak self] in
            guard let self else { return }
            LMKToast.showInfo(message: "Floating button tapped!", on: self)
        }
    }

    @objc private func dismissFloating() {
        LMKFloatingButton.dismissCurrent()
    }
}
