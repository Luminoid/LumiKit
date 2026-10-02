//
//  LMKTextInputStyle.swift
//  LumiKit
//
//  Shared vocabulary of the text inputs: the validation state, the style
//  both `LMKTextField` and `LMKTextView` use, the character limit they
//  enforce, and the helper/counter row.
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
    /// Helper line color in the normal and success states; `nil` = `textSecondary`.
    public var helperColor: UIColor?
    /// `nil` = `small`.
    public var counterTextStyle: LMKTextStyle?
    /// `nil` = `textSecondary`.
    public var counterColor: UIColor?
    /// Height floor of the input; `nil` = `minimumTouchTarget` (field) / 100 (view).
    public var minimumHeight: CGFloat?
    /// Growth cap of a text view; `nil` = unlimited.
    public var maximumHeight: CGFloat?
    /// Tint of a text field's clear button; `nil` = `textTertiary`.
    public var clearButtonTint: UIColor?
    /// Per-state overrides (border color and width, background); missing kinds derive from the tokens:
    /// `focused` = `primary`, `warning` = `warning`, `error` = `error`, `success` = `success`.
    public var states: [LMKValidationState.Kind: LMKControlStateStyle]?
    /// The whole input while disabled (`alpha`; `nil` = `alpha.disabled`).
    public var disabled: LMKControlStateStyle?

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
        states: [LMKValidationState.Kind: LMKControlStateStyle]? = nil,
        disabled: LMKControlStateStyle? = nil
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
        self.disabled = disabled
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
            states: other.states.map { (states ?? [:]).merging($0) { LMKControlStateStyle.merge($0, $1) ?? $1 } } ?? states,
            disabled: LMKControlStateStyle.merge(disabled, other.disabled)
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

// MARK: - Character limit

extension LMKTextInputStyle {
    /// The character limit both inputs enforce, in `Character`s (the unit the counter shows).
    /// An edit that fits goes through; one that grows an already full input is refused; a
    /// multi-character insertion that partly fits (a paste, dictation, an autocorrection) goes
    /// through and is trimmed to fit afterwards, so text that was already there is never cut.
    /// Nothing runs while an input method composes marked text.
    nonisolated enum CharacterLimit {
        /// `current` with `ranges` removed and `replacement` inserted at the first of them (the
        /// shape of the iOS 26 multi-range delegate calls), or `nil` for a range past the end.
        static func proposed(_ current: String, replacing ranges: [NSRange], with replacement: String) -> String? {
            let sorted = ranges.sorted { $0.location < $1.location }
            let length = (current as NSString).length
            guard let first = sorted.first, sorted.allSatisfy({ NSMaxRange($0) <= length }) else { return nil }
            let result = NSMutableString(string: current)
            for range in sorted.reversed() {
                result.replaceCharacters(in: range, with: "")
            }
            result.insert(replacement, at: first.location)
            return result as String
        }

        /// Whether the edit may proceed under `limit`: the result fits, it does not grow the text,
        /// or there is room for part of the replacement (`trimmed` cuts the rest afterwards).
        static func allowsChange(in current: String, ranges: [NSRange], replacement: String, limit: Int) -> Bool {
            guard let result = proposed(current, replacing: ranges, with: replacement) else { return true }
            if result.count <= limit || result.count <= current.count { return true }
            guard let remaining = proposed(current, replacing: ranges, with: "") else { return true }
            return remaining.count < limit
        }

        /// `current` with what was inserted since `previous` cut down until the text fits `limit`,
        /// plus the caret offset (in UTF-16 units) right after the kept insertion; `nil` when the
        /// text fits or nothing was inserted (text that was already there is never cut).
        static func trimmed(_ current: String, previous: String, limit: Int) -> (text: String, caretOffset: Int)? {
            let overflow = current.count - limit
            guard overflow > 0 else { return nil }
            let currentCharacters = Array(current)
            let previousCharacters = Array(previous)
            var prefix = 0
            while prefix < currentCharacters.count, prefix < previousCharacters.count, currentCharacters[prefix] == previousCharacters[prefix] {
                prefix += 1
            }
            var suffix = 0
            while suffix < currentCharacters.count - prefix, suffix < previousCharacters.count - prefix,
                  currentCharacters[currentCharacters.count - 1 - suffix] == previousCharacters[previousCharacters.count - 1 - suffix] {
                suffix += 1
            }
            let inserted = currentCharacters.count - prefix - suffix
            guard inserted > 0 else { return nil }
            let head = String(currentCharacters[..<(prefix + max(0, inserted - overflow))])
            let tail = String(currentCharacters[(currentCharacters.count - suffix)...])
            return (head + tail, head.utf16.count)
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

    /// Gap between the message and the counter; the owner sets it from the theme.
    var spacing: CGFloat {
        get { stack.spacing }
        set { stack.spacing = newValue }
    }

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
        stack.addArrangedSubview(messageLabel)
        stack.addArrangedSubview(counterLabel)
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.bottom.trailing.equalToSuperview()
            // A counter alone hugs at required priority: pinned at both edges it would cap the
            // row, and with it the input above, at the counter's width. The leading edge holds
            // just below required, so a message still fills the row and a counter alone sits at
            // the trailing edge.
            make.leading.greaterThanOrEqualToSuperview()
            make.leading.equalToSuperview().priority(.high)
        }
        isHidden = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Whether either label has content.
    var hasContent: Bool { !(messageLabel.isHidden && counterLabel.isHidden) }

    /// Shows `message` (hidden when `nil`) and the `count`/`limit` counter (hidden when `limit` is
    /// `nil`), which VoiceOver reads through `counterAccessibilityLabelFormat` (`%lld of %lld characters`).
    func update(
        message: String?,
        messageColor: UIColor,
        messageStyle: LMKTextStyle,
        count: Int?,
        limit: Int?,
        counterColor: UIColor,
        counterStyle: LMKTextStyle,
        counterAccessibilityLabelFormat: String
    ) {
        messageLabel.lmk_apply(messageStyle, color: messageColor)
        messageLabel.lmk_setText(message)
        messageLabel.isHidden = message?.isEmpty ?? true
        counterLabel.lmk_apply(counterStyle, color: counterColor)
        if let limit, let count {
            let counted = Self.counterFormatter.string(from: NSNumber(value: count)) ?? "\(count)"
            let limited = Self.counterFormatter.string(from: NSNumber(value: limit)) ?? "\(limit)"
            counterLabel.lmk_setText("\(counted)/\(limited)")
            counterLabel.accessibilityLabel = String(format: counterAccessibilityLabelFormat, Int64(count), Int64(limit))
            counterLabel.isHidden = false
        } else {
            counterLabel.lmk_setText(nil)
            counterLabel.accessibilityLabel = nil
            counterLabel.isHidden = true
        }
        isHidden = !hasContent
    }
}
