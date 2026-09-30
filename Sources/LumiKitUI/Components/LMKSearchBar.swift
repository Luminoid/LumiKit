//
//  LMKSearchBar.swift
//  LumiKit
//
//  Search bar: magnifying glass, text field, clear button, and a cancel
//  button that appears while editing. Closure-driven; height is a Dynamic
//  Type floor.
//

import SnapKit
import UIKit

/// Search bar matching the native minimal style.
///
/// ```swift
/// let searchBar = LMKSearchBar()
/// searchBar.placeholder = "Search plants"
/// searchBar.onTextChange = { query in filter(query) }
/// searchBar.debounceInterval = 0.3
/// searchBar.onDebouncedTextChange = { query in search(query) }
/// ```
public final class LMKSearchBar: UIView, LMKThemeApplying {
    // MARK: - Cancel button

    /// When the cancel button shows.
    public nonisolated enum CancelButtonMode: Sendable, Hashable, CaseIterable {
        /// While the field is being edited (the default).
        case automatic
        case always
        case never
    }

    // MARK: - Style

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// Field surface: background (`backgroundTertiary`), corners (`medium`), insets (`medium` / `small`).
        public var surface: LMKSurfaceStyle
        /// `nil` = `textTertiary`.
        public var iconTint: UIColor?
        /// `nil` = 18.
        public var iconSize: CGFloat?
        /// `nil` = `body`.
        public var textStyle: LMKTextStyle?
        /// `nil` = `textPrimary`.
        public var textColor: UIColor?
        /// `nil` = `textTertiary`.
        public var placeholderColor: UIColor?
        /// `nil` = `textTertiary`.
        public var clearButtonTint: UIColor?
        /// `nil` = 22.
        public var clearButtonSize: CGFloat?
        /// Style of the cancel button; `nil` = ghost primary.
        public var cancelButton: LMKButton.Style?
        /// Height floor of the field; `nil` = 36 (grows with Dynamic Type).
        public var height: CGFloat?
        /// Gap between icon, field, and buttons; `nil` = `small`.
        public var spacing: CGFloat?

