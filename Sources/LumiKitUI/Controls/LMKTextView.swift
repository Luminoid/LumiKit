//
//  LMKTextView.swift
//  LumiKit
//
//  Multi-line text input with placeholder text support.
//

import SnapKit
import UIKit

/// Multi-line text view with built-in placeholder support.
///
/// ```swift
/// let textView = LMKTextView()
/// textView.placeholder = "Add notes..."
/// textView.text = ""
/// ```
open class LMKTextView: UIView {
    // MARK: - Properties

    /// The underlying text view. Exposed for direct configuration.
    public let textView = UITextView()
    private let placeholderLabel = UILabel()

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

    /// Maximum number of characters. 0 means unlimited.
    public var maxCharacterCount: Int = 0

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
        textView.lmk_applyFormContentPadding()
        textView.delegate = self
        addSubview(textView)
        textView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
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

        isAccessibilityElement = false
    }

    private func updatePlaceholderVisibility() {
        placeholderLabel.isHidden = !(textView.text?.isEmpty ?? true)
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
        if maxCharacterCount > 0 {
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
