//
//  LMKFile.swift
//  LumiKit
//
//  Temporary file URLs and bounded cleanup of the temporary directory.
//

import Foundation
import UniformTypeIdentifiers

/// Temporary file URLs and cleanup of the app's temporary directory.
public enum LMKFile {
    // MARK: - Temporary URLs

    /// A unique file URL in the temporary directory with the extension of `type`.
    public static func temporaryURL(extension type: UTType) -> URL {
        let name = (UUID().uuidString as NSString).appendingPathExtension(for: type)
        return FileManager.default.temporaryDirectory.appendingPathComponent(name, isDirectory: false)
    }

    /// A unique file URL in the temporary directory with a literal extension (`"jpg"`).
    public static func temporaryURL(extension pathExtension: String) -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        return pathExtension.isEmpty ? url : url.appendingPathExtension(pathExtension)
    }

    // MARK: - Cleanup

    /// Removes items from the temporary directory, continuing past individual failures.
    ///
    /// - Parameters:
    ///   - age: When set, only items whose modification date is known and at least this many seconds old are removed.
    ///   - prefix: When set, only items whose file name starts with the prefix are removed.
    /// - Returns: The number of items removed.
    @discardableResult
    public static func clearTemporaryFiles(olderThan age: TimeInterval? = nil, matchingPrefix prefix: String? = nil) -> Int {
        removeTemporaryFiles(olderThan: age, matchingPrefix: prefix)
    }

    /// `clearTemporaryFiles(olderThan:matchingPrefix:)` on a detached utility task, so the caller's
    /// actor never blocks on the file system.
    @discardableResult
    public static func clearTemporaryFilesInBackground(olderThan age: TimeInterval? = nil, matchingPrefix prefix: String? = nil) async -> Int {
        await Task.detached(priority: .utility) {
            removeTemporaryFiles(olderThan: age, matchingPrefix: prefix)
        }.value
    }

    private static func removeTemporaryFiles(olderThan age: TimeInterval?, matchingPrefix prefix: String?) -> Int {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
        let items: [URL]
        do {
            items = try fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )
        } catch {
            LMKLogger.error("clearTemporaryFiles: failed to list the temporary directory", error: error, category: .data)
            return 0
        }
        let cutoff = age.map { Date(timeIntervalSinceNow: -$0) }
        var removed = 0
        for item in items {
            if let prefix, !item.lastPathComponent.hasPrefix(prefix) { continue }
            if let cutoff {
                // An item whose age is unknown is kept: the age filter only removes what it can date.
                let modified = (try? item.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
                guard let modified, modified <= cutoff else { continue }
            }
            do {
                try fileManager.removeItem(at: item)
                removed += 1
            } catch {
                LMKLogger.error("clearTemporaryFiles: failed to remove \(item.lastPathComponent)", error: error, category: .data)
            }
        }
        return removed
    }
}
