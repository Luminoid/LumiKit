//
//  LMKFloatingButton.swift
//  LumiKit
//
//  Draggable floating action button that stays on top of the window.
//  Snaps to the nearest horizontal edge after dragging.
//

import SnapKit
import UIKit

/// Layout constants for the floating button.
public enum LMKFloatingButtonLayout {
    public static let defaultSize: CGFloat = 56
    public static let edgeMargin: CGFloat = 16
    public static let iconSize: CGFloat = 24
    public static let badgeOffset: CGFloat = -4
}

/// Draggable floating action button for quick actions or debug access.
///
/// Presented on the key window so it persists across view controller transitions.
/// After dragging, the button snaps to the nearest horizontal edge (left or right).
///
/// ```swift
/// // Show a floating debug button
/// LMKFloatingButton.show(icon: UIImage(systemName: "ladybug")) {
///     print("Debug tapped")
/// }
///
/// // Dismiss
/// LMKFloatingButton.dismissCurrent()
/// ```
public final class LMKFloatingButton: UIView {
    // MARK: - Configurable Strings

    public nonisolated struct Strings: Sendable {
        public var accessibilityLabel: String

        public init(accessibilityLabel: String = "Floating action button") {
            self.accessibilityLabel = accessibilityLabel
        }
    }

    public nonisolated(unsafe) static var strings = Strings()

    // MARK: - Properties

    /// The currently visible floating button, if any.
    public private(set) static weak var current: LMKFloatingButton?

    /// Called when the button is tapped.
    public var tapHandler: (() -> Void)?

    /// The button icon.
    public var icon: UIImage? {
        didSet { iconView.image = icon }
    }

    private let buttonSize: CGFloat
    private let iconView = UIImageView()
    private var badgeView: LMKBadgeView?
    private var panStartCenter: CGPoint = .zero

    // MARK: - Initialization

    public init(icon: UIImage?, size: CGFloat = LMKFloatingButtonLayout.defaultSize) {
        self.buttonSize = size
        super.init(frame: CGRect(origin: .zero, size: CGSize(width: size, height: size)))
        self.icon = icon
        setupUI()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: LMKFloatingButton, _: UITraitCollection) in
            self.refreshDynamicColors()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        // Shape
        backgroundColor = LMKColor.primary
        layer.cornerRadius = buttonSize / 2
        lmk_applyShadow(LMKShadow.button())