        public init(
            surface: LMKSurfaceStyle = LMKSurfaceStyle(),
            iconTint: UIColor? = nil,
            iconSize: CGFloat? = nil,
            textStyle: LMKTextStyle? = nil,
            textColor: UIColor? = nil,
            placeholderColor: UIColor? = nil,
            clearButtonTint: UIColor? = nil,
            clearButtonSize: CGFloat? = nil,
            cancelButton: LMKButton.Style? = nil,
            height: CGFloat? = nil,
            spacing: CGFloat? = nil
        ) {
            self.surface = surface
            self.iconTint = iconTint
            self.iconSize = iconSize
            self.textStyle = textStyle
            self.textColor = textColor
            self.placeholderColor = placeholderColor
            self.clearButtonTint = clearButtonTint
            self.clearButtonSize = clearButtonSize
            self.cancelButton = cancelButton
            self.height = height
            self.spacing = spacing
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                surface: surface.merging(other.surface),
                iconTint: other.iconTint ?? iconTint,
                iconSize: other.iconSize ?? iconSize,
                textStyle: other.textStyle ?? textStyle,
                textColor: other.textColor ?? textColor,
                placeholderColor: other.placeholderColor ?? placeholderColor,
                clearButtonTint: other.clearButtonTint ?? clearButtonTint,
                clearButtonSize: other.clearButtonSize ?? clearButtonSize,
                cancelButton: other.cancelButton.map { cancelButton?.merging($0) ?? $0 } ?? cancelButton,
                height: other.height ?? height,
                spacing: other.spacing ?? spacing
            )
        }
    }

    // MARK: - Strings

    public nonisolated struct Strings: Sendable, Equatable {
        public var cancel: String
        public var clearAccessibilityLabel: String

        public init(cancel: String = LMKLocalized("searchBar.cancel"), clearAccessibilityLabel: String = LMKLocalized("searchBar.clear.accessibilityLabel")) {
            self.cancel = cancel
            self.clearAccessibilityLabel = clearAccessibilityLabel
        }
    }

    /// Process-wide defaults; set at app launch to override.
    public nonisolated(unsafe) static var strings = Strings()

    /// Per-instance strings (default `Self.strings`).
    public var strings: Strings = LMKSearchBar.strings {
        didSet { applyStrings() }
    }

    // MARK: - Callbacks

    /// Every keystroke and clear.
    public var onTextChange: ((String) -> Void)?
    /// Return key.
    public var onSearch: ((String) -> Void)?
    public var onBeginEditing: (() -> Void)?
    public var onEndEditing: (() -> Void)?
    /// The cancel button (the field is cleared and resigned first).
    public var onCancel: (() -> Void)?
    /// `onTextChange` coalesced by `debounceInterval`.
    public var onDebouncedTextChange: ((String) -> Void)?

    /// Seconds to wait after the last keystroke before `onDebouncedTextChange`; `nil` disables it.
    public var debounceInterval: TimeInterval?

    // MARK: - State

    /// The wrapped text field, for keyboard type, return key, and content type. Its hit area is
    /// at least `minimumTouchTarget` tall even though the bar draws at its 36pt floor.
    public let textField: UITextField = LMKHitExpandingTextField()
    public let containerView = UIView()
    public let iconView = UIImageView()
    public let clearButton = LMKButton(style: .iconOnly(.neutral).size(.small))
    public let cancelButton = LMKButton(style: .ghost())

    public var placeholder: String? {
        didSet { applyPlaceholder() }
    }

    public var text: String? {
        get { textField.text }
        set {
            textField.text = newValue
            updateClearButtonVisibility()
        }
    }

    /// When the cancel button shows. Default `.automatic`.
    public var cancelButtonMode: CancelButtonMode = .automatic {
        didSet { updateCancelButton(animated: false) }
    }

    /// Whether the cancel button is currently shown.
    public var showsCancelButton: Bool { !cancelButton.isHidden }

    /// Per-instance style; `nil` fields resolve from `theme.searchBar`, then the built-in look.
    public var style: Style {
        didSet {
            guard style != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKSearchBar) -> Void)?

    private var resolved = Style()
    private var heightConstraint: Constraint?
    private var iconSizeConstraint: Constraint?
    private var clearSizeConstraint: Constraint?
    private var cancelSpacingConstraint: Constraint?
    private var cancelWidthConstraint: Constraint?
    private var debounceTask: Task<Void, Never>?
    private var isEditing = false
    private static let defaultHeight: CGFloat = 36
    private static let defaultIconSize: CGFloat = 18
    private static let defaultClearButtonSize: CGFloat = 22

    // MARK: - Initialization

    public init(style: Style = Style()) {
        self.style = style
        super.init(frame: .zero)
        setupUI()
        lmk_startApplyingTheme()
    }

    override public convenience init(frame: CGRect) {
        self.init(style: Style())
        self.frame = frame
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        debounceTask?.cancel()
    }

    // MARK: - Setup

    private func setupUI() {
        iconView.image = UIImage(systemName: "magnifyingglass")
        iconView.contentMode = .scaleAspectFit
        iconView.setContentHuggingPriority(.required, for: .horizontal)

        textField.returnKeyType = .search
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.clearButtonMode = .never
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

        clearButton.setSymbol("xmark.circle.fill")
        clearButton.isHidden = true
        clearButton.onTap = { [weak self] in self?.clearButtonTapped() }

        cancelButton.isHidden = true
        cancelButton.setContentHuggingPriority(.required, for: .horizontal)
        cancelButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        cancelButton.onTap = { [weak self] in self?.cancelButtonTapped() }

        addSubview(containerView)
        containerView.addSubview(iconView)
        containerView.addSubview(textField)
        containerView.addSubview(clearButton)
        addSubview(cancelButton)

        containerView.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            heightConstraint = make.height.greaterThanOrEqualTo(Self.defaultHeight).constraint
        }
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(0)
            make.centerY.equalToSuperview()
            iconSizeConstraint = make.width.height.equalTo(Self.defaultIconSize).constraint
        }
        textField.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.trailing.equalTo(clearButton.snp.leading)
            make.leading.equalTo(iconView.snp.trailing)
        }
        clearButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(0)
            make.centerY.equalToSuperview()
            clearSizeConstraint = make.width.height.equalTo(Self.defaultClearButtonSize).constraint
        }
        cancelButton.snp.makeConstraints { make in
            cancelSpacingConstraint = make.leading.equalTo(containerView.snp.trailing).offset(0).constraint
            make.centerY.equalToSuperview()
            cancelWidthConstraint = make.width.equalTo(0).constraint
            make.trailing.equalToSuperview()
        }
        applyStrings()
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        containerView.lmk_layoutSurfaceIfNeeded()
    }

    private func applyStrings() {
        cancelButton.title = strings.cancel
        clearButton.accessibilityLabel = strings.clearAccessibilityLabel
        updateCancelButton(animated: false)
    }

    private func applyPlaceholder() {
        textField.attributedPlaceholder = placeholder.map {
            NSAttributedString(string: $0, attributes: [.foregroundColor: resolved.placeholderColor ?? LMKColor.textTertiary])
        }
    }

    // MARK: - Theme

    public func applyTheme(_ theme: LMKTheme) {
        resolved = theme.searchBar.merging(style)
        let defaults = LMKSurfaceStyle(
            background: .solid(LMKColor.backgroundTertiary),
            corners: .fixed(theme.cornerRadius.medium),
            shadow: LMKShadowSource.none,
            contentInsets: .lmk_symmetric(vertical: 0, horizontal: theme.spacing.medium)
        )
        let applied = containerView.lmk_apply(surface: resolved.surface, defaults: defaults)
        let insets = applied.contentInsets ?? .lmk_symmetric(vertical: 0, horizontal: theme.spacing.medium)
        let spacing = resolved.spacing ?? theme.spacing.small
        iconView.snp.updateConstraints { $0.leading.equalToSuperview().offset(insets.leading) }
        clearButton.snp.updateConstraints { $0.trailing.equalToSuperview().offset(-insets.trailing + theme.spacing.xs) }
        textField.snp.updateConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(spacing)
            make.trailing.equalTo(clearButton.snp.leading).offset(-theme.spacing.xs)
        }
        cancelSpacingConstraint?.update(offset: spacing)

        iconView.tintColor = resolved.iconTint ?? LMKColor.textTertiary
        iconSizeConstraint?.update(offset: resolved.iconSize ?? Self.defaultIconSize)
        textField.lmk_apply(resolved.textStyle ?? .body, color: resolved.textColor ?? LMKColor.textPrimary)
        applyPlaceholder()
        clearButton.style = LMKButton.Style.iconOnly(.neutral).size(.small).tint(resolved.clearButtonTint ?? LMKColor.textTertiary)
        clearSizeConstraint?.update(offset: resolved.clearButtonSize ?? Self.defaultClearButtonSize)
        cancelButton.style = resolved.cancelButton ?? .ghost()
        let lineHeight = ceil(theme.typography.font(for: resolved.textStyle ?? .body, compatibleWith: traitCollection).lineHeight) + theme.spacing.small
        heightConstraint?.update(offset: max(resolved.height ?? Self.defaultHeight, lineHeight))
        updateCancelButton(animated: false)
        didApplyStyle?(self)
    }

    // MARK: - First responder

    @discardableResult
    override public func becomeFirstResponder() -> Bool {
        textField.becomeFirstResponder()
    }

    @discardableResult
    override public func resignFirstResponder() -> Bool {
        textField.resignFirstResponder()
    }

    override public var canBecomeFirstResponder: Bool { textField.canBecomeFirstResponder }
    override public var isFirstResponder: Bool { textField.isFirstResponder }

    // MARK: - Updates

    private func updateClearButtonVisibility() {
        clearButton.isHidden = textField.text?.isEmpty ?? true
    }

    private func updateCancelButton(animated: Bool) {
        let shows = switch cancelButtonMode {
        case .automatic: isEditing
        case .always: true
        case .never: false
        }
        cancelButton.isHidden = !shows
        cancelButton.layoutIfNeeded()
        cancelWidthConstraint?.update(offset: shows ? cancelButton.intrinsicContentSize.width : 0)
        cancelSpacingConstraint?.update(offset: shows ? (resolved.spacing ?? traitCollection.lmkTheme.spacing.small) : 0)
        guard animated, LMKAnimation.shouldAnimate, window != nil else { return }
        UIView.animate(withDuration: LMKAnimation.Duration.normal) { [weak self] in self?.layoutIfNeeded() }
    }

    private func scheduleDebounce(_ text: String) {
        debounceTask?.cancel()
        guard let debounceInterval, let onDebouncedTextChange else { return }
        debounceTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(debounceInterval))
            guard !Task.isCancelled, self != nil else { return }
            onDebouncedTextChange(text)
        }
    }

    // MARK: - Actions

    @objc private func textFieldDidChange() {
        updateClearButtonVisibility()
        let text = textField.text ?? ""
        onTextChange?(text)
        scheduleDebounce(text)
    }

    private func clearButtonTapped() {
        textField.text = ""
        updateClearButtonVisibility()
        onTextChange?("")
        scheduleDebounce("")
    }

    private func cancelButtonTapped() {
        textField.text = ""
        textField.resignFirstResponder()
        updateClearButtonVisibility()
        isEditing = false
        updateCancelButton(animated: true)
        onCancel?()
    }
}

// MARK: - UITextFieldDelegate

extension LMKSearchBar: UITextFieldDelegate {
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        isEditing = true
        updateCancelButton(animated: true)
        onBeginEditing?()
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        isEditing = false
        updateCancelButton(animated: true)
        onEndEditing?()
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        onSearch?(textField.text ?? "")
        return true
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKSearchBar`.
    var searchBar: LMKSearchBar.Style {
        get { self[LMKSearchBar.Style.self] }
        set { self[LMKSearchBar.Style.self] = newValue }
    }
}
