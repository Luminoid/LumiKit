//
//  AsyncImageTestSupport.swift
//  LumiKit
//
//  Shared helpers for async photo data source tests: a resumable gate to hold
//  an in-flight image load open, and a main-actor settling loop.
//

import UIKit

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

/// Yields the main actor repeatedly so cooperatively scheduled load tasks can
/// run to completion before the test asserts.
@MainActor
func settleMainActor(iterations: Int = 50) async {
    for _ in 0 ..< iterations {
        await Task.yield()
    }
}
