//
//  LMKFileTests.swift
//  LumiKit
//

import Foundation
import Testing
import UniformTypeIdentifiers
@testable import LumiKitCore

// MARK: - LMKFile

struct LMKFileTests {
    private let tmpDir = FileManager.default.temporaryDirectory

    @Test
    func `temporaryURL uses the type's preferred extension`() {
        #expect(LMKFile.temporaryURL(extension: .jpeg).pathExtension == "jpeg")
        #expect(LMKFile.temporaryURL(extension: .png).pathExtension == "png")
    }

    @Test
    func `temporaryURL accepts a literal extension`() {
        #expect(LMKFile.temporaryURL(extension: "jpg").pathExtension == "jpg")
        #expect(LMKFile.temporaryURL(extension: "").pathExtension == "")
    }

    @Test
    func `temporaryURL lives in the temporary directory`() {
        let url = LMKFile.temporaryURL(extension: .jpeg)
        #expect(url.deletingLastPathComponent().standardizedFileURL == tmpDir.standardizedFileURL)
    }

    @Test
    func `temporaryURL returns unique URLs`() {
        #expect(LMKFile.temporaryURL(extension: .jpeg) != LMKFile.temporaryURL(extension: .jpeg))
    }

    @Test
    func `clearTemporaryFiles removes matching files and reports the count`() throws {
        let prefix = "lmk_clear_\(UUID().uuidString)_"
        let kept = tmpDir.appendingPathComponent("lmk_keep_\(UUID().uuidString).txt")
        let doomed = (0 ..< 2).map { tmpDir.appendingPathComponent("\(prefix)\($0).txt") }
        try "test".write(to: kept, atomically: true, encoding: .utf8)
        for url in doomed {
            try "test".write(to: url, atomically: true, encoding: .utf8)
        }
        defer { try? FileManager.default.removeItem(at: kept) }

        let removed = LMKFile.clearTemporaryFiles(matchingPrefix: prefix)

        #expect(removed == 2)
        #expect(doomed.allSatisfy { !FileManager.default.fileExists(atPath: $0.path) })
        #expect(FileManager.default.fileExists(atPath: kept.path))
    }

    @Test
    func `clearTemporaryFiles keeps files newer than the age cutoff`() throws {
        let prefix = "lmk_age_\(UUID().uuidString)_"
        let fresh = tmpDir.appendingPathComponent("\(prefix)fresh.txt")
        let stale = tmpDir.appendingPathComponent("\(prefix)stale.txt")
        try "test".write(to: fresh, atomically: true, encoding: .utf8)
        try "test".write(to: stale, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.modificationDate: Date(timeIntervalSinceNow: -3600)], ofItemAtPath: stale.path)
        defer { try? FileManager.default.removeItem(at: fresh) }

        let removed = LMKFile.clearTemporaryFiles(olderThan: 600, matchingPrefix: prefix)

        #expect(removed == 1)
        #expect(!FileManager.default.fileExists(atPath: stale.path))
        #expect(FileManager.default.fileExists(atPath: fresh.path))
    }

    @Test
    func `clearTemporaryFiles keeps an item whose age is unknown when an age is given`() throws {
        let prefix = "lmk_dangling_\(UUID().uuidString)_"
        let link = tmpDir.appendingPathComponent("\(prefix)link")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: tmpDir.appendingPathComponent("\(prefix)missing"))
        defer { try? FileManager.default.removeItem(at: link) }
        #expect((try? FileManager.default.destinationOfSymbolicLink(atPath: link.path)) != nil)

        let removedWithAge = LMKFile.clearTemporaryFiles(olderThan: 600, matchingPrefix: prefix)
        #expect(removedWithAge == 0)
        #expect((try? FileManager.default.destinationOfSymbolicLink(atPath: link.path)) != nil, "a dangling link has no modification date, so the age filter cannot claim it")

        let removedWithoutAge = LMKFile.clearTemporaryFiles(matchingPrefix: prefix)
        #expect(removedWithoutAge == 1, "without an age filter every match goes")
        #expect((try? FileManager.default.destinationOfSymbolicLink(atPath: link.path)) == nil)
    }

    @Test
    func `clearTemporaryFilesInBackground removes off the calling task`() async throws {
        let prefix = "lmk_async_\(UUID().uuidString)_"
        let url = tmpDir.appendingPathComponent("\(prefix)file.txt")
        try "test".write(to: url, atomically: true, encoding: .utf8)

        let removed = await LMKFile.clearTemporaryFilesInBackground(matchingPrefix: prefix)

        #expect(removed == 1)
        #expect(!FileManager.default.fileExists(atPath: url.path))
    }
}
