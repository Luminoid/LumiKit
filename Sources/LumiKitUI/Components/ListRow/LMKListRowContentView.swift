//
//  LMKListRowContentView.swift
//  LumiKit
//
//  The content view `LMKListRowConfiguration` renders into.
//

import SnapKit
import UIKit

/// Renders an `LMKListRowConfiguration`. Cells create it through the configuration; hosts that
/// want the row outside a cell can build one directly and set `configuration`.
public final class LMKListRowContentView: UIView, UIContentView, LMKThemeApplying {
    // MARK: - Public API

    /// The row configuration; setting an `LMKListRowConfiguration` re-renders the row.
    public var configuration: UIContentConfiguration {
        get { current }
        set {
            guard let configuration = newValue as? LMKListRowConfiguration else { return }
            current = configuration
            applyTheme(traitCollection.lmkTheme)
        }
    }

    public func supports(_ configuration: UIContentConfiguration) -> Bool {
        configuration is LMKListRowConfiguration
    }

    /// The configuration as `LMKListRowConfiguration`.
    public private(set) var current: LMKListRowConfiguration

    /// The full-bleed fill behind the content while `Style.highlighted` / `Style.selected` give
    /// one (hidden otherwise), drawn with `stateBackgroundCorners`.
    public let stateBackgroundView: UIView = LMKSurfaceView()
    /// The corners of `stateBackgroundView`; a host that rounds the row sets the same ones.
    public var stateBackgroundCorners: LMKCornerStyle = .square {
        didSet {
            guard stateBackgroundCorners != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    public let leadingContainer: UIView = LMKSurfaceView()
    public let leadingImageView = UIImageView()
    public let titleLabel = UILabel()
    public let subtitleLabel = UILabel()
    public let detailLabel = UILabel()
    /// The widest a single-line detail grows, as a share of the row; past it the detail truncates
    /// and the title keeps the rest.
    static let detailMaxWidthRatio: CGFloat = 0.5
    public let accessoryImageView = UIImageView()
    public let textStack = UIStackView()
    public let trailingStack = UIStackView()
    /// The switch for a `.toggle` trailing accessory, once one has been shown.
    public private(set) var toggle: LMKSwitch?
    /// The badge for a `.badge` trailing accessory, once one has been shown.
    public private(set) var badgeView: LMKBadgeView?

    private var leadingCustomView: UIView?
    private var trailingCustomView: UIView?
    private var loadTask: Task<Void, Never>?
    private var asyncImageID: String?
    private let heightGuide = UILayoutGuide()
    /// The row inside its vertical content insets; the leading view, the text, and the trailing
    /// views center in it and never cross its top (so, centered, never its bottom either).
    private let contentGuide = UILayoutGuide()
    private var contentTopConstraint: Constraint?
    private var contentBottomConstraint: Constraint?
    private var minimumHeightConstraint: Constraint?
    private var preferredHeightConstraint: Constraint?
    private var leadingSizeConstraint: Constraint?

    // MARK: - Initialization

    public init(configuration: LMKListRowConfiguration) {
        current = configuration
        super.init(frame: .zero)
        setupUI()
        lmk_startApplyingTheme()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        loadTask?.cancel()
    }

    // MARK: - Setup

    private func setupUI() {
        stateBackgroundView.isUserInteractionEnabled = false
        stateBackgroundView.isHidden = true
        addSubview(stateBackgroundView)
        stateBackgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        leadingImageView.contentMode = .scaleAspectFill
        leadingImageView.clipsToBounds = true
        leadingContainer.addSubview(leadingImageView)
        leadingImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        leadingContainer.setContentHuggingPriority(.required, for: .horizontal)
        leadingContainer.setContentCompressionResistancePriority(.required, for: .horizontal)

        textStack.axis = .vertical
        textStack.alignment = .fill
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)

        detailLabel.textAlignment = .right
        detailLabel.setContentHuggingPriority(.required, for: .horizontal)
        // A short detail keeps its full width beside a wrapping title (999 outranks the title's
        // 750); a long one truncates at `detailMaxWidthRatio` of the row instead of crushing the
        // title to nothing (the cap below is required, so it wins over this).
        detailLabel.setContentCompressionResistancePriority(UILayoutPriority(999), for: .horizontal)
        accessoryImageView.contentMode = .scaleAspectFit
        accessoryImageView.setContentHuggingPriority(.required, for: .horizontal)
        accessoryImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        trailingStack.axis = .horizontal
        trailingStack.alignment = .center
        trailingStack.addArrangedSubview(detailLabel)
        trailingStack.addArrangedSubview(accessoryImageView)

        addSubview(leadingContainer)
        addSubview(textStack)
        addSubview(trailingStack)

        addLayoutGuide(contentGuide)
        contentGuide.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.width.equalTo(0)
            contentTopConstraint = make.top.equalToSuperview().constraint
            // Just below required: a cell's encapsulated height is imposed before the row is
            // measured, and must not break the insets while it is.
            contentBottomConstraint = make.bottom.equalToSuperview().priority(999).constraint
        }
        leadingContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalTo(contentGuide)
            leadingSizeConstraint = make.width.height.equalTo(0).constraint
            make.top.greaterThanOrEqualTo(contentGuide)
        }
        trailingStack.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalTo(contentGuide)
            make.top.greaterThanOrEqualTo(contentGuide)
            // With every trailing view hidden the stack has no width of its own; it collapses so
            // the text takes the room (the visible views' required hugging wins otherwise).
            make.width.equalTo(0).priority(.medium)
        }
        detailLabel.snp.makeConstraints { make in
            make.width.lessThanOrEqualTo(self).multipliedBy(Self.detailMaxWidthRatio)
        }
        textStack.snp.makeConstraints { make in
            make.leading.equalTo(leadingContainer.snp.trailing)
            make.centerY.equalTo(contentGuide)
            make.top.greaterThanOrEqualTo(contentGuide)
            // Pinned, not `<=`: a wrapping label bounded only from one side keeps the narrow
            // width an early layout pass gave it.
            make.trailing.equalTo(trailingStack.snp.leading)
        }
        // A layout guide, not a constraint on self: a constraint on the view would switch off its
        // autoresizing translation and break hosts that position it by frame.
        addLayoutGuide(heightGuide)
        heightGuide.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview()
            make.width.equalTo(0)
            minimumHeightConstraint = make.height.greaterThanOrEqualTo(0).constraint
            // The content only bounds the height from below (centered rows, `top >=`), so a
            // fitting request with an expanded target would resolve to that target; this
            // low-priority hug settles the height at max(minimum, content) for any target.
            preferredHeightConstraint = make.height.equalTo(0).priority(.low).constraint
        }
    }

    // MARK: - Theme

    public func applyTheme(_ theme: LMKTheme) {
        let style = theme.listRow.merging(current.style)
        let insets = style.contentInsets ?? NSDirectionalEdgeInsets(top: theme.spacing.small, leading: theme.spacing.large, bottom: theme.spacing.small, trailing: theme.spacing.large)
        contentTopConstraint?.update(offset: insets.top)
        contentBottomConstraint?.update(offset: -insets.bottom)
        let minimumHeight = style.minimumHeight ?? theme.layout.rowHeightCompact
        minimumHeightConstraint?.update(offset: minimumHeight)
        preferredHeightConstraint?.update(offset: minimumHeight)

        let state = stateStyle(style)
        applyLeading(style: style, theme: theme, insets: insets)
        applyText(style: style, theme: theme, foreground: state?.foregroundColor)
        applyTrailing(style: style, theme: theme, insets: insets, foreground: state?.foregroundColor)
        applyStateBackground(state?.background, theme: theme)

        var contentAlpha = state?.alpha ?? 1
        if !current.isEnabled { contentAlpha = min(contentAlpha, style.disabled?.alpha ?? theme.alpha.disabled) }
        alpha = contentAlpha
        updateAccessibility()
    }

    /// The per-state style for the configuration's cell state: `selected` under `highlighted`.
    private func stateStyle(_ style: LMKListRowConfiguration.Style) -> LMKControlStateStyle? {
        LMKControlStateStyle.merge(current.isSelected ? style.selected : nil, current.isHighlighted ? style.highlighted : nil)
    }

    /// Shows the state fill at once (a press reads instantly) and fades it out.
    private func applyStateBackground(_ background: LMKBackgroundStyle?, theme: LMKTheme) {
        if let background {
            _ = stateBackgroundView.lmk_apply(surface: LMKSurfaceStyle(background: background, corners: stateBackgroundCorners))
            stateBackgroundView.layer.removeAllAnimations()
            stateBackgroundView.isHidden = false
            stateBackgroundView.alpha = 1
        } else if !stateBackgroundView.isHidden {
            let hide = { [stateBackgroundView] in
                stateBackgroundView.isHidden = true
                stateBackgroundView.alpha = 1
            }
            if LMKAnimation.shouldAnimate, window != nil {
                UIView.animate(withDuration: theme.animation.fast, animations: { self.stateBackgroundView.alpha = 0 }, completion: { finished in
                    if finished { hide() }
                })
            } else {
                hide()
            }
        }
    }

    private func applyLeading(style: LMKListRowConfiguration.Style, theme: LMKTheme, insets: NSDirectionalEdgeInsets) {
        let size = style.leadingSize ?? theme.layout.iconCircle
        var customView: UIView?
        if case let .view(view) = current.leading { customView = view }
        // Remove only what is still ours: a reused row must not pull a host's view out of the
        // row that took it since.
        if let old = leadingCustomView, old !== customView, old.superview === leadingContainer {
            old.removeFromSuperview()
        }
        leadingCustomView = nil
        leadingImageView.isHidden = false
        var hasLeading = true

        switch current.leading {
        case .none:
            hasLeading = false
            cancelAsyncLoad()
            leadingImageView.image = nil
            leadingContainer.lmk_apply(surface: LMKSurfaceStyle(background: .clear, corners: LMKCornerStyle.square))
        case let .symbol(name, tint):
            cancelAsyncLoad()
            showSymbol(name, tint: tint ?? LMKColor.primary, style: style, theme: theme)
        case let .image(image):
            cancelAsyncLoad()
            showThumbnail(image, style: style, theme: theme)
        case let .asyncImage(id, placeholderSymbol, load):
            if asyncImageID != id {
                cancelAsyncLoad()
                asyncImageID = id
                showSymbol(placeholderSymbol ?? "photo", tint: LMKColor.textTertiary, style: style, theme: theme)
                loadTask = Task { [weak self] in
                    let image = await load(id)
                    guard !Task.isCancelled, let self, asyncImageID == id else { return }
                    if let image {
                        showThumbnail(image, style: style, theme: theme)
                    }
                }
            } else if leadingImageView.contentMode == .scaleAspectFill {
                showThumbnail(leadingImageView.image, style: style, theme: theme)
            } else {
                showSymbol(placeholderSymbol ?? "photo", tint: LMKColor.textTertiary, style: style, theme: theme)
            }
        case let .view(view):
            cancelAsyncLoad()
            leadingImageView.isHidden = true
            leadingContainer.lmk_apply(surface: LMKSurfaceStyle(background: .clear, corners: LMKCornerStyle.square))
            if view.superview !== leadingContainer {
                leadingContainer.addSubview(view)
                view.snp.remakeConstraints { make in
                    make.edges.equalToSuperview()
                }
            }
            leadingCustomView = view
        }

        leadingContainer.isHidden = !hasLeading
        leadingSizeConstraint?.update(offset: hasLeading ? size : 0)
        leadingContainer.snp.updateConstraints { make in
            make.leading.equalToSuperview().offset(insets.leading)
        }
        textStack.snp.updateConstraints { make in
            make.leading.equalTo(leadingContainer.snp.trailing).offset(hasLeading ? (style.leadingSpacing ?? theme.spacing.medium) : 0)
        }
    }

    private func showSymbol(_ name: String, tint: UIColor, style: LMKListRowConfiguration.Style, theme: LMKTheme) {
        let configuration = UIImage.SymbolConfiguration(pointSize: style.leadingSymbolPointSize ?? theme.layout.iconExtraSmall)
        leadingImageView.image = UIImage(systemName: name, withConfiguration: configuration)
        leadingImageView.contentMode = .center
        leadingImageView.tintColor = tint
        leadingImageView.lmk_apply(surface: LMKSurfaceStyle(corners: LMKCornerStyle.square))
        leadingContainer.lmk_apply(surface: LMKSurfaceStyle(
            background: .solid(tint.withAlphaComponent(style.leadingCircleAlpha ?? theme.alpha.xxs)),
            corners: .circle
        ))
    }

    private func showThumbnail(_ image: UIImage?, style: LMKListRowConfiguration.Style, theme: LMKTheme) {
        leadingImageView.image = image
        leadingImageView.contentMode = .scaleAspectFill
        leadingImageView.tintColor = nil
        let corners = style.leadingCorners ?? .fixed(theme.cornerRadius.small)
        leadingContainer.lmk_apply(surface: LMKSurfaceStyle(background: .clear, corners: corners))
        leadingImageView.lmk_apply(surface: LMKSurfaceStyle(corners: corners))
    }

    private func cancelAsyncLoad() {
        loadTask?.cancel()
        loadTask = nil
        asyncImageID = nil
    }

    private func applyText(style: LMKListRowConfiguration.Style, theme: LMKTheme, foreground: UIColor?) {
        textStack.spacing = style.textSpacing ?? theme.spacing.xxs
        titleLabel.lmk_apply(style.titleTextStyle ?? .body, color: foreground ?? style.titleColor ?? LMKColor.textPrimary)
        // Unlimited by default (as `UIListContentConfiguration`): a one-line row truncates at large Dynamic Type sizes.
        titleLabel.numberOfLines = style.titleLines ?? 0
        titleLabel.lmk_setText(current.title)
        subtitleLabel.lmk_apply(style.subtitleTextStyle ?? .caption, color: foreground ?? style.subtitleColor ?? LMKColor.textSecondary)
        subtitleLabel.numberOfLines = style.subtitleLines ?? 0
        subtitleLabel.lmk_setText(current.subtitle)
        subtitleLabel.isHidden = current.subtitle?.isEmpty ?? true
        detailLabel.lmk_apply(style.detailTextStyle ?? .bodyMedium, color: foreground ?? style.detailColor ?? LMKColor.textPrimary)
        detailLabel.lmk_setText(current.detail)
        detailLabel.isHidden = current.detail?.isEmpty ?? true
    }

    private func applyTrailing(style: LMKListRowConfiguration.Style, theme: LMKTheme, insets: NSDirectionalEdgeInsets, foreground: UIColor?) {
        trailingStack.spacing = style.trailingSpacing ?? theme.spacing.small
        var customView: UIView?
        if case let .view(view) = current.trailing { customView = view }
        if let old = trailingCustomView, old !== customView, old.superview === trailingStack {
            trailingStack.removeArrangedSubview(old)
            old.removeFromSuperview()
        }
        trailingCustomView = nil
        toggle?.isHidden = true
        badgeView?.isHidden = true
        accessoryImageView.isHidden = true
        accessoryImageView.tintColor = foreground ?? style.accessoryTint ?? LMKColor.textTertiary

        switch current.trailing {
        case .none:
            break
        case .disclosure:
            let configuration = UIImage.SymbolConfiguration(pointSize: style.accessoryChevronSize ?? theme.layout.symbolAccessory, weight: .semibold)
            accessoryImageView.image = UIImage(systemName: "chevron.forward", withConfiguration: configuration)
            accessoryImageView.isHidden = false
        case .checkmark:
            let configuration = UIImage.SymbolConfiguration(pointSize: style.accessoryChevronSize ?? theme.layout.symbolAccessory, weight: .semibold)
            accessoryImageView.image = UIImage(systemName: "checkmark", withConfiguration: configuration)
            accessoryImageView.tintColor = foreground ?? style.checkmarkTint ?? LMKColor.primary
            accessoryImageView.isHidden = false
        case let .toggle(isOn, _):
            let toggle = self.toggle ?? makeToggle()
            toggle.isOn = isOn
            toggle.isEnabled = current.isEnabled
            toggle.onValueChange = { [weak self] value in self?.handleToggle(value) }
            toggle.isHidden = false
            // The row's title names the switch when VoiceOver reaches it on its own.
            toggle.accessibilityLabel = current.title
        case let .badge(content):
            let badgeView = self.badgeView ?? makeBadge()
            badgeView.configure(content)
            badgeView.isHidden = false
        case let .image(image, tint):
            accessoryImageView.image = image
            accessoryImageView.tintColor = foreground ?? tint ?? style.accessoryTint ?? LMKColor.textTertiary
            accessoryImageView.isHidden = false
        case let .view(view):
            view.setContentHuggingPriority(.required, for: .horizontal)
            if view.superview !== trailingStack {
                trailingStack.addArrangedSubview(view)
            }
            trailingCustomView = view
        }

        trailingStack.snp.updateConstraints { make in
            make.trailing.equalToSuperview().offset(-insets.trailing)
        }
        textStack.snp.updateConstraints { make in
            make.trailing.equalTo(trailingStack.snp.leading).offset(trailingStack.arrangedSubviews.allSatisfy(\.isHidden) ? 0 : -(style.trailingSpacing ?? theme.spacing.small))
        }
    }

    private func makeToggle() -> LMKSwitch {
        let toggle = LMKSwitch()
        trailingStack.addArrangedSubview(toggle)
        self.toggle = toggle
        return toggle
    }

    private func makeBadge() -> LMKBadgeView {
        let badge = LMKBadgeView()
        trailingStack.insertArrangedSubview(badge, at: trailingStack.arrangedSubviews.count - 1)
        badgeView = badge
        return badge
    }

    // MARK: - Toggle

    /// Records the flip in the configuration (and in the hosting cell's stored one, so the next
    /// configuration pass keeps it), then tells the host.
    private func handleToggle(_ value: Bool) {
        guard case let .toggle(_, onValueChange) = current.trailing else { return }
        let trailing = LMKListRowConfiguration.Trailing.toggle(isOn: value, onValueChange: onValueChange)
        current.trailing = trailing
        if let cell = enclosingCell, var stored = cell.contentConfiguration as? LMKListRowConfiguration, case .toggle = stored.trailing {
            stored.trailing = trailing
            cell.contentConfiguration = stored
        }
        onValueChange(value)
    }

    /// The table or collection cell this view is the content of, if any.
    private var enclosingCell: (any LMKListRowHostingCell)? {
        var view = superview
        while let candidate = view {
            if let cell = candidate as? any LMKListRowHostingCell { return cell }
            view = candidate.superview
        }
        return nil
    }

    // MARK: - Accessibility

    private func updateAccessibility() {
        isAccessibilityElement = current.isSingleAccessibilityElement
        guard isAccessibilityElement else {
            accessibilityElements = nil
            titleLabel.accessibilityLabel = [current.title, current.subtitle].compactMap(\.self).joined(separator: ", ")
            return
        }
        accessibilityLabel = current.accessibilityLabel ?? [current.title, current.subtitle, current.detail]
            .compactMap(\.self)
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        accessibilityHint = current.accessibilityHint
        var traits: UIAccessibilityTraits = []
        if case .disclosure = current.trailing { traits.insert(.button) }
        if case .checkmark = current.trailing { traits.insert(.selected) }
        if !current.isEnabled { traits.insert(.notEnabled) }
        accessibilityTraits = traits
    }
}

/// The cells whose `contentConfiguration` a toggle row writes its value back into.
protocol LMKListRowHostingCell: UIView {
    var contentConfiguration: (any UIContentConfiguration)? { get set }
}

extension UITableViewCell: LMKListRowHostingCell {}
extension UICollectionViewCell: LMKListRowHostingCell {}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKListRowConfiguration`.
    var listRow: LMKListRowConfiguration.Style {
        get { self[LMKListRowConfiguration.Style.self] }
        set { self[LMKListRowConfiguration.Style.self] = newValue }
    }
}
