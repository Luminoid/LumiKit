//
//  String+LMK.swift
//  LumiKit
//
//  String extension utilities.
//

import Foundation

public extension String? {
    /// Returns the string if it's not empty, otherwise `nil`.
    /// Useful for cleaning up optional string handling patterns.
    var nonEmpty: String? {
        guard let self, !self.isEmpty else { return nil }
        return self
    }
}
