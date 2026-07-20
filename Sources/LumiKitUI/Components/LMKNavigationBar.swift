import SnapKit
import UIKit

/// A bar button item for ``LMKNavigationBar``.
public struct LMKNavigationBarItem {
    public let image: UIImage?
    public let title: String?
    public let accessibilityLabel: String?
    public let action: () -> Void

    public init(
        image: UIImage?,
        title: String? = nil,
        accessibilityLabel: String? = nil,
        action: @escaping () -> Void
    ) {
        self.image = image
        self.title = title
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    public init(
        systemName: String,
        accessibilityLabel: String? = nil,
        action: @escaping () -> Void
    ) {
        self.image = UIImage(systemName: systemName)
        self.title = nil
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    public init(
        title: String,
        accessibilityLabel: String? = nil,
        action: @escaping () -> Void
    ) {
        self.image = nil
        self.title = title
        self.accessibilityLabel = accessibilityLabel ?? title
        self.action = action
    }
}

/// Custom navigation bar with design-token styling.
///
/// Supports two display modes matching Apple's navigation bar patterns:
///
/// **Large title mode** (root screens):
/// ```
/// ┌──────────────────────────────┐
/// │  (status bar area)           │
/// ├──────────────────────────────┤
/// │  [←]                  [+][⋯] │  ← 44pt button row
/// │  Page Title                   │  ← 52pt large title row
/// ├──────────────────────────────┤
/// │  ── separator ──             │
/// └──────────────────────────────┘
/// ```
///
/// **Standard mode** (pushed screens):
/// ```
/// ┌──────────────────────────────┐
/// │  (status bar area)           │
/// ├──────────────────────────────┤
/// │  [←]    Page Title    [+][⋯] │  ← 44pt centered title
/// ├──────────────────────────────┤
/// │  ── separator ──             │
/// └──────────────────────────────┘
/// ```
///
/// Usage:
/// ```swift
/// navigationController?.setNavigationBarHidden(true, animated: false)
///
/// let navBar = LMKNavigationBar()
/// navBar.title = "Items"
/// navBar.largeTitleEnabled = true
/// navBar.setRightItems([.init(systemName: "plus") { self.addTapped() }])
/// view.addSubview(navBar)
/// navBar.pinToTop(of: view)
/// ```
public final class LMKNavigationBar: UIView {
    // MARK: - Constants

    private static let buttonRowHeight: CGFloat = 44
    private static let largeTitleRowHeight: CGFloat = 52
    private static let buttonSize: CGFloat = 44
    private static let contentMargin: CGFloat = 16
    private static let backChevronLeading: CGFloat = 8

    // MARK: - Public Properties

    /// The title displayed in the bar.
    public var title: String? {
        didSet {
            inlineTitleLabel.text = title
            largeTitleLabel.text = title
        }
    }

    /// Enable large title mode (bold, left-aligned, separate row). Default `false`.
    public var largeTitleEnabled: Bool = false {
        didSet {
            largeTitleRow.isHidden = !largeTitleEnabled
            inlineTitleLabel.isHidden = largeTitleEnabled
            updateBottomConstraint()
        }
    }

    /// Whether the back button is visible.
    public var showsBackButton: Bool = false {
        didSet { backButton.isHidden = !showsBackButton }
    }

    /// Override the default back action (pop navigation controller).
    public var backAction: (() -> Void)?

    // MARK: - Appearance

    public var barBackgroundColor: UIColor = LMKColor.backgroundPrimary {
        didSet { backgroundColor = barBackgroundColor }
    }

    public var largeTitleFont: UIFont = .systemFont(ofSize: 34, weight: .bold) {
        didSet { largeTitleLabel.font = largeTitleFont }
    }

    public var largeTitleColor: UIColor = LMKColor.textPrimary {
        didSet { largeTitleLabel.textColor = largeTitleColor }
    }

    public var inlineTitleFont: UIFont = .systemFont(ofSize: 17, weight: .semibold) {
        didSet { inlineTitleLabel.font = inlineTitleFont }
    }

    public var inlineTitleColor: UIColor = LMKColor.textPrimary {
        didSet { inlineTitleLabel.textColor = inlineTitleColor }
    }

    public var buttonTintColor: UIColor = LMKColor.primary {
        didSet {
            backButton.tintColor = buttonTintColor
            leftItemsStack.arrangedSubviews.forEach { $0.tintColor = buttonTintColor }
            rightItemsStack.arrangedSubviews.forEach { $0.tintColor = buttonTintColor }
        }
    }

    public var showsSeparator: Bool = true {
        didSet { separatorView.isHidden = !showsSeparator }
    }

    // MARK: - UI Components

    /// The 44pt row containing back button, inline title, and right items.
    private lazy var buttonRow: UIView = .init()

    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
        button.setImage(UIImage(systemName: "chevron.backward", withConfiguration: config), for: .normal)
        button.tintColor = buttonTintColor
        button.isPointerInteractionEnabled = true
        button.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        button.isHidden = true
        button.accessibilityLabel = "Back"
        return button
    }()

    private lazy var leftItemsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = LMKSpacing.xs
        stack.alignment = .center
        stack.isHidden = true
        return stack
    }()

