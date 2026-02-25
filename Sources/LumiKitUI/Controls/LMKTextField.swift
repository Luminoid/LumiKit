//
//  LMKTextField.swift
//  LumiKit
//
//  Full-featured text field with icon, placeholder, validation states, and helper text.
//

import SnapKit
import UIKit

/// Validation state for the text field.
public enum LMKTextFieldState {
    /// Normal state with default border.
    case normal
    /// Error state with red border and error message.
    case error(String)
    /// Success state with green border.
    case success
}

/// Text field with leading icon, validation states, and helper or error text below.
///
/// ```swift
/// let field = LMKTextField()
/// field.placeholder = "Email"
/// field.leadingIcon = UIImage(systemName: "envelope")
/// field.helperText = "We'll never share your email."
/// field.validationState = .error("Invalid email format")
/// ```
open class LMKTextField: UIView {
    // MARK: - Properties

    /// The underlying text field. Exposed for direct configuration.
    public let textField = UITextField()
    private let containerView = UIView()
    private let leadingIconView = UIImageView()
    private let helperLabel = UILabel()
    private var leadingIconConstraint: Constraint?
    private var traitChangeRegistration: (any UITraitChangeRegistration)?

    /// Delegate forwarding.
    public weak var delegate: (any UITextFieldDelegate)? {
        get { textField.delegate }
        set { textField.delegate = newValue }
    }

    /// Proxied text property.
    public var text: String? {
        get { textField.text }
        set { textField.text = newValue }
    }

    /// Placeholder text.
    public var placeholder: String? {
        didSet {
            textField.attributedPlaceholder = placeholder.map {
                NSAttributedString(string: $0, attributes: [.foregroundColor: LMKColor.textTertiary])
            }
        }
    }

    /// Leading icon image.
    public var leadingIcon: UIImage? {
        didSet {
            leadingIconView.image = leadingIcon
            leadingIconView.isHidden = leadingIcon == nil
            updateLeadingConstraint()
        }
    }

    /// Helper text shown below the field in normal state.
    public var helperText: String? {
        didSet { updateHelperText() }
    }

    /// Current validation state.
    public var validationState: LMKTextFieldState = .normal {
        didSet { updateValidationAppearance() }
    }

    /// Called when text changes via user input.
    public var textChangedHandler: ((String?) -> Void)?

    /// Maximum number of characters. `nil` means unlimited.
    public var maxCharacterCount: Int?

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
        // Container (border + background)
        containerView.backgroundColor = LMKColor.backgroundSecondary
        containerView.layer.cornerRadius = LMKCornerRadius.small
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = LMKColor.divider.cgColor
        addSubview(containerView)

        // Leading icon
        leadingIconView.contentMode = .scaleAspectFit
        leadingIconView.tintColor = LMKColor.textTertiary
        leadingIconView.isHidden = true
        containerView.addSubview(leadingIconView)

        // Text field
        textField.font = LMKTypography.body
        textField.textColor = LMKColor.textPrimary
        textField.lmk_applyFormContentPadding()
        containerView.addSubview(textField)

        // Helper/error label
        helperLabel.font = LMKTypography.small
        helperLabel.textColor = LMKColor.textTertiary
        helperLabel.numberOfLines = 0
        helperLabel.isHidden = true
        addSubview(helperLabel)

        // Layout
        containerView.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.height.greaterThanOrEqualTo(LMKLayout.minimumTouchTarget)
        }

        leadingIconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(LMKSpacing.medium)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(LMKLayout.iconSmall)
        }

        textField.snp.makeConstraints { make in
            self.leadingIconConstraint = make.leading.equalToSuperview().offset(LMKSpacing.medium).constraint
            make.trailing.equalToSuperview().offset(-LMKSpacing.medium)
            make.top.bottom.equalToSuperview()
        }

        helperLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(LMKSpacing.xs)
            make.top.equalTo(containerView.snp.bottom).offset(LMKSpacing.xs)
            make.bottom.equalToSuperview()
        }

        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

        isAccessibilityElement = false
        accessibilityElements = [textField, helperLabel]

        traitChangeRegistration = registerForTraitChanges(
            [UITraitUserInterfaceStyle.self, UITraitAccessibilityContrast.self],
            action: #selector(refreshDynamicColors)
        )
    }

    @objc private func refreshDynamicColors() {
        updateValidationAppearance()
    }

    @objc private func textFieldDidChange() {
        textChangedHandler?(textField.text)
    }

    private func updateLeadingConstraint() {
        let leadingOffset: CGFloat = if leadingIcon != nil {
            LMKLayout.iconSmall + LMKSpacing.medium + LMKSpacing.small
        } else {
            LMKSpacing.medium
        }
        leadingIconConstraint?.update(offset: leadingOffset)
    }

    // MARK: - Validation Appearance

    private func updateValidationAppearance() {
        switch validationState {
        case .normal:
            containerView.layer.borderColor = LMKColor.divider.cgColor
            textField.accessibilityValue = nil
            updateHelperText()
        case .error(let message):
            containerView.layer.borderColor = LMKColor.error.cgColor
            helperLabel.text = message
            helperLabel.textColor = LMKColor.error
            helperLabel.isHidden = false
            textField.accessibilityValue = message
        case .success:
            containerView.layer.borderColor = LMKColor.success.cgColor
            textField.accessibilityValue = nil
            updateHelperText()
        }
    }

    private func updateHelperText() {
        if case .error = validationState { return }
        helperLabel.text = helperText
        helperLabel.textColor = LMKColor.textTertiary
        helperLabel.isHidden = helperText == nil
    }

    // MARK: - First Responder

    @discardableResult
    override public func becomeFirstResponder() -> Bool { textField.becomeFirstResponder() }

    @discardableResult
    override public func resignFirstResponder() -> Bool { textField.resignFirstResponder() }

    override public var isFirstResponder: Bool { textField.isFirstResponder }
}
