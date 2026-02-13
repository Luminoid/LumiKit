//
//  LMKSearchBar.swift
//  LumiKit
//
//  Custom search bar with magnifying glass icon, text field, clear button, cancel button.
//

import SnapKit
import UIKit

/// Delegate for LMKSearchBar.
public protocol LMKSearchBarDelegate: AnyObject {
    func lmkSearchBar(_ searchBar: LMKSearchBar, textDidChange searchText: String)
    func lmkSearchBarSearchButtonClicked(_ searchBar: LMKSearchBar)
    func lmkSearchBarTextDidBeginEditing(_ searchBar: LMKSearchBar)
    func lmkSearchBarTextDidEndEditing(_ searchBar: LMKSearchBar)
    func lmkSearchBarCancelButtonClicked(_ searchBar: LMKSearchBar)
}

public extension LMKSearchBarDelegate {
    func lmkSearchBarSearchButtonClicked(_ searchBar: LMKSearchBar) {}
    func lmkSearchBarTextDidBeginEditing(_ searchBar: LMKSearchBar) {}
    func lmkSearchBarTextDidEndEditing(_ searchBar: LMKSearchBar) {}
    func lmkSearchBarCancelButtonClicked(_ searchBar: LMKSearchBar) {}
}

/// Custom search bar matching native iOS UISearchBar features (minimal style).
@MainActor
public final class LMKSearchBar: UIView {
    // MARK: - Configurable Strings

    public struct Strings: Sendable {
        public var cancel: String
        public var clearAccessibilityLabel: String

        public init(cancel: String = "Cancel", clearAccessibilityLabel: String = "Clear") {
            self.cancel = cancel
            self.clearAccessibilityLabel = clearAccessibilityLabel
        }
    }

    nonisolated(unsafe) public static var strings = Strings()

    // MARK: - Public

    public weak var delegate: LMKSearchBarDelegate?

    public var placeholder: String? {
        get { textField.attributedPlaceholder?.string }
        set {
            textField.attributedPlaceholder = newValue.map {
                NSAttributedString(string: $0, attributes: [.foregroundColor: LMKColor.textTertiary])
            }
        }
    }

    public var text: String? {
        get { textField.text }
        set {
            textField.text = newValue
            updateClearButtonVisibility()
        }
    }

    public var showsCancelButton: Bool {
        get { !cancelButton.isHidden }
        set {
            cancelButton.isHidden = !newValue
            updateCancelButtonConstraints()
        }
    }

    @discardableResult
    public override func becomeFirstResponder() -> Bool { textField.becomeFirstResponder() }

    @discardableResult
    public override func resignFirstResponder() -> Bool { textField.resignFirstResponder() }

    public override var canBecomeFirstResponder: Bool { textField.canBecomeFirstResponder }
    public override var isFirstResponder: Bool { textField.isFirstResponder }

    // MARK: - Subviews

    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = LMKColor.backgroundTertiary
        view.layer.cornerRadius = LMKCornerRadius.medium
        view.layer.masksToBounds = true
        return view
    }()

    private lazy var magnifyingGlassImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "magnifyingglass")
        iv.tintColor = LMKColor.textTertiary
        iv.contentMode = .scaleAspectFit
        iv.setContentHuggingPriority(.required, for: .horizontal)
        return iv
    }()

    private lazy var textField: UITextField = {
        let field = UITextField()
        field.font = LMKTypography.body
        field.textColor = LMKColor.textPrimary
        field.returnKeyType = .search
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.clearButtonMode = .never
        field.delegate = self
        field.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        return field
    }()

    private lazy var clearButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = LMKColor.textTertiary
        button.addTarget(self, action: #selector(clearButtonTapped), for: .touchUpInside)
        button.isHidden = true
        button.accessibilityLabel = Self.strings.clearAccessibilityLabel
        return button
    }()

    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(Self.strings.cancel, for: .normal)
        button.titleLabel?.font = LMKTypography.body
        button.setTitleColor(LMKColor.primary, for: .normal)
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        button.isHidden = true
        button.setContentHuggingPriority(.required, for: .horizontal)
        return button
    }()

    private var cancelButtonWidthConstraint: Constraint?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(containerView)
        containerView.addSubview(magnifyingGlassImageView)
        containerView.addSubview(textField)
        containerView.addSubview(clearButton)
        addSubview(cancelButton)

        let iconSize: CGFloat = 18
        let horizontalPadding = LMKSpacing.medium

        containerView.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.height.equalTo(36)
        }

        magnifyingGlassImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(horizontalPadding)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(iconSize)
        }

        textField.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.trailing.equalTo(clearButton.snp.leading).offset(-LMKSpacing.xs)
            make.leading.equalTo(magnifyingGlassImageView.snp.trailing).offset(LMKSpacing.small)
        }

        clearButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-LMKSpacing.small)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(22)
        }

        cancelButton.snp.makeConstraints { make in
            make.leading.equalTo(containerView.snp.trailing).offset(LMKSpacing.small)
            make.centerY.equalToSuperview()
            make.top.bottom.equalToSuperview()
            cancelButtonWidthConstraint = make.width.equalTo(0).constraint
            make.trailing.equalToSuperview()
        }
    }

    private func updateClearButtonVisibility() {
        clearButton.isHidden = textField.text?.isEmpty ?? true
    }

    private func updateCancelButtonConstraints() {
        let showing = !cancelButton.isHidden
        cancelButtonWidthConstraint?.update(offset: showing ? 60 : 0)
        let duration = LMKAnimationHelper.shouldAnimate ? LMKAnimationHelper.Duration.actionSheet : 0
        UIView.animate(withDuration: duration) { self.layoutIfNeeded() }
    }
}

// MARK: - Actions

private extension LMKSearchBar {
    @objc func textFieldDidChange() {
        updateClearButtonVisibility()
        delegate?.lmkSearchBar(self, textDidChange: textField.text ?? "")
    }

    @objc func clearButtonTapped() {
        textField.text = ""
        updateClearButtonVisibility()
        delegate?.lmkSearchBar(self, textDidChange: "")
    }

    @objc func cancelButtonTapped() {
        textField.text = ""
        textField.resignFirstResponder()
        updateClearButtonVisibility()
        showsCancelButton = false
        delegate?.lmkSearchBarCancelButtonClicked(self)
    }
}

// MARK: - UITextFieldDelegate

extension LMKSearchBar: UITextFieldDelegate {
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        showsCancelButton = true
        delegate?.lmkSearchBarTextDidBeginEditing(self)
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        showsCancelButton = false
        delegate?.lmkSearchBarTextDidEndEditing(self)
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        delegate?.lmkSearchBarSearchButtonClicked(self)
        return true
    }
}
