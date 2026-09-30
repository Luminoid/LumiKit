//
//  LMKTextInputStyle.swift
//  LumiKit
//
//  Shared vocabulary of the text inputs: the validation state, the style
//  both `LMKTextField` and `LMKTextView` use, and the helper/counter row.
//

import SnapKit
import UIKit

// MARK: - Validation state

/// Validation state of a text input.
public nonisolated enum LMKValidationState: Sendable, Equatable {
    case normal
    /// A caution shown in the helper line.
    case warning(String)
    /// A problem shown in the helper line.
    case error(String)
    case success

    /// The state kinds a style can color individually (`focused` is the editing state).
    public nonisolated enum Kind: Sendable, Hashable, CaseIterable {
        case normal, focused, warning, error, success
    }

    public var kind: Kind {
        switch self {
        case .normal: .normal
        case .warning: .warning
        case .error: .error
        case .success: .success
        }
    }

    /// The warning or error message.
    public var message: String? {
        switch self {
        case let .warning(message), let .error(message): message
        case .normal, .success: nil
        }
    }
}

// MARK: - Style

/// Style shared by `LMKTextField` and `LMKTextView` (`theme.textField` / `theme.textView`).
public nonisolated struct LMKTextInputStyle: Sendable, Equatable {
    /// Input surface: background (`backgroundSecondary`), corners (`small`), border (`divider`, 1pt), insets.
    public var surface: LMKSurfaceStyle
    /// `nil` = `body`.
    public var textStyle: LMKTextStyle?
    /// `nil` = `textPrimary`.
    public var textColor: UIColor?
    /// `nil` = `textTertiary`.
    public var placeholderColor: UIColor?
    /// `nil` = `iconSmall`.
    public var iconSize: CGFloat?
    /// `nil` = `textTertiary`.
    public var iconTint: UIColor?
    /// `nil` = `small`.
    public var helperTextStyle: LMKTextStyle?
    /// Helper line color in the normal and success states; `nil` = `textTertiary`.
    public var helperColor: UIColor?
    /// `nil` = `small`.
    public var counterTextStyle: LMKTextStyle?
    /// `nil` = `textTertiary`.
    public var counterColor: UIColor?
    /// Height floor of the input; `nil` = `minimumTouchTarget` (field) / 100 (view).
    public var minimumHeight: CGFloat?
    /// Growth cap of a text view; `nil` = unlimited.
    public var maximumHeight: CGFloat?
    /// `nil` = `textTertiary`.
    public var clearButtonTint: UIColor?
    /// Per-state overrides (border color and width, background); missing kinds derive from the tokens:
    /// `focused` = `primary`, `warning` = `warning`, `error` = `error`, `success` = `success`.
    public var states: [LMKValidationState.Kind: LMKControlStateStyle]?

    public init(
        surface: LMKSurfaceStyle = LMKSurfaceStyle(),
        textStyle: LMKTextStyle? = nil,
        textColor: UIColor? = nil,
        placeholderColor: UIColor? = nil,
        iconSize: CGFloat? = nil,
        iconTint: UIColor? = nil,
        helperTextStyle: LMKTextStyle? = nil,
        helperColor: UIColor? = nil,
        counterTextStyle: LMKTextStyle? = nil,
        counterColor: UIColor? = nil,
        minimumHeight: CGFloat? = nil,
        maximumHeight: CGFloat? = nil,
        clearButtonTint: UIColor? = nil,
        states: [LMKValidationState.Kind: LMKControlStateStyle]? = nil
    ) {
        self.surface = surface
        self.textStyle = textStyle
        self.textColor = textColor
        self.placeholderColor = placeholderColor
        self.iconSize = iconSize
        self.iconTint = iconTint
        self.helperTextStyle = helperTextStyle
        self.helperColor = helperColor
        self.counterTextStyle = counterTextStyle
        self.counterColor = counterColor
        self.minimumHeight = minimumHeight
        self.maximumHeight = maximumHeight
        self.clearButtonTint = clearButtonTint
        self.states = states
    }

    /// `other`'s non-nil fields over this style's.
    public func merging(_ other: Self) -> Self {
        Self(
            surface: surface.merging(other.surface),
            textStyle: other.textStyle ?? textStyle,
            textColor: other.textColor ?? textColor,
            placeholderColor: other.placeholderColor ?? placeholderColor,
            iconSize: other.iconSize ?? iconSize,
            iconTint: other.iconTint ?? iconTint,
            helperTextStyle: other.helperTextStyle ?? helperTextStyle,
            helperColor: other.helperColor ?? helperColor,
            counterTextStyle: other.counterTextStyle ?? counterTextStyle,
            counterColor: other.counterColor ?? counterColor,
            minimumHeight: other.minimumHeight ?? minimumHeight,
            maximumHeight: other.maximumHeight ?? maximumHeight,
            clearButtonTint: other.clearButtonTint ?? clearButtonTint,
            states: other.states.map { (states ?? [:]).merging($0) { LMKControlStateStyle.merge($0, $1) ?? $1 } } ?? states
        )
    }

    /// The tint of `kind` (border and message): the state override's border color, else the token.
    func tint(for kind: LMKValidationState.Kind, defaultBorder: UIColor) -> UIColor {
        if let color = states?[kind]?.border?.color { return color }
        switch kind {
        case .normal: return defaultBorder
        case .focused: return LMKColor.primary
        case .warning: return LMKColor.warning
        case .error: return LMKColor.error
        case .success: return LMKColor.success
        }
    }
}

