//
//  NSAttributedString+LMK.swift
//  LumiKit
//
//  Convenient attributed string building helpers.
//

import Foundation

public extension NSAttributedString {
    /// Concatenate two attributed strings.
    ///
    /// ```swift
    /// let combined = boldTitle + regularBody
    /// ```
    static func + (lhs: NSAttributedString, rhs: NSAttributedString) -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: lhs)
        mutable.append(rhs)
        return mutable
    }
}

public extension NSMutableAttributedString {
    /// Append a plain string with attributes. Returns `self` for chaining.
    ///
    /// ```swift
    /// let result = NSMutableAttributedString()
    ///     .lmk_append("Hello ", attributes: [.font: UIFont.boldSystemFont(ofSize: 16)])
    ///     .lmk_append("world", attributes: [.font: UIFont.systemFont(ofSize: 16)])
    /// ```
    @discardableResult
    func lmk_append(_ string: String, attributes: [NSAttributedString.Key: Any] = [:]) -> NSMutableAttributedString {
        append(NSAttributedString(string: string, attributes: attributes))
        return self
    }

    /// Apply attributes to the entire string. Returns `self` for chaining.
    @discardableResult
    func lmk_applyToAll(_ attributes: [NSAttributedString.Key: Any]) -> NSMutableAttributedString {
        guard length > 0 else { return self }
        addAttributes(attributes, range: NSRange(location: 0, length: length))
        return self
    }
}
