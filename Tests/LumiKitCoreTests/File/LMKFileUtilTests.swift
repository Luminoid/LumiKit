//
//  LMKFileUtilTests.swift
//  LumiKit
//

import Foundation
import Testing
import UniformTypeIdentifiers
@testable import LumiKitCore

// MARK: - LMKFileUtil

struct LMKFileUtilTests {
    @Test
    func `generateTempFileURL returns URL with correct extension for JPEG`() {
        let url = LMKFileUtil.generateTempFileURL(fileExtension: .jpeg)
        #expect(url != nil)
        #expect(url?.pathExtension == "jpeg")
    }

    @Test
    func `generateTempFileURL returns URL with correct extension for PNG`() {
        let url = LMKFileUtil.generateTempFileURL(fileExtension: .png)
        #expect(url != nil)
        #expect(url?.pathExtension == "png")
    }

    @Test
    func `generateTempFileURL returns URL in temporary directory`() throws {
        let url = try #require(LMKFileUtil.generateTempFileURL(fileExtension: .jpeg))
        #expect(url.path.contains(NSTemporaryDirectory().dropLast()))
    }

    @Test
    func `generateTempFileURL returns unique URLs`() {
        let url1 = LMKFileUtil.generateTempFileURL(fileExtension: .jpeg)
        let url2 = LMKFileUtil.generateTempFileURL(fileExtension: .jpeg)
        #expect(url1 != url2)
    }

    @Test
    func `clearTmpDirectory removes files`() throws {
        let tmpDir = FileManager.default.temporaryDirectory
        let testFile = tmpDir.appendingPathComponent("lmk_test_\(UUID().uuidString).txt")
        try "test".write(to: testFile, atomically: true, encoding: .utf8)
        #expect(FileManager.default.fileExists(atPath: testFile.path))

        LMKFileUtil.clearTmpDirectory()

        #expect(!FileManager.default.fileExists(atPath: testFile.path))
    }
}
