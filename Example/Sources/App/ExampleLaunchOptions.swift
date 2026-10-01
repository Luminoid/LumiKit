//
//  ExampleLaunchOptions.swift
//  LumiKitExample
//
//  Launch arguments that drive the accessibility and platform sweep from a
//  script: open one page, force RTL, apply a theme, audit one or every page,
//  tap through a page's presentations, and write a screenshot per page.
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
    /// `-lmk-audit`: audit the launched page, print the findings, and exit.
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
    /// `-lmk-tap <title>` (repeatable): after `-lmk-page` opens, tap these controls in order
    /// (by title or accessibility label), then screenshot and audit what they presented.
    var taps: [String] = []

    /// The options of this launch.
    static let current = parse()

    var isScripted: Bool { page != nil || audit || auditAll }

    /// Parses the `-lmk-` arguments. A value option takes the next token unless that token is
    /// another `-lmk-` flag, so `-lmk-page -lmk-audit` leaves the page unset instead of eating the flag.
    static func parse(_ arguments: [String] = CommandLine.arguments) -> Self {
        var options = Self()
        let tokens = Array(arguments.dropFirst())
        var index = 0
        func value() -> String? {
            let next = index + 1
            guard next < tokens.count, !tokens[next].hasPrefix("-lmk-") else { return nil }
            index = next
            return tokens[next]
        }
        while index < tokens.count {
            switch tokens[index] {
            case "-lmk-page": options.page = value()
            case "-lmk-audit": options.audit = true
            case "-lmk-audit-all": options.auditAll = true
            case "-lmk-rtl": options.rightToLeft = true
            case "-lmk-theme": options.theme = value()
            case "-lmk-config": options.configuration = value() ?? options.configuration
            case "-lmk-screenshots": options.screenshotDirectory = value()
            case "-lmk-live-photo": options.livePhotoFiles = [value(), value()].compactMap(\.self)
            case "-lmk-tap": if let title = value() { options.taps.append(title) }
            default: break
            }
            index += 1
        }
        return options
    }
}
