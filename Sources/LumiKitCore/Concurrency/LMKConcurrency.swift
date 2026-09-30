//
//  LMKConcurrency.swift
//  LumiKit
//
//  Codable helpers callable from any isolation, main-actor hops, and task bookkeeping.
//

import Foundation

/// Concurrency helpers: Codable from any isolation, main-actor hops, and owned tasks.
public enum LMKConcurrency {
    // MARK: - Codable Encoding/Decoding

    /// Encode a value as JSON. Callable from any isolation context.
    /// - Parameters:
    ///   - value: The value to encode.
    ///   - encoder: The encoder to use (a fresh `JSONEncoder` by default).
    public nonisolated static func encode(_ value: some Encodable, encoder: JSONEncoder = JSONEncoder()) throws -> Data {
        try encoder.encode(value)
    }

    /// Decode JSON data. Callable from any isolation context.
    /// - Parameters:
    ///   - type: The type to decode.
    ///   - data: The JSON data.
    ///   - decoder: The decoder to use (a fresh `JSONDecoder` by default).
    public nonisolated static func decode<T: Decodable>(_ type: T.Type, from data: Data, decoder: JSONDecoder = JSONDecoder()) throws -> T {
        try decoder.decode(type, from: data)
    }

    // MARK: - Main-actor hops

    /// Runs `work` on the main actor with a weak capture of `object`, skipping it if the object is gone.
    /// - Returns: The task, for cancellation.
    @discardableResult
    public static func onMainActor<T: AnyObject & Sendable>(
        weak object: T,
        _ work: @escaping @MainActor (T) -> Void
    ) -> Task<Void, Never> {
        Task { @MainActor [weak object] in
            guard let object else { return }
            work(object)
        }
    }

    /// Runs `work` on the main actor after `delay` seconds. Cancel the returned task to skip it.
    /// Use this instead of `DispatchQueue.main.asyncAfter`.
    @discardableResult
    public static func onMainActorAfter(delay: TimeInterval, _ work: @escaping @MainActor @Sendable () -> Void) -> Task<Void, Never> {
        Task {
            do {
                try await Task.sleep(nanoseconds: UInt64(max(0, delay) * 1_000_000_000))
                await MainActor.run { work() }
            } catch {
                // Cancelled before the delay elapsed: the work is skipped.
            }
        }
    }

    // MARK: - Runtime Checks

    /// Stops a debug build when called off the main actor.
    /// - Parameter operation: Description of the operation being performed.
    public static func assertMainActor(operation: String) {
        MainActor.assertIsolated("\(operation) must be called on the main actor")
    }

    // MARK: - Task Management

    /// Runs `operation` on the main actor with a weak capture of `object`, logging cancellation and errors.
    /// - Returns: The task handle; store it and cancel in `deinit`.
    @discardableResult
    public static func executeTask<T: AnyObject & Sendable>(
        weak object: T,
        operation: @escaping @MainActor (T) async throws -> Void
    ) -> Task<Void, Never> {
        Task { @MainActor [weak object] in
            guard let object else {
                LMKLogger.info("Task skipped: object deallocated", category: .general)
                return
            }
            do {
                try Task.checkCancellation()
                try await operation(object)
            } catch is CancellationError {
                LMKLogger.info("Task cancelled", category: .general)
            } catch {
                LMKLogger.error("Task error", error: error, category: .general)
            }
        }
    }
}
