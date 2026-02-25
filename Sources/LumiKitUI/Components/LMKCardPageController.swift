//
//  LMKCardPageController.swift
//  LumiKit
//
//  Base class for pages within an embedded navigation controller
//  inside a card or panel. Provides a custom header with leading
//  button, centered title, trailing button, and multi-page navigation
//  with slide animations.
//

import SnapKit
import UIKit

/// Base class for card-embedded navigation pages with design-token styling.
///
/// Provides shared header infrastructure:
/// - Leading button (back chevron, 32pt visual with 44pt touch target)
/// - Centered title label
/// - Trailing button (configurable icon, 32pt visual with 44pt touch target)
/// - Optional header separator
/// - Multi-page navigation with slide animations
/// - Dynamic color refresh on trait changes
///
/// Subclasses override `setupContent()` to build their content
/// below the header, and `trailingButtonTapped()` to handle
/// the trailing button action.
///
/// Multi-page navigation:
/// ```swift
/// // Push a new content view with slide animation
/// let detailView = buildDetailView()
/// pushContentView(detailView, title: "Details")
///
/// // Pop back to previous content
/// popContentView()
/// ```
///
/// Designed for use inside a `UINavigationController` with a hidden
/// system navigation bar (custom header replaces it).
open class LMKCardPageController: UIViewController {
    // MARK: - Configurable Strings

    /// Configurable strings for card page controllers.
    public nonisolated struct Strings: Sendable {
        /// Accessibility label for the leading (back) button.
        public var leadingButtonAccessibilityLabel: String
        /// Accessibility label for the trailing button.
        public var trailingButtonAccessibilityLabel: String

        public init(
            leadingButtonAccessibilityLabel: String = "Back",
            trailingButtonAccessibilityLabel: String = "Action"
        ) {
            self.leadingButtonAccessibilityLabel = leadingButtonAccessibilityLabel
            self.trailingButtonAccessibilityLabel = trailingButtonAccessibilityLabel
        }
    }

    /// Configurable strings for card page controllers. Set before presenting.
    public nonisolated(unsafe) static var strings = Strings()

    // MARK: - Constants

    private static let buttonSize: CGFloat = 32
    private static let buttonTouchInset = -(LMKLayout.minimumTouchTarget - buttonSize) / 2

    private static var symbolConfig: UIImage.SymbolConfiguration {
        UIImage.SymbolConfiguration(
            pointSize: LMKCardPageLayout.symbolPointSize,
            weight: LMKCardPageLayout.symbolWeight
        )
    }

    // MARK: - Navigation Types

    private enum NavigationDirection {
        case forward
        case backward
        case none
    }

    private struct PageSnapshot {
        let contentView: UIView
        let title: String?
    }

    // MARK: - Public Properties

