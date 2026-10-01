//
//  AsyncImageTestSupport.swift
//  LumiKit
//
//  Shared helper for async photo data source tests: a resumable gate to hold
//  an in-flight image load open. Tests wait for the load's effect with
//  `LMKWait.until`, never for a fixed number of turns.
//

/// Holds async callers until `open()` is called — used to keep a fake image
/// load in flight while the test reconfigures or reuses the cell, proving the
/// stale result is discarded.
@MainActor
final class AsyncGate {
    private var isOpen = false
    private var continuations: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        if isOpen { return }
        await withCheckedContinuation { continuations.append($0) }
    }

    func open() {
        isOpen = true
        continuations.forEach { $0.resume() }
        continuations.removeAll()
    }
}