nonisolated struct LMKTextFieldStyleSlot: LMKThemeExtension {
    static let defaultValue = Self()
    var style = LMKTextInputStyle()
}

nonisolated struct LMKTextViewStyleSlot: LMKThemeExtension {
    static let defaultValue = Self()
    var style = LMKTextInputStyle()
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKTextField`.
    var textField: LMKTextInputStyle {
        get { self[LMKTextFieldStyleSlot.self].style }
        set { self[LMKTextFieldStyleSlot.self].style = newValue }
    }

    /// App-wide default style for `LMKTextView`.
    var textView: LMKTextInputStyle {
        get { self[LMKTextViewStyleSlot.self].style }
        set { self[LMKTextViewStyleSlot.self].style = newValue }
    }
}

// MARK: - Helper row

/// The line under an input: helper or validation message on the leading side, a character
/// counter on the trailing side.
final class LMKTextInputHelperRow: UIView {
    let messageLabel = UILabel()
    let counterLabel = UILabel()
    private static let counterFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    private let stack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        messageLabel.numberOfLines = 0
        // The message takes the width the counter leaves, from constraints: a wrapping label sized
        // by its own content keeps whatever narrow width an early layout pass gave it.
        messageLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        messageLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        counterLabel.textAlignment = .right
        counterLabel.setContentHuggingPriority(.required, for: .horizontal)
        counterLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        stack.axis = .horizontal
        stack.alignment = .top
        stack.spacing = LMKSpacing.small
        stack.addArrangedSubview(messageLabel)
        stack.addArrangedSubview(counterLabel)
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        isHidden = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Whether either label has content.
    var hasContent: Bool { !(messageLabel.isHidden && counterLabel.isHidden) }

    /// Shows `message` (hidden when `nil`) and the `count`/`limit` counter (hidden when `limit` is `nil`).
    func update(message: String?, messageColor: UIColor, messageStyle: LMKTextStyle, count: Int?, limit: Int?, counterColor: UIColor, counterStyle: LMKTextStyle) {
        messageLabel.lmk_apply(messageStyle, color: messageColor)
        messageLabel.lmk_setText(message)
        messageLabel.isHidden = message?.isEmpty ?? true
        counterLabel.lmk_apply(counterStyle, color: counterColor)
        if let limit, let count {
            let counted = Self.counterFormatter.string(from: NSNumber(value: count)) ?? "\(count)"
            let limited = Self.counterFormatter.string(from: NSNumber(value: limit)) ?? "\(limit)"
            counterLabel.lmk_setText("\(counted)/\(limited)")
            counterLabel.isHidden = false
        } else {
            counterLabel.lmk_setText(nil)
            counterLabel.isHidden = true
        }
        isHidden = !hasContent
    }
}
