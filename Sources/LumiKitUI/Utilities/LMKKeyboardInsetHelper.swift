//
//  LMKKeyboardInsetHelper.swift
//  LumiKit
//
//  Adjusts a scroll view's content inset when the keyboard appears/disappears
//  and scrolls to keep the focused input visible.
//

import UIKit

/// Observes keyboard show/hide notifications and adjusts a scroll view's bottom
/// content inset so the focused input stays visible above the keyboard.
///
/// ```swift
/// class MyViewController: UIViewController {
///     private lazy var keyboardHelper = LMKKeyboardInsetHelper(
///         scrollView: scrollView,
///         rootView: view
///     )
///
///     override func viewWillAppear(_ animated: Bool) {
///         super.viewWillAppear(animated)
///         keyboardHelper.startObserving()
///     }
///
///     override func viewWillDisappear(_ animated: Bool) {
///         super.viewWillDisappear(animated)
///         keyboardHelper.stopObserving()
///     }
/// }
/// ```
public final class LMKKeyboardInsetHelper {
    private weak var scrollView: UIScrollView?
    private weak var rootView: UIView?
    private var observers: [any NSObjectProtocol] = []

    /// - Parameters:
    ///   - scrollView: The scroll view whose content inset will be adjusted.
    ///   - rootView: The root view used to convert keyboard frame coordinates (typically `view`).
    public init(scrollView: UIScrollView, rootView: UIView) {
        self.scrollView = scrollView
        self.rootView = rootView
    }

    /// Begin observing keyboard notifications. Safe to call multiple times.
    public func startObserving() {
        guard observers.isEmpty else { return }
        observers.append(
            NotificationCenter.default.addObserver(
                forName: UIResponder.keyboardWillShowNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let self,
                      let userInfo = notification.userInfo,
                      let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                      let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
                      let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
                else { return }
                MainActor.assumeIsolated {
                    self.applyInset(keyboardFrame: keyboardFrame, duration: duration, curveValue: curveValue)
                }
            }
        )
        observers.append(
            NotificationCenter.default.addObserver(
                forName: UIResponder.keyboardWillHideNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let self,
                      let userInfo = notification.userInfo,
                      let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
                      let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
                else { return }
                MainActor.assumeIsolated {
                    self.resetInset(duration: duration, curveValue: curveValue)
                }
            }
        )
    }

    /// Stop observing keyboard notifications.
    public func stopObserving() {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers.removeAll()
    }

    // MARK: - Private

    private func applyInset(keyboardFrame: CGRect, duration: TimeInterval, curveValue: UInt) {
        guard let scrollView, let rootView else { return }

        let keyboardTop = rootView.convert(keyboardFrame, from: nil).origin.y
        let scrollViewBottom = scrollView.frame.maxY
        let overlap = scrollViewBottom - keyboardTop
        guard overlap > 0 else { return }

        let curve = UIView.AnimationOptions(rawValue: curveValue << 16)
        UIView.animate(withDuration: duration, delay: 0, options: curve) {
            scrollView.contentInset.bottom = overlap
            scrollView.verticalScrollIndicatorInsets.bottom = overlap
        }

        if let firstResponder = rootView.lmk_findFirstResponder() {
            let rect = firstResponder.convert(firstResponder.bounds, to: scrollView)
            let visibleRect = rect.insetBy(dx: 0, dy: -LMKSpacing.large)
            scrollView.scrollRectToVisible(visibleRect, animated: true)
        }
    }

    private func resetInset(duration: TimeInterval, curveValue: UInt) {
        guard let scrollView else { return }

        let curve = UIView.AnimationOptions(rawValue: curveValue << 16)
        UIView.animate(withDuration: duration, delay: 0, options: curve) {
            scrollView.contentInset.bottom = 0
            scrollView.verticalScrollIndicatorInsets.bottom = 0
        }
    }
}
