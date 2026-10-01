//
//  LMKOnceContinuation.swift
//  LumiKit
//
//  A continuation that resumes exactly once: from `resolve(_:)`, or with a
//  fallback value when the last reference goes away (an alert dismissed without
//  an action, a presentation UIKit refused, a custom presentation that never
//  reports back). The awaited alerts capture one in every action closure.
//

import Foundation

final class LMKOnceContinuation<Value: Sendable> {
    private var continuation: CheckedContinuation<Value, Never>?
    private let fallback: Value

    init(_ continuation: CheckedContinuation<Value, Never>, fallback: Value) {
        self.continuation = continuation
        self.fallback = fallback
    }

    isolated deinit {
        resolve(fallback)
    }

    /// Resumes with `value` unless something already resumed.
    func resolve(_ value: Value) {
        guard let continuation else { return }
        self.continuation = nil
        continuation.resume(returning: value)
    }
}
