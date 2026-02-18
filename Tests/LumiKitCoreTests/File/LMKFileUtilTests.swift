//
//  LMKFileUtilTests.swift
//  LumiKit
//

import Foundation
import Testing
import UniformTypeIdentifiers

@testable import LumiKitCore

// MARK: - LMKFileUtil

@Suite("LMKFileUtil")
struct LMKFileUtilTests {
    @Test("generateTempFileURL returns URL with correct extension for JPEG")
    func tempFileURLJPEG() {
        let url = LMKFileUtil.generateTempFileURL(fileExtension: .jpeg)
        #expect(url != nil)
        #expect(url?.pathExtension == "jpeg")
    }

    @Test("generateTempFileURL returns URL with correct extension for PNG")
    func tempFileURLPNG() {
        let url = LMKFileUtil.generateTempFileURL(fileExtension: .png)
        #expect(url != nil)
        #expect(url?.pathExtension == "png")
    }

    @Test("generateTempFileURL returns URL in temporary directory")
    func tempFileURLInTmpDir() {
        let url = LMKFileUtil.generateTempFileURL(fileExtension: .jpeg)
        #expect(url != nil)
        #expect(url!.path.contains(NSTemporaryDirectory().dropLast()))
    }

    @Test("generateTempFileURL returns unique URLs")
    func tempFileURLUnique() {
        let url1 = LMKFileUtil.generateTempFileURL(fileExtension: .jpeg)
        let url2 = LMKFileUtil.generateTempFileURL(fileExtension: .jpeg)
        #expect(url1 != url2)
    }

    @Test("clearTmpDirectory removes files")
    func clearTmpDirectoryRemovesFiles() throws {
        let tmpDir = FileManager.default.temporaryDirectory
        let testFile = tmpDir.appendingPathComponent("lmk_test_\(UUID().uuidString).txt")
        try "test".write(to: testFile, atomically: true, encoding: .utf8)
        #expect(FileManager.default.fileExists(atPath: testFile.path))

        LMKFileUtil.clearTmpDirectory()

        #expect(!FileManager.default.fileExists(atPath: testFile.path))
    }
}
