//
//  LMKFileUtil.swift
//  LumiKit
//
//  File system utilities for temporary files and directory cleanup.
//

import Foundation
import UniformTypeIdentifiers

/// File system utilities for temporary files and directory cleanup.
public enum LMKFileUtil {
    /// Generate a temporary file URL with the given file extension type.
    /// - Parameter fileExtension: The `UTType` for the desired file extension.
    /// - Returns: A URL in the temporary directory, or `nil` if generation fails.
    public static func generateTempFileURL(fileExtension: UTType) -> URL? {
        let fileName = NSUUID().uuidString
        let fileNameWithExtension = (fileName as NSString).appendingPathExtension(for: fileExtension)
        let filePath = (NSTemporaryDirectory() as NSString).appendingPathComponent(fileNameWithExtension)
        return URL(fileURLWithPath: filePath)
    }

    /// Remove all files in the app's temporary directory.
    public static func clearTmpDirectory() {
        do {
            let tmpDirUrl = FileManager.default.temporaryDirectory
            let tmpDir = try FileManager.default.contentsOfDirectory(atPath: tmpDirUrl.path)
            for file in tmpDir {
                let fileUrl = tmpDirUrl.appendingPathComponent(file)
                try FileManager.default.removeItem(atPath: fileUrl.path)
            }
        } catch {
            LMKLogger.error("clearTmpDirectory failed", error: error, category: .data)
        }
    }
}
