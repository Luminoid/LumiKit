//
//  LMKLoadingStateView.swift
//  LumiKit
//
//  Loading indicator with an optional message, inline (transparent) or as a
//  dimmed overlay.
//

import SnapKit
import UIKit

/// Loading state view.
///
/// ```swift
/// let loading = LMKLoadingStateView()
/// loading.startLoading(message: "Syncing…")
/// loading.stopLoading()
/// let overlay = LMKLoadingStateView(style: LMKLoadingStateView.Style(presentation: .overlay))
/// ```
public final class LMKLoadingStateView: UIView, LMKThemeApplying {
    // MARK: - Presentation

    public nonisolated enum Presentation: Sendable, Hashable, CaseIterable {
        /// Transparent, sized to its content.
        case inline
        /// Dimmed full-bleed background with a large indicator.
        case overlay
    }

    // MARK: - Style

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// `nil` = `.inline`.
        public var presentation: Presentation?
        /// `nil` = `.medium` inline, `.large` overlay.
        public var indicatorStyle: UIActivityIndicatorView.Style?
        /// `nil` = `primary`.
        public var indicatorColor: UIColor?
        /// `nil` = `body`.
        public var messageTextStyle: LMKTextStyle?
        /// `nil` = `textSecondary`.
        public var messageColor: UIColor?
        /// Overlay background; `nil` = `backgroundPrimary` at `xxl`.
        public var overlayBackground: UIColor?
        /// Gap between indicator and message; `nil` = `medium`.
        public var spacing: CGFloat?
        /// Vertical offset of the indicator from the center; `nil` = `-xl`.
        public var indicatorOffset: CGFloat?

        public init(
            presentation: Presentation? = nil,
            indicatorStyle: UIActivityIndicatorView.Style? = nil,
            indicatorColor: UIColor? = nil,
            messageTextStyle: LMKTextStyle? = nil,
            messageColor: UIColor? = nil,
            overlayBackground: UIColor? = nil,
            spacing: CGFloat? = nil,
            indicatorOffset: CGFloat? = nil
        ) {
            self.presentation = presentation
            self.indicatorStyle = indicatorStyle
            self.indicatorColor = indicatorColor
            self.messageTextStyle = messageTextStyle
            self.messageColor = messageColor
            self.overlayBackground = overlayBackground
            self.spacing = spacing
            self.indicatorOffset = indicatorOffset
        }

        public static let defaultValue = Self()
        public static let inline = Self(presentation: .inline)
        public static let overlay = Self(presentation: .overlay)

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                presentation: other.presentation ?? presentation,
                indicatorStyle: other.indicatorStyle ?? indicatorStyle,
                indicatorColor: other.indicatorColor ?? indicatorColor,
                messageTextStyle: other.messageTextStyle ?? messageTextStyle,
                messageColor: other.messageColor ?? messageColor,
                overlayBackground: other.overlayBackground ?? overlayBackground,
                spacing: other.spacing ?? spacing,
                indicatorOffset: other.indicatorOffset ?? indicatorOffset
            )
        }
    }

    // MARK: - Strings

    public nonisolated struct Strings: Sendable, Equatable {
        /// VoiceOver label while loading without a message.
        public var loadingAccessibilityLabel: String

        public init(loadingAccessibilityLabel: String = LMKLocalized("loadingState.loading.accessibilityLabel")) {
            self.loadingAccessibilityLabel = loadingAccessibilityLabel
        }
    }

    /// Process-wide defaults; set at app launch to override.
    public nonisolated(unsafe) static var strings = Strings()

    /// Per-instance strings (default `Self.strings`).
    public var strings: Strings = LMKLoadingStateView.strings {
        didSet { updateAccessibilityLabel() }
    }

    // MARK: - Properties

    public let activityIndicator = UIActivityIndicatorView(style: .medium)
    public let messageLabel = UILabel()

    /// Per-instance style; `nil` fields resolve from `theme.loadingState`, then the built-in look.
    public var style: Style {
        didSet {
            guard style != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Whether the indicator is animating.
    public private(set) var isLoading = false

    /// The current message (`nil` = indicator only).
    public private(set) var message: String?

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKLoadingStateView) -> Void)?

    private var indicatorOffsetConstraint: Constraint?
    private var messageSpacingConstraint: Constraint?

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

    // MARK: - Setup

    private func setupUI() {
        isAccessibilityElement = true
        accessibilityTraits = .updatesFrequently

        activityIndicator.hidesWhenStopped = true
        addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            indicatorOffsetConstraint = make.centerY.equalToSuperview().offset(0).constraint
        }

        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.isHidden = true
        addSubview(messageLabel)
        messageLabel.snp.makeConstraints { make in
            messageSpacingConstraint = make.top.equalTo(activityIndicator.snp.bottom).offset(0).constraint
            // 999, not required: hosts install this view as a `tableView.backgroundView`, whose
            // autoresizing pass starts at width 0, where required insets would conflict.
            make.leading.trailing.equalToSuperview().inset(LMKSpacing.xl).priority(999)
            make.centerX.equalToSuperview()
        }
    }

    // MARK: - Theme

    public func applyTheme(_ theme: LMKTheme) {
        let resolved = theme.loadingState.merging(style)
        let presentation = resolved.presentation ?? .inline
        backgroundColor = presentation == .overlay ? (resolved.overlayBackground ?? LMKColor.backgroundPrimary.withAlphaComponent(theme.alpha.xxl)) : .clear
        activityIndicator.style = resolved.indicatorStyle ?? (presentation == .overlay ? .large : .medium)
        activityIndicator.color = resolved.indicatorColor ?? LMKColor.primary
        messageLabel.lmk_apply(resolved.messageTextStyle ?? .body, color: resolved.messageColor ?? LMKColor.textSecondary)
        indicatorOffsetConstraint?.update(offset: resolved.indicatorOffset ?? -theme.spacing.xl)
        messageSpacingConstraint?.update(offset: resolved.spacing ?? theme.spacing.medium)
        didApplyStyle?(self)
    }

    // MARK: - Loading

    /// Shows the view and starts the indicator; `message` (when non-empty) appears below it.
    public func startLoading(message: String? = nil) {
        isHidden = false
        isLoading = true
        activityIndicator.startAnimating()
        setMessage(message)
        UIAccessibility.post(notification: .announcement, argument: accessibilityLabel)
    }

    /// Stops the indicator and hides the view.
    public func stopLoading() {
        isLoading = false
        activityIndicator.stopAnimating()
        isHidden = true
    }

    /// Replaces the message (`nil` or empty hides it).
    public func updateMessage(_ message: String?) {
        setMessage(message)
    }

    private func setMessage(_ message: String?) {
        let trimmed = message.flatMap { $0.isEmpty ? nil : $0 }
        self.message = trimmed
        messageLabel.lmk_setText(trimmed)
        messageLabel.isHidden = trimmed == nil
        updateAccessibilityLabel()
    }

    private func updateAccessibilityLabel() {
        accessibilityLabel = message ?? strings.loadingAccessibilityLabel
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKLoadingStateView`.
    var loadingState: LMKLoadingStateView.Style {
        get { self[LMKLoadingStateView.Style.self] }
        set { self[LMKLoadingStateView.Style.self] = newValue }
    }
}
