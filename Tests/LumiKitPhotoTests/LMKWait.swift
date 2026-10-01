//
//  LMKWait.swift
//  LumiKit
//
//  Polling wait for asynchronous UI work. Parallel suites can hold the main
//  actor for seconds at a time (date picker wheels, calendar views), so a fixed
//  sleep resumes before a dismissal or a handler has had its turn; polling a
//  condition with a generous deadline stays deterministic under that load.
//

import Foundation

@MainActor
enum LMKWait {
    /// Polls `condition` every 20 ms until it holds or `timeout` passes.
    static func until(timeout: Duration = .seconds(10), _ condition: () -> Bool) async {
        let deadline = ContinuousClock.now + timeout
        while !condition(), ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(20))
        }
    }
}
