//
//  LMKWait.swift
//  LumiKit
//
//  Polling wait for asynchronous UI work. Parallel suites can hold the main
//  actor for seconds at a time (date picker wheels, calendar views), so a fixed
//  sleep resumes before a dismissal or a handler has had its turn; polling a
//  condition with a generous budget stays deterministic under that load.
//

import Foundation

@MainActor
enum LMKWait {
    /// Polls `condition` every 20 ms until it holds or `timeout` worth of polls has run.
    ///
    /// The budget counts polls, not wall-clock time. When another suite blocks the main
    /// thread for longer than `timeout` (a first render on a slow CI runner), the awaited
    /// completion and this poll both come due during the block; a wall-clock deadline would
    /// see it expired on the first resume and give up one turn before the completion runs.
    static func until(timeout: Duration = .seconds(10), _ condition: () -> Bool) async {
        let interval = Duration.milliseconds(20)
        var polls = Int((timeout / interval).rounded(.up))
        while !condition(), polls > 0 {
            polls -= 1
            try? await Task.sleep(for: interval)
        }
    }
}