    public private(set) lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = LMKColor.backgroundPrimary
        return view
    }()

    public private(set) lazy var headerTitleLabel: UILabel = {
        let label = UILabel()
        label.font = LMKTypography.bodyBold
        label.textColor = LMKColor.textPrimary
        label.textAlignment = .center
        return label
    }()

    public private(set) lazy var leadingButton: UIButton = {
        let button = TouchExpandedButton(type: .system)
        button.setImage(
            UIImage(systemName: leadingButtonSymbol, withConfiguration: Self.symbolConfig),
            for: .normal
        )
        button.tintColor = LMKColor.secondary
        button.addTarget(self, action: #selector(leadingButtonAction), for: .touchUpInside)
        button.accessibilityLabel = Self.strings.leadingButtonAccessibilityLabel
        button.lmk_touchAreaEdgeInsets = UIEdgeInsets(
            top: Self.buttonTouchInset, left: Self.buttonTouchInset,
            bottom: Self.buttonTouchInset, right: Self.buttonTouchInset
        )
        button.isHidden = !showsLeadingButton
        return button
    }()

    public private(set) lazy var trailingButton: UIButton = {
        let button = TouchExpandedButton(type: .system)
        button.setImage(
            UIImage(systemName: trailingButtonSymbol, withConfiguration: Self.symbolConfig),
            for: .normal
        )
        button.tintColor = LMKColor.secondary
        button.addTarget(self, action: #selector(trailingButtonAction), for: .touchUpInside)
        button.accessibilityLabel = Self.strings.trailingButtonAccessibilityLabel
        button.lmk_touchAreaEdgeInsets = UIEdgeInsets(
            top: Self.buttonTouchInset, left: Self.buttonTouchInset,
            bottom: Self.buttonTouchInset, right: Self.buttonTouchInset
        )
        button.isHidden = !showsTrailingButton
        return button
    }()

    public private(set) lazy var headerSeparator: UIView = {
        let view = UIView()
        view.backgroundColor = LMKColor.divider
        view.isHidden = !showsHeaderSeparator
        return view
    }()

    /// Container for subclass content. Add your views here in `setupContent()`.
    ///
    /// This view is the root page in the multi-page navigation stack.
    /// When pages are pushed, this view is preserved and restored on pop.
    public private(set) lazy var contentContainerView = UIView()

    // MARK: - Private Properties

    /// Internal container that manages page transitions.
    /// `contentContainerView` is the initial child; pushed pages replace it.
    private lazy var pageContainerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()

    // MARK: - Navigation State

    private var navigationStack: [PageSnapshot] = []
    private var isTransitioning = false

    /// Whether the navigation stack has pages that can be popped.
    public var canPopContent: Bool { !navigationStack.isEmpty }

    // MARK: - Configuration

    /// SF Symbol name for the trailing button. Default: `"doc.on.doc"` (copy).
    /// Override in subclasses to change the icon.
    open var trailingButtonSymbol: String { "doc.on.doc" }

    /// SF Symbol name for the leading button. Default: `"chevron.left"` (back).
    /// Override in subclasses to change the icon.
    open var leadingButtonSymbol: String { "chevron.left" }

    /// Header height. Default: `LMKCardPageLayout.headerHeight` (52pt).
    /// Override in subclasses to adjust.
    open var headerHeight: CGFloat { LMKCardPageLayout.headerHeight }

    /// Whether the leading button is visible on the root page. Default: `true`.
    /// When pages are pushed, the leading button always shows for back navigation.
    open var showsLeadingButton: Bool { true }

    /// Whether the trailing button is visible. Default: `true`.
    /// Override in subclasses to hide the trailing action button.
    open var showsTrailingButton: Bool { true }

    /// Whether a separator line appears below the header. Default: `false`.
    /// Override in subclasses to show a header separator.
    open var showsHeaderSeparator: Bool { false }

    // MARK: - Initialization

    /// Create a card page controller.
    /// - Parameter title: The title displayed in the header.
    public init(title: String) {
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle

    override open func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = LMKColor.backgroundPrimary
        setupHeader()
        setupPageContainer()
        setupContent()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: LMKCardPageController, _: UITraitCollection) in
            self.refreshBaseColors()
            self.refreshCardPageColors()
        }
    }

    // MARK: - Base Setup

    private func setupHeader() {
        headerTitleLabel.text = title

        view.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(headerHeight)
        }

        headerView.addSubview(leadingButton)
        leadingButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(LMKSpacing.large)
            make.centerY.equalToSuperview()
            make.size.equalTo(Self.buttonSize)
        }

        headerView.addSubview(trailingButton)
        trailingButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(LMKSpacing.large)
            make.centerY.equalToSuperview()
            make.size.equalTo(Self.buttonSize)
        }

        headerView.addSubview(headerTitleLabel)
        headerTitleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            if showsLeadingButton {
                make.leading.greaterThanOrEqualTo(leadingButton.snp.trailing).offset(LMKSpacing.small)
            } else {
                make.leading.greaterThanOrEqualToSuperview().inset(LMKSpacing.large)
            }
            if showsTrailingButton {
                make.trailing.lessThanOrEqualTo(trailingButton.snp.leading).offset(-LMKSpacing.small)
            } else {
                make.trailing.lessThanOrEqualToSuperview().inset(LMKSpacing.large)
            }
        }

        headerView.addSubview(headerSeparator)
        headerSeparator.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(LMKCardPageLayout.separatorHeight)
        }
    }

    private func setupPageContainer() {
        view.addSubview(pageContainerView)
        pageContainerView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        // contentContainerView is the root page — pinned to edges
        // so it can be snapshotted and restored correctly by push/pop
        pageContainerView.addSubview(contentContainerView)
        contentContainerView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    // MARK: - Template Methods (Override in Subclasses)

    /// Override to add page-specific content below `headerView`.
    /// Called after header setup in `viewDidLoad`.
    open func setupContent() {}

    /// Override to refresh page-specific dynamic colors on trait changes.
    /// Base colors (header, title, buttons) are refreshed automatically.
    open func refreshCardPageColors() {}

    /// Called when the leading button is tapped and no pages are in the stack.
    /// Default implementation pops the navigation controller.
    open func leadingButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    /// Called when the trailing button is tapped.
    /// Default implementation does nothing — override in subclasses.
    open func trailingButtonTapped() {}

    // MARK: - Multi-Page Navigation

    /// Push new content with a forward slide animation.
    ///
    /// The current content and title are saved to the navigation stack.
    /// The leading button automatically becomes visible for back navigation.
    ///
    /// - Parameters:
    ///   - contentView: The new content view to display.
    ///   - title: Optional new title. If nil, the current title is preserved.
    ///   - animated: Whether to animate the transition.
    public func pushContentView(_ contentView: UIView, title: String? = nil, animated: Bool = true) {
        guard !isTransitioning else { return }

        // Snapshot current page
        let currentPage = pageContainerView.subviews.first
        let snapshot = PageSnapshot(
            contentView: currentPage ?? UIView(),
            title: self.title
        )
        navigationStack.append(snapshot)

        // Transition to new content
        transitionContent(to: contentView, direction: .forward, animated: animated)

        // Update title
        if let title {
            self.title = title
            headerTitleLabel.text = title
        }

        // Show leading button for back navigation
        leadingButton.isHidden = false
    }

    /// Pop to the previous content with a backward slide animation.
    ///
    /// - Parameter animated: Whether to animate the transition.
    public func popContentView(animated: Bool = true) {
        guard !isTransitioning, let snapshot = navigationStack.popLast() else { return }

        // Restore previous page
        transitionContent(to: snapshot.contentView, direction: .backward, animated: animated)

        // Restore title
        if let previousTitle = snapshot.title {
            self.title = previousTitle
            headerTitleLabel.text = previousTitle
        }

        // Hide leading button if back at root and not configured to show
        if navigationStack.isEmpty, !showsLeadingButton {
            leadingButton.isHidden = true
        }
    }

    // MARK: - Content Transition

    private func transitionContent(to newView: UIView, direction: NavigationDirection, animated: Bool) {
        let oldView = pageContainerView.subviews.first

        if !animated || direction == .none {
            oldView?.removeFromSuperview()
            pageContainerView.addSubview(newView)
            newView.snp.makeConstraints { $0.edges.equalToSuperview() }
            return
        }

        guard let oldView else {
            pageContainerView.addSubview(newView)
            newView.snp.makeConstraints { $0.edges.equalToSuperview() }
            return
        }

        isTransitioning = true

        // Convert old view to manual frame for animation
        let oldFrame = oldView.frame
        oldView.snp.removeConstraints()
        oldView.translatesAutoresizingMaskIntoConstraints = true
        oldView.frame = oldFrame

        // Add new view with auto layout
        pageContainerView.addSubview(newView)
        newView.alpha = 1
        newView.snp.makeConstraints { $0.edges.equalToSuperview() }

        // Position new view off-screen
        let containerWidth = max(pageContainerView.bounds.width, 1)
        let slideIn = direction == .forward ? containerWidth : -containerWidth
        newView.transform = CGAffineTransform(translationX: slideIn, y: 0)

        let duration = LMKAnimationHelper.shouldAnimate
            ? LMKAnimationHelper.Duration.screenTransition
            : 0

        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut) {
            oldView.transform = CGAffineTransform(translationX: -slideIn, y: 0)
            oldView.alpha = 0
            newView.transform = .identity
            self.view.layoutIfNeeded()
        } completion: { _ in
            oldView.removeFromSuperview()
            self.isTransitioning = false
        }
    }

    // MARK: - Actions

    @objc private func leadingButtonAction() {
        if canPopContent {
            popContentView(animated: true)
        } else {
            leadingButtonTapped()
        }
    }

    @objc private func trailingButtonAction() { trailingButtonTapped() }

    // MARK: - Helpers

    private func refreshBaseColors() {
        headerView.backgroundColor = LMKColor.backgroundPrimary
        headerTitleLabel.textColor = LMKColor.textPrimary
        leadingButton.tintColor = LMKColor.secondary
        trailingButton.tintColor = LMKColor.secondary
        headerSeparator.backgroundColor = LMKColor.divider
        view.backgroundColor = LMKColor.backgroundPrimary
    }
}

// MARK: - Touch Expanded Button

/// Button subclass that respects `lmk_touchAreaEdgeInsets` for hit-testing.
private final class TouchExpandedButton: UIButton {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        lmk_pointInside(point, with: event)
    }
}
