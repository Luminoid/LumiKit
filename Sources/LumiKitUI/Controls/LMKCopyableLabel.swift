//
//  LMKCopyableLabel.swift
//  LumiKit
//
//  A label whose text can be copied: a long press (or a secondary click on
//  iPad and Mac) shows a Copy edit menu, VoiceOver gets a Copy custom action.
//

import UIKit

/// A `UILabel` with a Copy menu on long press or secondary click, for read-only detail values
/// (a phone number, an identifier, a brand) that users want on the clipboard without a text field.
///
/// ```swift
/// let phone = LMKCopyableLabel()
/// phone.lmk_apply(.body)
/// phone.text = clinic.phone
/// phone.onCopy = { LMKToast.show(.success, "Copied", in: self) }
/// ```
public final class LMKCopyableLabel: UILabel {
    // MARK: - Strings

    public nonisolated struct Strings: Sendable, Equatable {
        /// The menu item and VoiceOver action title.
        public var copy: String

        public init(copy: String = LMKLocalized("copyableLabel.copy")) {
            self.copy = copy
        }
    }

    /// Process-wide defaults; set at app launch to override.
    public nonisolated(unsafe) static var strings = Strings()

    /// Per-instance strings (default `Self.strings`).
    public var strings: Strings = LMKCopyableLabel.strings {
        didSet { updateAccessibilityActions() }
    }

    // MARK: - Public API

    /// `false` disables the menu and the VoiceOver action, and the label stops taking touches
    /// (a plain label inside a control or a cell passes them on).
    public var isCopyEnabled = true {
        didSet {
            isUserInteractionEnabled = isCopyEnabled
            longPress.isEnabled = isCopyEnabled
            secondaryClick.isEnabled = isCopyEnabled
            updateAccessibilityActions()
        }
    }

    /// Supplies the text to copy instead of the label's own (a raw value behind a formatted display).
    public var copyTextProvider: (() -> String?)?

    /// Called with the copied text after a copy.
    public var onCopy: ((String) -> Void)?

    /// Selection haptic on copy (default `true`).
    public var haptics = true

    /// The text a copy would put on the pasteboard: `copyTextProvider`, else the attributed or
    /// plain text; `nil` when there is nothing to copy.
    public var copyableText: String? {
        if let provider = copyTextProvider { return provider().flatMap { $0.isEmpty ? nil : $0 } }
        if let attributed = attributedText?.string, !attributed.isEmpty { return attributed }
        if let text, !text.isEmpty { return text }
        return nil
    }

    /// Where a copy lands. Tests replace it: `UIPasteboard.general` blocks the main thread inside
    /// the xctest host, which has no pasteboard connection.
    var writeToPasteboard: (String) -> Void = { UIPasteboard.general.string = $0 }

    private lazy var editMenuInteraction = UIEditMenuInteraction(delegate: self)
    private lazy var longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
    /// A right click or a two-finger trackpad click on iPad and Mac Catalyst.
    private lazy var secondaryClick: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleSecondaryClick(_:)))
        tap.buttonMaskRequired = .secondary
        return tap
    }()

    // MARK: - Initialization

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        isUserInteractionEnabled = true
        addInteraction(editMenuInteraction)
        addGestureRecognizer(longPress)
        addGestureRecognizer(secondaryClick)
        updateAccessibilityActions()
    }

    // MARK: - Actions

    /// Copies `copyableText` to the general pasteboard. Returns `false` when there was nothing to copy.
    @discardableResult
    public func copyToPasteboard() -> Bool {
        guard isCopyEnabled, let text = copyableText else { return false }
        writeToPasteboard(text)
        if haptics { LMKHaptics.selection() }
        onCopy?(text)
        return true
    }

    /// Shows the Copy menu anchored at `point` (in the label's coordinates). Ignored while the
    /// label is not in a window, where an edit menu cannot be presented.
    public func presentCopyMenu(at point: CGPoint) {
        guard isCopyEnabled, copyableText != nil, window != nil else { return }
        editMenuInteraction.presentEditMenu(with: UIEditMenuConfiguration(identifier: nil, sourcePoint: point))
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        presentCopyMenu(at: gesture.location(in: self))
    }

    @objc private func handleSecondaryClick(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        presentCopyMenu(at: gesture.location(in: self))
    }

    /// A one-line value is 19pt tall; the long press still lands in a 44pt band around it.
    override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard !isHidden else { return false }
        guard isCopyEnabled else { return bounds.contains(point) }
        return lmk_hitTestBounds(minimumSide: traitCollection.lmkTheme.layout.minimumTouchTarget).contains(point)
    }

    // MARK: - Accessibility

    private func updateAccessibilityActions() {
        guard isCopyEnabled else {
            accessibilityCustomActions = nil
            return
        }
        accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: strings.copy) { [weak self] _ in
                self?.copyToPasteboard() ?? false
            },
        ]
    }
}

// MARK: - UIEditMenuInteractionDelegate

extension LMKCopyableLabel: UIEditMenuInteractionDelegate {
    public func editMenuInteraction(_: UIEditMenuInteraction, menuFor _: UIEditMenuConfiguration, suggestedActions _: [UIMenuElement]) -> UIMenu? {
        guard isCopyEnabled, copyableText != nil else { return nil }
        let copy = UIAction(title: strings.copy, image: UIImage(systemName: "doc.on.doc")) { [weak self] _ in
            self?.copyToPasteboard()
        }
        return UIMenu(children: [copy])
    }
}
