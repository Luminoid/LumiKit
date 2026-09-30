//
//  ExampleLaunchOptions.swift
//  LumiKitExample
//
//  Launch arguments that drive the accessibility and platform sweep from a
//  script: open one page, force RTL, apply a theme, audit one or every page,
//  and write a screenshot per page.
//
//  `-lmk-live-photo <still> <video>` hands the Photo Browser page a Live Photo
//  from two files, for a simulator whose library has none.
//
//  xcrun simctl launch --console booted com.luminoid.lumikit.example \
//      -lmk-audit-all -lmk-config ax5 -lmk-screenshots /tmp/lumikit-sweep
//

import Foundation

struct ExampleLaunchOptions {
    /// `-lmk-page <title>`: push the catalog page with this title at launch.
    var page: String?
    /// `-lmk-audit`: audit the launched page and print the findings.
    var audit = false
    /// `-lmk-audit-all`: walk every catalog page, audit each, then exit.
    var auditAll = false
    /// `-lmk-rtl`: force a right-to-left layout on the window.
    var rightToLeft = false
    /// `-lmk-theme example|ocean|default`: the theme applied at launch.
    var theme: String?
    /// `-lmk-config <name>`: a label for the run, echoed on every finding line.
    var configuration = "default"
    /// `-lmk-screenshots <dir>`: write `<dir>/<config>/<page>.png` per audited page.
    var screenshotDirectory: String?
    /// `-lmk-live-photo <still> <video>`: the paired files of a Live Photo the Photo Browser
    /// page opens at launch.
    var livePhotoFiles: [String] = []

    /// The options of this launch.
    static let current = parse()

    var isScripted: Bool { page != nil || audit || auditAll }

    static func parse(_ arguments: [String] = CommandLine.arguments) -> Self {
        var options = Self()
        var iterator = arguments.dropFirst().makeIterator()
        while let argument = iterator.next() {
            switch argument {
            case "-lmk-page": options.page = iterator.next()
            case "-lmk-audit": options.audit = true
            case "-lmk-audit-all": options.auditAll = true
            case "-lmk-rtl": options.rightToLeft = true
            case "-lmk-theme": options.theme = iterator.next()
            case "-lmk-config": options.configuration = iterator.next() ?? options.configuration
            case "-lmk-screenshots": options.screenshotDirectory = iterator.next()
            case "-lmk-live-photo": options.livePhotoFiles = [iterator.next(), iterator.next()].compactMap(\.self)
            default: break
            }
        }
        return options
    }
}
