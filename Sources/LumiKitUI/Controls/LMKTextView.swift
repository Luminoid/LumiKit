//
//  LMKTextView.swift
//  LumiKit
//
//  Multi-line text input with placeholder text support.
//

import SnapKit
import UIKit

/// Multi-line text view with built-in placeholder, validation states, and border styling.
///
/// ```swift
/// let textView = LMKTextView()
/// textView.placeholder = "Add notes..."
/// textView.validationState = .error("Too short")
/// ```
open class LMKTextView: UIView {
    // MARK: - Properties

    /// The underlying text view. Exposed for direct configuration.
    public let textView = UITextView()
    private let placeholderLabel = UILabel()
    private let helperLabel = UILabel()

    /// Delegate forwarding.
    public weak var delegate: (any UITextViewDelegate)?

    /// Proxied text property.
    public var text: String? {
        get { textView.text }
        set {
            textView.text = newValue
            updatePlaceholderVisibility()
        }
    }

    /// Placeholder text shown when the text view is empty.
    public var placeholder: String? {
        didSet {
            placeholderLabel.text = placeholder
            textView.accessibilityHint = placeholder
        }
    }

    /// Helper text shown below the text view in normal state.
    public var helperText: String? {
        didSet { updateHelperText() }
    }

    /// Current validation state.
    public var validationState: LMKTextFieldState = .normal {
        didSet { updateValidationAppearance() }
    }

    /// Maximum number of characters. `nil` means unlimited.
    public var maxCharacterCount: Int?

    /// Called when text changes via user input.
    public var textChangedHandler: ((String?) -> Void)?

    // MARK: - Initialization

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        textView.font = LMKTypography.body
        textView.textColor = LMKColor.textPrimary
        textView.backgroundColor = LMKColor.backgroundSecondary
        textView.layer.cornerRadius = LMKCornerRadius.small
        textView.layer.borderWidth = 1
        textView.layer.borderColor = LMKColor.divider.cgColor
        textView.lmk_applyFormContentPadding()
        textView.delegate = self
        addSubview(textView)
        textView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        placeholderLabel.font = LMKTypography.body
        placeholderLabel.textColor = LMKColor.textTertiary
        placeholderLabel.numberOfLines = 0
        textView.addSubview(placeholderLabel)
        placeholderLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(
                textView.textContainerInset.left + textView.textContainer.lineFragmentPadding
            )
            make.top.equalToSuperview().offset(textView.textContainerInset.top)
            make.trailing.equalTo(self.snp.trailing).offset(
                -(textView.textContainerInset.right + textView.textContainer.lineFragmentPadding)
            )
        }

        helperLabel.font = LMKTypography.small
        helperLabel.textColor = LMKColor.textTertiary
        helperLabel.numberOfLines = 0
        addSubview(helperLabel)
        helperLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(LMKSpacing.xs)
            make.top.equalTo(textView.snp.bottom).offset(LMKSpacing.xs)
            make.bottom.equalToSuperview()
        }

        isAccessibilityElement = false

        _ = registerForTraitChanges(
            [UITraitUserInterfaceStyle.self, UITraitAccessibilityContrast.self]
        ) { (self: LMKTextView, _: UITraitCollection) in
            self.updateValidationAppearance()
        }
    }

    // MARK: - UI Updates

    private func updatePlaceholderVisibility() {
        placeholderLabel.isHidden = !(textView.text?.isEmpty ?? true)
    }

    private func updateHelperText() {
        switch validationState {
        case .normal, .success:
            helperLabel.text = helperText
            helperLabel.textColor = LMKColor.textTertiary
        case .error(let message):
            helperLabel.text = message
            helperLabel.textColor = LMKColor.error
        }
    }

    private func updateValidationAppearance() {
        switch validationState {
        case .normal:
            textView.layer.borderColor = LMKColor.divider.cgColor
            updateHelperText()
        case .error(let message):
            textView.layer.borderColor = LMKColor.error.cgColor
            helperLabel.text = message
            helperLabel.textColor = LMKColor.error
        case .success:
            textView.layer.borderColor = LMKColor.success.cgColor
            updateHelperText()
        }
    }

    // MARK: - First Responder

    @discardableResult
    override public func becomeFirstResponder() -> Bool { textView.becomeFirstResponder() }

    @discardableResult
    override public func resignFirstResponder() -> Bool { textView.resignFirstResponder() }

    override public var isFirstResponder: Bool { textView.isFirstResponder }
}

// MARK: - UITextViewDelegate

extension LMKTextView: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        updatePlaceholderVisibility()
        textChangedHandler?(textView.text)
        delegate?.textViewDidChange?(textView)
    }

    public func textViewDidBeginEditing(_ textView: UITextView) {
        delegate?.textViewDidBeginEditing?(textView)
    }

    public func textViewDidEndEditing(_ textView: UITextView) {
        delegate?.textViewDidEndEditing?(textView)
    }

    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        delegate?.textViewShouldBeginEditing?(textView) ?? true
    }

    public func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        delegate?.textViewShouldEndEditing?(textView) ?? true
    }

    public func textView(
        _ textView: UITextView,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool {
        if let maxCharacterCount {
            let currentText = (textView.text ?? "") as NSString
            let newLength = currentText.length + (text as NSString).length - range.length
            if newLength > maxCharacterCount {
                return false
            }
        }
        return delegate?.textView?(textView, shouldChangeTextIn: range, replacementText: text) ?? true
    }

    public func textViewDidChangeSelection(_ textView: UITextView) {
        delegate?.textViewDidChangeSelection?(textView)
    }
}