    /// Centered title for standard (non-large) mode.
    private lazy var inlineTitleLabel: UILabel = {
        let label = UILabel()
        label.font = inlineTitleFont
        label.textColor = inlineTitleColor
        label.textAlignment = .center
        return label
    }()

    private lazy var rightItemsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = LMKSpacing.xs
        stack.alignment = .center
        return stack
    }()

    /// The 52pt row for the large title.
    private lazy var largeTitleRow: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()

    private lazy var largeTitleLabel: UILabel = {
        let label = UILabel()
        label.font = largeTitleFont
        label.textColor = largeTitleColor
        return label
    }()

    private lazy var separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = LMKColor.divider
        return view
    }()

    private var leftItemActions: [() -> Void] = []
    private var rightItemActions: [() -> Void] = []
    private weak var rightAccessoryView: UIView?
    private weak var largeTitleAccessoryView: UIView?

    // MARK: - Initialization

    public init() {
        super.init(frame: .zero)
        setupUI()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _: UITraitCollection) in
            self.refreshColors()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public API

    /// Set the left bar button items. When set, hides the back button.
    public func setLeftItems(_ items: [LMKNavigationBarItem]) {
        leftItemsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        leftItemActions = items.map(\.action)

        backButton.isHidden = true
        leftItemsStack.isHidden = items.isEmpty

        for (index, item) in items.enumerated() {
            let button = UIButton(type: .system)
            if let image = item.image {
                button.setImage(image, for: .normal)
            } else if let title = item.title {
                button.setTitle(title, for: .normal)
                button.titleLabel?.font = LMKTypography.body
            }
            button.tintColor = buttonTintColor
            button.isPointerInteractionEnabled = true
            button.tag = index
            button.addTarget(self, action: #selector(leftItemTapped(_:)), for: .touchUpInside)
            button.accessibilityLabel = item.accessibilityLabel ?? item.title
            button.snp.makeConstraints { $0.height.greaterThanOrEqualTo(Self.buttonSize) }
            leftItemsStack.addArrangedSubview(button)
        }
    }

    /// Set the right bar button items.
    public func setRightItems(_ items: [LMKNavigationBarItem]) {
        rightItemsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        rightItemActions = items.map(\.action)

        for (index, item) in items.enumerated() {
            let button = UIButton(type: .system)
            if let image = item.image {
                button.setImage(image, for: .normal)
            } else if let title = item.title {
                button.setTitle(title, for: .normal)
                button.titleLabel?.font = LMKTypography.body
            }
            button.tintColor = buttonTintColor
            button.isPointerInteractionEnabled = true
            button.tag = index
            button.addTarget(self, action: #selector(rightItemTapped(_:)), for: .touchUpInside)
            button.accessibilityLabel = item.accessibilityLabel ?? item.title
            button.snp.makeConstraints { $0.width.height.greaterThanOrEqualTo(Self.buttonSize) }
            rightItemsStack.addArrangedSubview(button)
        }
    }

    /// Pin the navigation bar to the top of a view (leading, trailing, top edges).
    public func pinToTop(of parentView: UIView) {
        snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
    }

    /// Toggle the enabled state of the right bar button at the given index.
    /// Disabled items render at reduced opacity and stop firing their action.
    public func setRightItemEnabled(at index: Int, _ enabled: Bool) {
        guard index >= 0, index < rightItemsStack.arrangedSubviews.count,
              let button = rightItemsStack.arrangedSubviews[index] as? UIButton
        else { return }
        button.isEnabled = enabled
        button.alpha = enabled ? 1.0 : LMKAlpha.disabled
    }

    /// Toggle the enabled state of the left bar button at the given index.
    public func setLeftItemEnabled(at index: Int, _ enabled: Bool) {
        guard index >= 0, index < leftItemsStack.arrangedSubviews.count,
              let button = leftItemsStack.arrangedSubviews[index] as? UIButton
        else { return }
        button.isEnabled = enabled
        button.alpha = enabled ? 1.0 : LMKAlpha.disabled
    }

    /// Place a non-tappable accessory view (e.g. activity indicator, sync
    /// status icon) immediately to the left of the right bar items, vertically
    /// centered with the button row. Pass `nil` to remove the existing
    /// accessory. The accessory lives outside `rightItemsStack` so calling
    /// `setRightItems(_:)` afterward does not disturb it.
    public func setRightAccessoryView(_ view: UIView?) {
        rightAccessoryView?.removeFromSuperview()
        rightAccessoryView = view
        guard let view else { return }
        addSubview(view)
        view.snp.makeConstraints { make in
            make.centerY.equalTo(rightItemsStack)
            make.trailing.equalTo(rightItemsStack.snp.leading).offset(-LMKSpacing.small)
        }
    }

    /// Place a non-tappable accessory view immediately to the right of the
    /// large title text — the iOS Mail / Notes pattern for surfacing
    /// background activity (sync, refresh) inline with the section title.
    /// Only meaningful when `largeTitleEnabled = true`. Pass `nil` to remove.
    /// The label's `.required` content-hugging priority means the accessory
    /// hangs off the actual text trailing, not the full row width.
    public func setLargeTitleAccessoryView(_ view: UIView?) {
        largeTitleAccessoryView?.removeFromSuperview()
        largeTitleAccessoryView = view
        guard let view else { return }
        largeTitleRow.addSubview(view)
        view.snp.makeConstraints { make in
            make.leading.equalTo(largeTitleLabel.snp.trailing).offset(LMKSpacing.small)
            make.centerY.equalTo(largeTitleLabel)
            make.trailing.lessThanOrEqualToSuperview().offset(-Self.contentMargin)
        }
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = barBackgroundColor

        // Button row (44pt)
        addSubview(buttonRow)
        buttonRow.addSubview(backButton)
        buttonRow.addSubview(leftItemsStack)
        buttonRow.addSubview(inlineTitleLabel)
        buttonRow.addSubview(rightItemsStack)

        buttonRow.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(Self.buttonRowHeight)
        }

        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Self.backChevronLeading)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(Self.buttonSize)
        }

        leftItemsStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Self.contentMargin)
            make.centerY.equalToSuperview()
        }

        rightItemsStack.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(Self.contentMargin)
            make.centerY.equalToSuperview()
        }

        // Inline title: centered between back button and right items
        inlineTitleLabel.snp.makeConstraints { make in
            // centerX must YIELD to the right-items stack: with 4+ bar items the
            // stack's leading edge can cross the bar's center, so a required centerX
            // could not also satisfy `trailing <= rightItemsStack.leading` and UIKit
            // recovered by breaking a button's 44pt min width. High (not required)
            // lets the title shift left / truncate while buttons keep their targets.
            make.centerX.equalToSuperview().priority(.high)
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(backButton.snp.trailing).offset(LMKSpacing.small)
            make.leading.greaterThanOrEqualTo(leftItemsStack.snp.trailing).offset(LMKSpacing.small)
            make.trailing.lessThanOrEqualTo(rightItemsStack.snp.leading).offset(-LMKSpacing.small)
        }

        // Large title row (52pt)
        addSubview(largeTitleRow)
        largeTitleRow.addSubview(largeTitleLabel)

        largeTitleRow.snp.makeConstraints { make in
            make.top.equalTo(buttonRow.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(Self.largeTitleRowHeight)
        }

        largeTitleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Self.contentMargin)
            // Allow shrink when an accessory view is present, but still
            // bound by the row's trailing edge for long titles.
            make.trailing.lessThanOrEqualToSuperview().offset(-Self.contentMargin)
            make.centerY.equalToSuperview()
        }
        largeTitleLabel.setContentHuggingPriority(.required, for: .horizontal)

        // Separator
        addSubview(separatorView)
        separatorView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(1.0 / UIScreen.main.scale)
            make.bottom.equalToSuperview()
        }

        // Bottom constraint: separator below the last visible row
        updateBottomConstraint()
    }

    private func updateBottomConstraint() {
        separatorView.snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(1.0 / UIScreen.main.scale)
            if largeTitleEnabled {
                make.top.equalTo(largeTitleRow.snp.bottom)
            } else {
                make.top.equalTo(buttonRow.snp.bottom)
            }
            make.bottom.equalToSuperview()
        }
    }

    private func refreshColors() {
        backgroundColor = barBackgroundColor
        inlineTitleLabel.textColor = inlineTitleColor
        largeTitleLabel.textColor = largeTitleColor
        backButton.tintColor = buttonTintColor
        leftItemsStack.arrangedSubviews.forEach { $0.tintColor = buttonTintColor }
        rightItemsStack.arrangedSubviews.forEach { $0.tintColor = buttonTintColor }
        separatorView.backgroundColor = LMKColor.divider
    }

    // MARK: - Actions

    @objc private func backTapped() {
        if let backAction {
            backAction()
        } else {
            findNavigationController()?.popViewController(animated: true)
        }
    }

    @objc private func leftItemTapped(_ sender: UIButton) {
        guard sender.tag < leftItemActions.count else { return }
        leftItemActions[sender.tag]()
    }

    @objc private func rightItemTapped(_ sender: UIButton) {
        guard sender.tag < rightItemActions.count else { return }
        rightItemActions[sender.tag]()
    }

    // MARK: - Helpers

    private func findNavigationController() -> UINavigationController? {
        var responder: UIResponder? = self
        while let next = responder?.next {
            if let nav = next as? UINavigationController {
                return nav
            }
            responder = next
        }
        return nil
    }
}
