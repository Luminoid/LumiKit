//
//  LMKScrollStackViewController.swift
//  LumiKit
//
//  Base class for scroll + vertical stack layout view controllers.
//

import SnapKit
import UIKit

/// Base class for view controllers with a scrollable vertical stack layout.
///
/// Provides a scroll view containing a content view with a vertical stack view.
/// Subclasses override open properties to configure spacing, insets, and scroll
/// behavior, then override ``setupStackContent()`` to populate the stack.
///
/// ```swift
/// final class MyDetailViewController: LMKScrollStackViewController {
///     override var stackSpacing: CGFloat { LMKSpacing.xl }
///     override var contentInsets: UIEdgeInsets {
///         UIEdgeInsets(top: LMKSpacing.xl, left: LMKSpacing.large,
///                      bottom: LMKSpacing.xl, right: LMKSpacing.large)
///     }
///
///     override func setupStackContent() {
///         addSectionHeader("Details")
///         stackView.addArrangedSubview(LMKLabelFactory.body(text: "Hello"))
///         addDivider()
///     }
/// }
/// ```
open class LMKScrollStackViewController: UIViewController {
    // MARK: - Configuration

    /// Spacing between stack view items. Default: ``LMKSpacing/large``.
    open var stackSpacing: CGFloat { LMKSpacing.large }

    /// Insets from the content view edges to the stack view.
    /// Default: ``LMKSpacing/cardPadding`` on all sides.
    open var contentInsets: UIEdgeInsets {
        let padding = LMKSpacing.cardPadding
        return UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
    }

    /// Keyboard dismiss mode for the scroll view. Default: `.onDrag`.
    open var keyboardDismissMode: UIScrollView.KeyboardDismissMode { .onDrag }

    /// Whether the scroll view always bounces vertically. Default: `false`.
    open var alwaysBounceVertical: Bool { false }

    /// When `true`, the scroll view bottom edge anchors to the safe area layout guide.
    /// When `false`, the scroll view fills the full superview bounds.
    /// Default: `true`.
    open var scrollViewUseSafeArea: Bool { true }

    // MARK: - Views

    /// The scroll view that contains all content.
    public private(set) lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.keyboardDismissMode = self.keyboardDismissMode
        scrollView.alwaysBounceVertical = self.alwaysBounceVertical
        return scrollView
    }()

    /// Intermediate content view inside the scroll view.
    public private(set) lazy var contentView: UIView = .init()

    /// The vertical stack view where subclasses add their content.
    public private(set) lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = self.stackSpacing
        stackView.alignment = .fill
        return stackView
    }()

    // MARK: - Initialization

    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override open func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = LMKColor.backgroundPrimary
        setupScrollStack()
        setupStackContent()
    }

    // MARK: - Setup

    private func setupScrollStack() {
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            if scrollViewUseSafeArea {
                make.top.leading.trailing.equalToSuperview()
                make.bottom.equalTo(view.safeAreaLayoutGuide)
            } else {
                make.edges.equalToSuperview()
            }
        }

        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        let insets = contentInsets
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(insets.top)
            make.leading.equalToSuperview().offset(insets.left)
            make.trailing.equalToSuperview().offset(-insets.right)
            make.bottom.equalToSuperview().offset(-insets.bottom)
        }
    }

    // MARK: - Template Method

    /// Override to populate the stack view with content.
    /// Called after the scroll and stack infrastructure is set up in ``viewDidLoad()``.
    open func setupStackContent() {}

    // MARK: - Helpers

    /// Add a styled section header label to the stack view.
    /// - Parameter title: The header text.
    public func addSectionHeader(_ title: String) {
        stackView.addArrangedSubview(LMKLabelFactory.heading(text: title, level: 3))
    }

    /// Add a pixel-perfect divider to the stack view.
    public func addDivider() {
        stackView.addArrangedSubview(LMKDividerView())
    }
}
