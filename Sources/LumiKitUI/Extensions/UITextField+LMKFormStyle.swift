//
//  UITextField+LMKFormStyle.swift
//  LumiKit
//
//  Form text field and text view styling.
//

import UIKit

private let lmk_formContentPadding: CGFloat = LMKSpacing.xs

public extension UITextField {
    /// Applies standard content leading and trailing padding for form text fields.
    func lmk_applyFormContentPadding() {
        leftView = UIView(frame: CGRect(x: 0, y: 0, width: lmk_formContentPadding, height: 1))
        leftViewMode = .always
        rightView = UIView(frame: CGRect(x: 0, y: 0, width: lmk_formContentPadding, height: 1))
        rightViewMode = .always
    }

    /// Applies base form styling: rounded rect border, design system background, content padding.
    func lmk_applyFormStyle() {
        borderStyle = .roundedRect
        backgroundColor = LMKColor.backgroundSecondary
        lmk_applyFormContentPadding()
    }
}

public extension UITextView {
    /// Applies content inset matching single-line form text fields.
    func lmk_applyFormContentPadding() {
        textContainerInset = UIEdgeInsets(
            top: lmk_formContentPadding,
            left: lmk_formContentPadding,
            bottom: lmk_formContentPadding,
            right: lmk_formContentPadding,
        )
    }
}
