//
//  String+LMK.swift
//  LumiKit
//
//  String extension utilities.
//

import Foundation

extension Optional where Wrapped == String {
    /// Returns the string if it's not empty, otherwise `nil`.
    /// Useful for cleaning up optional string handling patterns.
    public var nonEmpty: String? {
        guard let self, !self.isEmpty else { return nil }
        return self
    }
}
