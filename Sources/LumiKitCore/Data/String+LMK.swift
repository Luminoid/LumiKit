//
//  String+LMK.swift
//  LumiKit
//
//  String extension utilities.
//

import Foundation

public extension String {
    /// The string trimmed of whitespace and newlines, or `nil` when nothing remains.
    var lmk_trimmedOrNil: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

public extension String? {
    /// Returns the string if it's not empty, otherwise `nil`.
    /// Useful for cleaning up optional string handling patterns.
    var lmk_nonEmpty: String? {
        guard let self, !self.isEmpty else { return nil }
        return self
    }

    /// The wrapped string trimmed of whitespace and newlines, or `nil` when absent or blank.
    var lmk_trimmedOrNil: String? {
        self?.lmk_trimmedOrNil
    }
}
