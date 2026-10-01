//
//  LMKDetailCardView.swift
//  LumiKit
//
//  Renders an `LMKDetailCard`: a card surface with a header, rows keyed by id
//  (updated in place across reconfigures), and an action block.
//

import LumiKitCore
import SnapKit
import UIKit

/// A view rendering one `LMKDetailCard`.
///
/// ```swift
/// let view = LMKDetailCardView(card: card)
/// view.setValue("Every 5 days", forRowID: "water")
/// view.setAction("water", enabled: false)
/// ```
///
/// `configure(_:)` reuses row views whose id and kind match (a photo strip keeps its loaded
/// tiles and a hero image stays up while its next load runs), so hosts can rebuild the model freely.
public final class LMKDetailCardView: UIView, LMKThemeApplying {
    // MARK: - Strings

    /// Process-wide defaults; set at app launch to override.
    public nonisolated(unsafe) static var strings = Strings()

    /// Per-instance strings (default `Self.strings`).
    public var strings: Strings = LMKDetailCardView.strings {
        didSet { reconfigure() }
    }

    // MARK: - Properties

    /// The card last configured.
    public private(set) var card: LMKDetailCard?

    /// Per-instance style; `nil` fields resolve from `theme.detailCard`, then the built-in look.
    public var style: Style {
        didSet {
            guard style != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKDetailCardView) -> Void)?

    /// The style last resolved against the theme (page style, theme slot, and the card's own).
    public private(set) var resolvedStyle = Style()

    public let cardView = LMKCardView()
    public let contentStack = UIStackView()
    public let headerView = UIView()
    public let headerStack = UIStackView()
    public let headerIconContainer: UIView = LMKSurfaceView()
    public let headerIconView = UIImageView()
    public let headerTextStack = UIStackView()
    public let titleLabel = LMKCopyableLabel()
    public private(set) var subtitleLabels: [UILabel] = []
    public let headerTrailingStack = UIStackView()
    public let loadingIndicator = UIActivityIndicatorView(style: .medium)
    public let rowsStack = UIStackView()
    public let actionsStack = UIStackView()
    /// The action buttons by action id.
    public private(set) var actionButtons: [String: LMKButton] = [:]