        // Icon
        iconView.image = icon
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = LMKColor.white
        addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(LMKFloatingButtonLayout.iconSize)
        }

        // Gestures
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(pan)

        // Accessibility
        isAccessibilityElement = true
        accessibilityLabel = Self.strings.accessibilityLabel
        accessibilityTraits = .button
    }

    private func refreshDynamicColors() {
        backgroundColor = LMKColor.primary
        lmk_applyShadow(LMKShadow.button())
        iconView.tintColor = LMKColor.white
    }

    // MARK: - Show / Dismiss

    /// Show the floating button on the key window.
    public func show() {
        // Dismiss any existing floating button
        Self.current?.dismiss()

        guard let window = LMKSceneUtil.getKeyWindow() else { return }

        Self.current = self
        window.addSubview(self)

        // Initial position: right edge, vertically centered
        let safeArea = window.safeAreaInsets
        let x = window.bounds.width - buttonSize - LMKFloatingButtonLayout.edgeMargin
        let y = window.bounds.midY - buttonSize / 2
        frame.origin = CGPoint(
            x: x,
            y: clampY(y, in: window.bounds, safeArea: safeArea)
        )

        // Animate in
        if LMKAnimationHelper.shouldAnimate {
            alpha = 0
            transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            UIView.animate(
                withDuration: LMKAnimationHelper.Duration.modalPresentation,
                delay: 0,
                usingSpringWithDamping: LMKAnimationHelper.Spring.damping,
                initialSpringVelocity: 0,
                options: [.curveEaseOut],
                animations: {
                    self.alpha = 1
                    self.transform = .identity
                }
            )
        }
    }

    /// Dismiss the floating button.
    public func dismiss() {
        let duration = LMKAnimationHelper.shouldAnimate ? LMKAnimationHelper.Duration.actionSheet : 0
        UIView.animate(
            withDuration: duration,
            animations: {
                self.alpha = 0
                self.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
            },
            completion: { _ in
                if Self.current === self {
                    Self.current = nil
                }
                self.removeFromSuperview()
            }
        )
    }

    // MARK: - Static Convenience

    /// Show a floating button on the key window. Returns the button for further configuration.
    @discardableResult
    public static func show(icon: UIImage?, tapHandler: @escaping () -> Void) -> LMKFloatingButton {
        let button = LMKFloatingButton(icon: icon)
        button.tapHandler = tapHandler
        button.show()
        return button
    }

    /// Dismiss the currently visible floating button.
    public static func dismissCurrent() {
        current?.dismiss()
    }

    // MARK: - Badge

    /// Show a count badge on the floating button.
    public func showBadge(count: Int) {
        let badge = getOrCreateBadge()
        badge.configure(count: count)
    }

    /// Show a text badge on the floating button.
    public func showBadge(text: String) {
        let badge = getOrCreateBadge()
        badge.configure(text: text)
    }

    /// Show a dot badge on the floating button.
    public func showBadge() {
        let badge = getOrCreateBadge()
        badge.configure()
    }

    /// Hide the badge.
    public func hideBadge() {
        badgeView?.removeFromSuperview()
        badgeView = nil
    }

    private func getOrCreateBadge() -> LMKBadgeView {
        if let existing = badgeView { return existing }

        let badge = LMKBadgeView()
        addSubview(badge)
        badge.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(LMKFloatingButtonLayout.badgeOffset)
            make.trailing.equalToSuperview().offset(-LMKFloatingButtonLayout.badgeOffset)
        }
        badgeView = badge
        return badge
    }

    // MARK: - Gestures

    @objc private func handleTap() {
        tapHandler?()
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let superview else { return }

        switch gesture.state {
        case .began:
            panStartCenter = center
            if LMKAnimationHelper.shouldAnimate {
                UIView.animate(withDuration: LMKAnimationHelper.Duration.buttonPress) {
                    self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                }
            }

        case .changed:
            let translation = gesture.translation(in: superview)
            let safeArea = superview.safeAreaInsets
            let newX = panStartCenter.x + translation.x
            let newY = panStartCenter.y + translation.y
            center = CGPoint(
                x: clampX(newX, in: superview.bounds),
                y: clampY(newY - buttonSize / 2, in: superview.bounds, safeArea: safeArea) + buttonSize / 2
            )

        case .ended, .cancelled:
            snapToNearestEdge()
            if LMKAnimationHelper.shouldAnimate {
                UIView.animate(withDuration: LMKAnimationHelper.Duration.buttonPress) {
                    self.transform = .identity
                }
            }

        default:
            break
        }
    }

    // MARK: - Edge Snapping

    private func snapToNearestEdge() {
        guard let superview else { return }

        let midX = superview.bounds.midX
        let margin = LMKFloatingButtonLayout.edgeMargin
        let safeArea = superview.safeAreaInsets

        let targetX: CGFloat
        if center.x < midX {
            // Snap to left edge
            targetX = margin + safeArea.left + buttonSize / 2
        } else {
            // Snap to right edge
            targetX = superview.bounds.width - margin - safeArea.right - buttonSize / 2
        }

        let duration = LMKAnimationHelper.shouldAnimate ? LMKAnimationHelper.Duration.uiShort : 0
        UIView.animate(
            withDuration: duration,
            delay: 0,
            usingSpringWithDamping: LMKAnimationHelper.Spring.damping,
            initialSpringVelocity: 0,
            options: [.curveEaseOut],
            animations: {
                self.center.x = targetX
            }
        )
    }

    // MARK: - Clamping

    private func clampX(_ x: CGFloat, in bounds: CGRect) -> CGFloat {
        let half = buttonSize / 2
        return min(max(x, half), bounds.width - half)
    }

    private func clampY(_ y: CGFloat, in bounds: CGRect, safeArea: UIEdgeInsets) -> CGFloat {
        let minY = safeArea.top + LMKFloatingButtonLayout.edgeMargin
        let maxY = bounds.height - safeArea.bottom - LMKFloatingButtonLayout.edgeMargin - buttonSize
        return min(max(y, minY), maxY)
    }
}
