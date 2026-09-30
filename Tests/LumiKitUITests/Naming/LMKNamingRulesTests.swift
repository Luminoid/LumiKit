//
//  LMKNamingRulesTests.swift
//  LumiKit
//
//  The mechanically checkable half of the naming rules in CONTRIBUTING.md, run over `Sources/`.
//

import Foundation
import Testing

struct LMKNamingRulesTests {
    private struct Declaration {
        let file: String
        let line: String
        let name: String
        let kind: String
        let superclass: String?
    }

    // MARK: - Rules

    @Test
    func `Every public top-level type carries the LMK prefix`() throws {
        let offenders = try topLevelDeclarations().filter { !$0.name.hasPrefix("LMK") }
        #expect(offenders.isEmpty, "\(offenders.map { "\($0.file): \($0.name)" })")
    }

    @Test
    func `Banned role suffixes never appear on public types`() throws {
        let banned = ["Helper", "Helpers", "Util", "Utils", "Service", "Manager", "Type", "Config"]
        let offenders = try topLevelDeclarations().filter { declaration in
            banned.contains { declaration.name.hasSuffix($0) }
        }
        #expect(offenders.isEmpty, "\(offenders.map { "\($0.file): \($0.name)" })")
    }

    @Test
    func `View controller subclasses end in ViewController`() throws {
        let offenders = try topLevelDeclarations().filter { declaration in
            guard declaration.kind == "class", let superclass = declaration.superclass else { return false }
            if superclass.hasSuffix("ViewController") { return !declaration.name.hasSuffix("ViewController") }
            if superclass.hasSuffix("Controller") { return !declaration.name.hasSuffix("Controller") }
            return false
        }
        #expect(offenders.isEmpty, "\(offenders.map { "\($0.file): \($0.name)" })")
    }

    @Test
    func `No public Handler closures, top-level Strings types, or string globals`() throws {
        let patterns = try [
            #"^\s*(public|open) var \w+Handler\b"#,
            #"^public (nonisolated )?struct LMK\w+Strings\b"#,
            #"^(public )?nonisolated\(unsafe\) (public )?var lmk\w+Strings\b"#,
        ].map { try NSRegularExpression(pattern: $0) }
        var offenders: [String] = []
        for (file, contents) in try sourceFiles() {
            for line in contents.split(separator: "\n", omittingEmptySubsequences: false) {
                let text = String(line)
                let range = NSRange(text.startIndex..., in: text)
                if patterns.contains(where: { $0.firstMatch(in: text, range: range) != nil }) {
                    offenders.append("\(file): \(text.trimmingCharacters(in: .whitespaces))")
                }
            }
        }
        #expect(offenders.isEmpty, "\(offenders)")
    }

    // MARK: - Source scanning

    private static let sourcesDirectory: URL = {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0 ..< 4 {
            url.deleteLastPathComponent()
        }
        return url.appendingPathComponent("Sources", isDirectory: true)
    }()

    private func sourceFiles() throws -> [(String, String)] {
        let root = Self.sourcesDirectory
        let enumerator = try #require(FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil))
        var files: [(String, String)] = []
        for case let url as URL in enumerator where url.pathExtension == "swift" {
            let relative = url.path.replacingOccurrences(of: root.path + "/", with: "")
            try files.append((relative, String(contentsOf: url, encoding: .utf8)))
        }
        try #require(!files.isEmpty, "no sources under \(root.path)")
        return files
    }

    private func topLevelDeclarations() throws -> [Declaration] {
        let pattern = try NSRegularExpression(pattern: #"^(?:public|open) (?:nonisolated )?(?:final )?(class|struct|enum|protocol|actor) (\w+)(?::\s*([\w.]+))?"#)
        var declarations: [Declaration] = []
        for (file, contents) in try sourceFiles() {
            for line in contents.split(separator: "\n") {
                let text = String(line)
                let range = NSRange(text.startIndex..., in: text)
                guard let match = pattern.firstMatch(in: text, range: range) else { continue }
                let capture: (Int) -> String? = { index in
                    guard let range = Range(match.range(at: index), in: text) else { return nil }
                    return String(text[range])
                }
                declarations.append(Declaration(file: file, line: text, name: capture(2) ?? "", kind: capture(1) ?? "", superclass: capture(3)))
            }
        }
        return declarations
    }
}
