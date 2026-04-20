//
//  LMKCountdownConfirmation.swift
//  LumiKit
//
//  Presents a confirmation alert where the destructive button is disabled
//  for a countdown period, preventing accidental taps on critical actions.
//

import UIKit

/// Presents a confirmation alert with a timed countdown on the confirm button.
/// The confirm button is disabled for `countdownSeconds` and shows a live countdown
/// in its title. After the countdown completes, the button becomes tappable.
public enum LMKCountdownConfirmation {
    /// Present a countdown confirmation alert.
    /// - Parameters:
    ///   - viewController: The presenting view controller.
    ///   - title: Alert title.
    ///   - message: Alert message.
    ///   - confirmTitle: Base title for the confirm button (countdown appended while active).
    ///   - countdownSeconds: Seconds to wait before enabling confirm. Default is 3.
    ///   - onConfirm: Called when the user taps confirm after countdown.
    ///   - onCancel: Called when the user cancels.
    public static func present(
        on viewController: UIViewController,
        title: String,
        message: String? = nil,
        confirmTitle: String,
        countdownSeconds: Int = 3,
        onConfirm: @escaping () -> Void,
        onCancel: (() -> Void)? = nil
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        // Holder lets action handlers cancel the countdown task without
        // a forward reference (the task is created after the actions).
        final class TaskHolder {
            var task: Task<Void, Never>?
        }
        let holder = TaskHolder()

        let cancelAction = UIAlertAction(
            title: LMKAlertPresenter.strings.cancel,
            style: .cancel
        ) { _ in
            holder.task?.cancel()
            onCancel?()
        }
        alert.addAction(cancelAction)

        let confirmAction = UIAlertAction(
            title: "\(confirmTitle) (\(countdownSeconds))",
            style: .destructive
        ) { _ in
            holder.task?.cancel()
            onConfirm()
        }
        confirmAction.isEnabled = false
        alert.addAction(confirmAction)

        viewController.present(alert, animated: true)

        // Countdown ticks down once per second. Weakly captures confirmAction so
        // the task exits if the alert is dismissed before the countdown finishes.
        holder.task = Task { [weak confirmAction] in
            for tick in stride(from: countdownSeconds - 1, through: 0, by: -1) {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, let confirmAction else { return }
                if tick > 0 {
                    confirmAction.setValue("\(confirmTitle) (\(tick))", forKey: "title")
                } else {
                    confirmAction.setValue(confirmTitle, forKey: "title")
                    confirmAction.isEnabled = true
                }
            }
        }
    }
}
