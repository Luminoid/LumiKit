//
//  UITextField+LMKFormStyle.swift
//  LumiKit
//
//  Form text field and text view styling.
//

import UIKit

private let lmk_formContentPadding: CGFloat = LMKSpacing.xs

extension UITextField {
    /// Applies standard content leading and trailing padding for form text fields.
    @MainActor
    public func lmk_applyFormContentPadding() {
        leftView = UIView(frame: CGRect(x: 0, y: 0, width: lmk_formContentPadding, height: 1))
        leftViewMode = .always
        rightView = UIView(frame: CGRect(x: 0, y: 0, width: lmk_formContentPadding, height: 1))
        rightViewMode = .always
    }

    /// Applies base form styling: rounded rect border, design system background, content padding.
    @MainActor
    public func lmk_applyFormStyle() {
        borderStyle = .roundedRect
        backgroundColor = LMKColor.backgroundSecondary
        lmk_applyFormContentPadding()
    }
}

extension UITextView {
    /// Applies content inset matching single-line form text fields.
    public func lmk_applyFormContentPadding() {
        textContainerInset = UIEdgeInsets(
            top: lmk_formContentPadding,
            left: lmk_formContentPadding,
            bottom: lmk_formContentPadding,
            right: lmk_formContentPadding
        )
    }
}