    var rowViews: [String: any LMKDetailRowView] = [:]
    private var dividerViews: [LMKDividerView] = []
    private var longPressGestures: [String: UILongPressGestureRecognizer] = [:]
    /// The header's trailing controls, kept across reconfigures when the item at the same
    /// position has the same shape.
    private var headerTrailingItems: [(kind: TrailingKind, view: UIView)] = []
    private lazy var headerTap = UITapGestureRecognizer(target: self, action: #selector(handleHeaderTap))
    private var headerIconSizeConstraint: Constraint?

    /// The shape of a `LMKDetailCard.TrailingItem`, for reuse by position.
    private enum TrailingKind: Equatable {
        case button, textButton, badge, text
        case view(ObjectIdentifier)
    }

    // MARK: - Initialization

    public init(style: Style = Style()) {
        self.style = style
        super.init(frame: .zero)
        setupUI()
        lmk_startApplyingTheme()
    }

    public convenience init(card: LMKDetailCard, style: Style = Style()) {
        self.init(style: style)
        configure(card)
    }

    override public convenience init(frame: CGRect) {
        self.init(style: Style())
        self.frame = frame
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        cardView.contentView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerIconView.contentMode = .scaleAspectFit
        headerIconContainer.addSubview(headerIconView)
        headerIconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        // Just below required: the header stack hides the icon slot with its own constraint.
        headerIconContainer.snp.makeConstraints { make in
            headerIconSizeConstraint = make.width.height.equalTo(24).priority(999).constraint
        }
        headerTextStack.axis = .vertical
        headerTextStack.alignment = .fill
        headerTextStack.addArrangedSubview(titleLabel)
        titleLabel.numberOfLines = 0
        titleLabel.accessibilityTraits = .header
        headerTrailingStack.axis = .horizontal
        headerTrailingStack.alignment = .center
        headerTextStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        headerTextStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        headerTrailingStack.setContentHuggingPriority(.required, for: .horizontal)
        headerTrailingStack.setContentCompressionResistancePriority(.required, for: .horizontal)
        loadingIndicator.hidesWhenStopped = true
        headerTrailingStack.addArrangedSubview(loadingIndicator)
        headerStack.addArrangedSubview(headerIconContainer)
        headerStack.addArrangedSubview(headerTextStack)
        headerStack.addArrangedSubview(headerTrailingStack)
        headerView.addSubview(headerStack)
        headerStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        headerView.addGestureRecognizer(headerTap)
        headerTap.isEnabled = false

        rowsStack.axis = .vertical
        rowsStack.alignment = .fill
        actionsStack.axis = .vertical
        actionsStack.alignment = .fill

        contentStack.addArrangedSubview(headerView)
        contentStack.addArrangedSubview(rowsStack)
        contentStack.addArrangedSubview(actionsStack)
        headerView.isHidden = true
        actionsStack.isHidden = true
    }

    // MARK: - Configuration

    /// Renders `card`, reusing row views whose id and kind match.
    public func configure(_ card: LMKDetailCard) {
        self.card = card
        isHidden = card.isHidden
        applyTheme(traitCollection.lmkTheme)
    }

    /// Re-renders the current card (after a change to `strings`).
    private func reconfigure() {
        guard card != nil else { return }
        applyTheme(traitCollection.lmkTheme)
    }

    /// Changes one row in place. Returns `false` when there is no row with `rowID`.
    @discardableResult
    public func update(rowID: String, _ mutate: (inout LMKDetailCard.Row) -> Void) -> Bool {
        guard var card, let index = card.rows.firstIndex(where: { $0.id == rowID }) else { return false }
        var row = card.rows[index]
        mutate(&row)
        card.rows[index] = row
        self.card = card
        let theme = traitCollection.lmkTheme
        if row.id == rowID, let view = rowViews[rowID], view.kind == row.kind {
            view.update(row, context: rowContext(theme: theme))
        } else {
            applyTheme(theme)
        }
        return true
    }

    /// Sets a key/value row's value (and optionally its color) in place.
    @discardableResult
    public func setValue(_ value: String, color: UIColor? = nil, forRowID rowID: String) -> Bool {
        update(rowID: rowID) { row in
            guard case var .keyValue(keyValue) = row else { return }
            keyValue.value = value
            if let color { keyValue.valueColor = color }
            row = .keyValue(keyValue)
        }
    }

    /// Enables or disables one action button.
    @discardableResult
    public func setAction(_ id: String, enabled: Bool) -> Bool {
        guard var card, let index = card.actions.firstIndex(where: { $0.id == id }) else { return false }
        card.actions[index].isEnabled = enabled
        self.card = card
        actionButtons[id]?.isEnabled = enabled
        return true
    }

    /// Shows or hides the header's activity indicator (visible even without trailing items).
    public func setHeaderLoading(_ loading: Bool) {
        card?.header?.isLoading = loading
        if loading {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
        headerTrailingStack.isHidden = (card?.header?.trailing.isEmpty ?? true) && !loading
    }

    /// The view rendering the row with `rowID`.
    public func view(forRowID rowID: String) -> UIView? {
        rowViews[rowID]
    }

    /// Reloads a photo strip's tiles (after the host's photos changed without a count change).
    public func reloadPhotoStrip(rowID: String) {
        (rowViews[rowID] as? LMKDetailPhotoStripRowView)?.reload()
    }

    // MARK: - Theme

    /// The card surface under `Style.card`: a hairline outline carries the edge in both
    /// appearances (a shadow alone disappears in Dark Mode and smudges a tinted card in light),
    /// and the tightest shadow level lifts the card without a halo.
    static let defaultCardStyle = LMKCardView.Style(surface: LMKSurfaceStyle(border: .solid(), shadow: .level(.level1)))

    public func applyTheme(_ theme: LMKTheme) {
        resolvedStyle = theme.detailCard.merging(style)
        if let cardStyle = card?.style {
            resolvedStyle = resolvedStyle.merging(cardStyle)
        }
        let resolved = resolvedStyle
        cardView.style = Self.defaultCardStyle.merging(resolved.card)
        contentStack.setCustomSpacing(resolved.headerBottomSpacing ?? theme.spacing.medium, after: headerView)
        contentStack.setCustomSpacing(resolved.actionsTopSpacing ?? theme.spacing.large, after: rowsStack)
        applyHeader(theme: theme)
        applyRows(theme: theme)
        applyActions(theme: theme)
        didApplyStyle?(self)
    }

    /// What every row renders against: the card's traits, not the row's, because the card's
    /// trait handler runs before its descendants' traits update.
    private func rowContext(theme: LMKTheme) -> RowContext {
        RowContext(style: resolvedStyle, theme: theme, traits: traitCollection, strings: strings)
    }

    // MARK: - Header

    /// Multi-line labels beside a trailing group in a horizontal stack only wrap correctly once
    /// they know their column width, so the header text gets it from the layout pass.
    override public func layoutSubviews() {
        super.layoutSubviews()
        let width = headerTextStack.bounds.width
        guard width > 0 else { return }
        var changed = false
        for label in [titleLabel] + subtitleLabels where label.preferredMaxLayoutWidth != width {
            label.preferredMaxLayoutWidth = width
            changed = true
        }
        if changed {
            super.layoutSubviews()
        }
    }

    private func applyHeader(theme: LMKTheme) {
        let resolved = resolvedStyle
        guard let header = card?.header else {
            headerView.isHidden = true
            headerTap.isEnabled = false
            return
        }
        headerView.isHidden = false
        headerStack.spacing = resolved.headerSpacing ?? theme.spacing.small
        headerTextStack.spacing = theme.spacing.xxs
        headerTrailingStack.spacing = resolved.headerSpacing ?? theme.spacing.small

        // Icon
        if let icon = header.icon {
            let iconSize = resolved.headerIconSize ?? theme.layout.iconMedium
            let tint = icon.tint ?? resolved.headerIconTint ?? LMKColor.primary
            headerIconView.image = icon.image
            headerIconView.tintColor = tint
            if resolved.headerIconInCircle ?? false {
                let circle = theme.layout.iconCircle
                headerIconSizeConstraint?.update(offset: circle)
                _ = headerIconContainer.lmk_apply(surface: LMKSurfaceStyle(background: .solid(tint.withAlphaComponent(theme.alpha.xxs)), corners: .circle))
                headerIconView.snp.remakeConstraints { make in
                    make.center.equalToSuperview()
                    make.width.height.equalTo(iconSize)
                }
            } else {
                headerIconSizeConstraint?.update(offset: iconSize)
                _ = headerIconContainer.lmk_apply(surface: LMKSurfaceStyle(background: .clear, corners: LMKCornerStyle.square))
                headerIconView.snp.remakeConstraints { make in
                    make.edges.equalToSuperview()
                }
            }
            headerIconContainer.isHidden = false
        } else {
            headerIconContainer.isHidden = true
        }

        // Title and subtitles
        titleLabel.lmk_apply(header.titleTextStyle ?? resolved.headerTitleTextStyle ?? .h3, color: resolved.headerTitleColor ?? LMKColor.textPrimary)
        titleLabel.lmk_setText(header.title)
        titleLabel.isCopyEnabled = header.isCopyable
        while subtitleLabels.count < header.subtitles.count {
            let label = UILabel()
            label.numberOfLines = 0
            subtitleLabels.append(label)
            headerTextStack.addArrangedSubview(label)
        }
        for (index, label) in subtitleLabels.enumerated() {
            let visible = index < header.subtitles.count
            label.isHidden = !visible
            guard visible else { continue }
            label.lmk_apply(resolved.headerSubtitleTextStyle ?? .caption, color: resolved.headerSubtitleColor ?? LMKColor.textSecondary)
            label.lmk_setText(header.subtitles[index])
        }

        // Trailing items
        applyTrailingItems(header.trailing)
        loadingIndicator.color = LMKColor.textSecondary
        loadingIndicator.accessibilityLabel = strings.loadingAccessibilityLabel
        if header.isLoading {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
        headerTrailingStack.isHidden = header.trailing.isEmpty && !header.isLoading

        // Tap
        headerTap.isEnabled = header.onTap != nil
        var traits: UIAccessibilityTraits = .header
        if header.onTap != nil { traits.insert(.button) }
        titleLabel.accessibilityTraits = traits
    }

    /// Updates the trailing controls in place where the item at a position keeps its shape,
    /// creates the rest, and drops the surplus (a host's `.view` only while it is still ours).
    private func applyTrailingItems(_ items: [LMKDetailCard.TrailingItem]) {
        var kept: [(kind: TrailingKind, view: UIView)] = []
        for (index, item) in items.enumerated() {
            let kind = Self.trailingKind(of: item)
            let view: UIView
            if index < headerTrailingItems.count, headerTrailingItems[index].kind == kind, headerTrailingItems[index].view.superview === headerTrailingStack {
                view = headerTrailingItems[index].view
                updateTrailingView(view, with: item)
            } else {
                view = makeTrailingView(item)
            }
            kept.append((kind, view))
        }
        for entry in headerTrailingItems where !kept.contains(where: { $0.view === entry.view }) && entry.view.superview === headerTrailingStack {
            headerTrailingStack.removeArrangedSubview(entry.view)
            entry.view.removeFromSuperview()
        }
        for (index, entry) in kept.enumerated() where headerTrailingStack.arrangedSubviews[lmk_safe: index] !== entry.view {
            headerTrailingStack.insertArrangedSubview(entry.view, at: index)
        }
        headerTrailingItems = kept
    }

    private static func trailingKind(of item: LMKDetailCard.TrailingItem) -> TrailingKind {
        switch item {
        case .button: .button
        case .textButton: .textButton
        case .badge: .badge
        case .text: .text
        case let .view(view): .view(ObjectIdentifier(view))
        }
    }

    private func makeTrailingView(_ item: LMKDetailCard.TrailingItem) -> UIView {
        let resolved = resolvedStyle
        let view: UIView = switch item {
        case let .button(systemName, _, _):
            LMKButton(systemImage: systemName, style: LMKButton.Style.iconOnly(.secondary).merging(resolved.headerButton))
        case .textButton:
            LMKButton(style: LMKButton.Style.ghost(.secondary).size(.small).merging(resolved.headerButton))
        case .badge:
            LMKBadgeView()
        case .text:
            UILabel.lmk_make(.caption, color: LMKColor.textSecondary)
        case let .view(view):
            view
        }
        // The nested stack's own hugging is not what the header stack distributes by; the items
        // themselves must refuse the spare width so the title column gets it.
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        updateTrailingView(view, with: item)
        return view
    }

    private func updateTrailingView(_ view: UIView, with item: LMKDetailCard.TrailingItem) {
        let resolved = resolvedStyle
        switch item {
        case let .button(systemName, accessibilityLabel, onTap):
            guard let button = view as? LMKButton else { return }
            button.style = LMKButton.Style.iconOnly(.secondary).merging(resolved.headerButton)
            button.setSymbol(systemName)
            button.accessibilityLabel = accessibilityLabel
            button.onTap = onTap
        case let .textButton(title, onTap):
            guard let button = view as? LMKButton else { return }
            button.style = LMKButton.Style.ghost(.secondary).size(.small).merging(resolved.headerButton)
            button.title = title
            button.onTap = onTap
        case let .badge(content):
            (view as? LMKBadgeView)?.configure(content)
        case let .text(text):
            (view as? UILabel)?.lmk_setText(text)
        case .view:
            break
        }
    }

    @objc private func handleHeaderTap() {
        card?.header?.onTap?()
    }

    // MARK: - Rows

    private func applyRows(theme: LMKTheme) {
        let resolved = resolvedStyle
        let rows = card?.rows ?? []
        let context = rowContext(theme: theme)
        rowsStack.spacing = resolved.rowSpacing ?? theme.spacing.medium
        for view in rowsStack.arrangedSubviews {
            rowsStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        var kept: [String: any LMKDetailRowView] = [:]
        var dividerIndex = 0
        let showsDividers = resolved.showsRowDividers ?? false
        for (index, row) in rows.enumerated() {
            let view: any LMKDetailRowView = if let existing = rowViews[row.id], existing.kind == row.kind {
                existing
            } else {
                makeRowView(row)
            }
            view.update(row, context: context)
            kept[row.id] = view
            if showsDividers, index > 0 {
                if dividerIndex >= dividerViews.count {
                    dividerViews.append(LMKDividerView())
                }
                rowsStack.addArrangedSubview(dividerViews[dividerIndex])
                dividerIndex += 1
            }
            rowsStack.addArrangedSubview(view)
        }
        rowViews = kept
        rowsStack.isHidden = rows.isEmpty
    }

    private func makeRowView(_ row: LMKDetailCard.Row) -> any LMKDetailRowView {
        switch row {
        case .keyValue: LMKDetailKeyValueRowView(rowID: row.id)
        case .text: LMKDetailTextRowView(rowID: row.id)
        case .chips: LMKDetailChipsRowView(rowID: row.id)
        case .photoStrip: LMKDetailPhotoStripRowView(rowID: row.id)
        case .progress: LMKDetailProgressRowView(rowID: row.id)
        case .navigation: LMKDetailNavigationRowView(rowID: row.id)
        case .link: LMKDetailLinkRowView(rowID: row.id)
        case .rating: LMKDetailRatingRowView(rowID: row.id)
        case .image: LMKDetailImageRowView(rowID: row.id)
        case .divider: LMKDetailDividerRowView(rowID: row.id)
        case .custom: LMKDetailCustomRowView(rowID: row.id)
        }
    }

    // MARK: - Actions

    private func applyActions(theme: LMKTheme) {
        let resolved = resolvedStyle
        let actions = card?.actions ?? []
        for view in actionsStack.arrangedSubviews {
            actionsStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        actionsStack.isHidden = actions.isEmpty
        guard !actions.isEmpty else {
            actionButtons = [:]
            longPressGestures = [:]
            return
        }
        let spacing = resolved.actionSpacing ?? theme.spacing.small
        actionsStack.spacing = spacing
        var buttons: [String: LMKButton] = [:]
        var gestures: [String: UILongPressGestureRecognizer] = [:]
        let ordered: [LMKButton] = actions.map { action in
            let button = actionButtons[action.id] ?? LMKButton()
            button.title = action.title
            button.image = action.image
            button.style = action.style ?? resolved.actionButtonStyle(for: action.role)
            button.isEnabled = action.isEnabled
            button.onTap = action.onTap
            button.accessibilityIdentifier = action.id
            if let existing = longPressGestures[action.id] {
                button.removeGestureRecognizer(existing)
            }
            if action.onLongPress != nil {
                let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleActionLongPress(_:)))
                gesture.name = action.id
                button.addGestureRecognizer(gesture)
                gestures[action.id] = gesture
            }
            buttons[action.id] = button
            return button
        }
        actionButtons = buttons
        longPressGestures = gestures

        func pairRows(_ buttons: ArraySlice<LMKButton>) {
            var index = buttons.startIndex
            while index < buttons.endIndex {
                let next = buttons.index(after: index)
                if next < buttons.endIndex {
                    let row = UIStackView(lmk_axis: .horizontal, spacing: spacing, distribution: .fillEqually, arrangedSubviews: [buttons[index], buttons[next]])
                    actionsStack.addArrangedSubview(row)
                    index = buttons.index(after: next)
                } else {
                    actionsStack.addArrangedSubview(buttons[index])
                    index = next
                }
            }
        }

        switch card?.actionsLayout ?? .stacked {
        case .stacked:
            ordered.forEach(actionsStack.addArrangedSubview)
        case .pairs:
            pairRows(ordered[...])
        case .leadingPrimary:
            if let first = ordered.first { actionsStack.addArrangedSubview(first) }
            pairRows(ordered.dropFirst())
        case .inline:
            actionsStack.addArrangedSubview(UIStackView(lmk_axis: .horizontal, spacing: spacing, distribution: .fillEqually, arrangedSubviews: ordered))
        }
    }

    @objc private func handleActionLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, let id = gesture.name, let action = card?.actions.first(where: { $0.id == id }), action.isEnabled else { return }
        if resolvedStyle.haptics ?? true { LMKHaptics.selection() }
        action.onLongPress?()
    }
}

// MARK: - Row view protocol

extension LMKDetailCardView {
    /// What a row renders against: the resolved style, the theme, the card's trait collection
    /// (for Dynamic Type decisions), and the card's strings.
    struct RowContext {
        let style: Style
        let theme: LMKTheme
        let traits: UITraitCollection
        let strings: Strings
    }
}

/// A view rendering one `LMKDetailCard.Row`, updated in place across reconfigures.
protocol LMKDetailRowView: UIView {
    var rowID: String { get }
    /// The row kind this view renders (`LMKDetailCard.Row.kind`).
    var kind: Int { get }
    func update(_ row: LMKDetailCard.Row, context: LMKDetailCardView.RowContext)
}
