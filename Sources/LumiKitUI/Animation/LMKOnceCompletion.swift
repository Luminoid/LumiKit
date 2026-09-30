//
//  LMKOnceCompletion.swift
//  LumiKit
//
//  A completion that runs exactly once: from the animation's own callback, or
//  from a fallback just past the duration when Core Animation never reports
//  back (a window that is not rendering, an animation replaced mid-flight).
//

import Foundation

final class LMKOnceCompletion {
    private var completion: (() -> Void)?
    private var fallback: Task<Void, Never>?

    /// Schedules the fallback `duration` + a small margin from now.
    init(after duration: TimeInterval, _ completion: @escaping () -> Void) {
        self.completion = completion
        fallback = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(duration + Self.margin))
            self?.fire()
        }
    }

    /// Runs the completion if it has not run yet.
    func fire() {
        guard let completion else { return }
        self.completion = nil
        fallback?.cancel()
        fallback = nil
        completion()
    }

    private static let margin: TimeInterval = 0.1
}
