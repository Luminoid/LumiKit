//
//  LMKConcurrencyHelpers.swift
//  LumiKit
//
//  Unified concurrency helpers.
//  Provides thread-safe encoding/decoding and async/sync utilities.
//

import Foundation

/// Unified helper for concurrency operations.
/// Provides consistent patterns for async/sync operations.
public enum LMKConcurrencyHelpers {
    // MARK: - Codable Encoding/Decoding

    /// Encode a `Codable` value to `Data`.
    /// Thread-safe: can be called from any isolation context.
    public nonisolated static func encode(_ value: some Encodable) -> Data? {
        try? JSONEncoder().encode(value)
    }

    /// Decode `Data` to a `Codable` type.
    /// Thread-safe: can be called from any isolation context.
    public nonisolated static func decode<T: Decodable>(_ type: T.Type, from data: Data) -> T? {
        try? JSONDecoder().decode(type, from: data)
    }

    // MARK: - Async Operations

    /// Execute a closure on the main actor asynchronously with a weak self capture.
    /// Use this for UI updates from background contexts.
    public static func onMainActor<T: AnyObject & Sendable>(
        weak object: T,
        _ work: @escaping @MainActor (T) -> Void,
    ) {
        Task { @MainActor [weak object] in
            guard let object else { return }
            work(object)
        }
    }

    /// Execute a closure on the main actor after a delay.
    /// Use this instead of `DispatchQueue.main.asyncAfter`.
    public static func onMainActorAfter(delay: TimeInterval, _ work: @escaping @MainActor @Sendable () -> Void) {
        Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            await MainActor.run {
                work()
            }
        }
    }

    // MARK: - Runtime Checks

    /// Assert that execution is on the main actor.
    /// - Parameter operation: Description of the operation being performed.
    public static func assertMainActor(operation: String) {
        #if DEBUG
            assert(Thread.isMainThread, "\(operation) must be called on main actor")
        #endif
    }

    // MARK: - Task Management

    /// Execute a task with proper cancellation handling and weak self capture.
    /// Use this for async operations in ViewControllers to prevent memory leaks.
    public static func executeTask<T: AnyObject & Sendable>(
        weak object: T,
        operation: @escaping @MainActor (T) async throws -> Void,
    ) {
        Task { @MainActor [weak object] in
            guard let object else {
                LMKLogger.info("Task cancelled: object deallocated", category: .ui)
                return
            }
            try Task.checkCancellation()
            do {
                try await operation(object)
            } catch is CancellationError {
                LMKLogger.info("Task cancelled", category: .ui)
            } catch {
                LMKLogger.error("Task error", error: error, category: .ui)
            }
        }
    }
}
