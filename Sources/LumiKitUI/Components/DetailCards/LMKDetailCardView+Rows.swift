//
//  LMKDetailCardView+Rows.swift
//  LumiKit
//
//  The row views of a detail card: key/value, text, chips, progress,
//  navigation, link, rating, image, divider, custom. Each renders one
//  `LMKDetailCard.Row` against the card's `RowContext` and updates in place.
//

import LumiKitCore
import SnapKit
import UIKit

// MARK: - Key / value

final class LMKDetailKeyValueRowView: UIView, LMKDetailRowView {
    let rowID: String
    let kind = 0
    let outerStack = UIStackView()
    let pairStack = UIStackView()
    let keyLabel = UILabel()
    let valueLabel = LMKCopyableLabel()
    let descriptionLabel = UILabel()
    private var onTap: (() -> Void)?
    private lazy var tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))

    init(rowID: String) {
        self.rowID = rowID
        super.init(frame: .zero)
        outerStack.axis = .vertical
        outerStack.alignment = .fill
        keyLabel.numberOfLines = 0
        valueLabel.numberOfLines = 0
        descriptionLabel.numberOfLines = 0
        pairStack.addArrangedSubview(keyLabel)
        pairStack.addArrangedSubview(valueLabel)
        outerStack.addArrangedSubview(pairStack)
        outerStack.addArrangedSubview(descriptionLabel)
        addSubview(outerStack)
        outerStack.snp.makeConstraints { $0.edges.equalToSuperview() }
        addGestureRecognizer(tap)
        isAccessibilityElement = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(_ row: LMKDetailCard.Row, context: LMKDetailCardView.RowContext) {
        guard case let .keyValue(model) = row else { return }
        let style = context.style
        let theme = context.theme
        // At accessibility text sizes an inline pair leaves the value a few characters of width, so it stacks.
        let inline = model.layout == .inline && !context.traits.preferredContentSizeCategory.isAccessibilityCategory
        pairStack.axis = inline ? .horizontal : .vertical
        pairStack.alignment = inline ? .firstBaseline : .fill
        pairStack.spacing = style.keyValueSpacing ?? (inline ? theme.spacing.small : theme.spacing.xs)
        outerStack.spacing = theme.spacing.xs
        keyLabel.lmk_apply(inline ? (style.inlineKeyTextStyle ?? .subbodyMedium) : (style.stackedKeyTextStyle ?? .captionMedium), color: style.keyColor ?? LMKColor.textSecondary)
        keyLabel.lmk_setText(model.key)
        keyLabel.setContentHuggingPriority(inline ? .required : .defaultLow, for: .horizontal)
        keyLabel.setContentCompressionResistancePriority(inline ? .required : .defaultHigh, for: .horizontal)
        valueLabel.lmk_apply(style.valueTextStyle ?? .body, color: model.valueColor ?? style.valueColor ?? LMKColor.textPrimary)
        valueLabel.lmk_setText(model.value)
        // The inline value sits against the trailing edge, which is the left one in RTL.
        let trailing: NSTextAlignment = effectiveUserInterfaceLayoutDirection == .rightToLeft ? .left : .right
        valueLabel.textAlignment = inline ? (style.inlineValueAlignment ?? trailing) : .natural
        valueLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        valueLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        valueLabel.isCopyEnabled = model.isCopyable
        valueLabel.copyTextProvider = model.copyText.map { text in { text } }
        descriptionLabel.lmk_apply(style.descriptionTextStyle ?? .caption, color: style.descriptionColor ?? LMKColor.textSecondary)
        descriptionLabel.lmk_setText(model.description)
        descriptionLabel.isHidden = model.description == nil
        onTap = model.onTap
        tap.isEnabled = model.onTap != nil

        accessibilityLabel = model.key
        accessibilityValue = [model.value, model.description].compactMap(\.self).joined(separator: ", ")
        accessibilityTraits = model.onTap != nil ? .button : .staticText
        accessibilityCustomActions = model.isCopyable ? [UIAccessibilityCustomAction(name: valueLabel.strings.copy) { [weak self] _ in self?.valueLabel.copyToPasteboard() ?? false }] : nil
    }

    @objc private func handleTap() {
        onTap?()
    }
}

// MARK: - Text

final class LMKDetailTextRowView: UIView, LMKDetailRowView {
    let rowID: String
    let kind = 1
    let stack = UIStackView()
    let titleLabel = UILabel()
    /// Plain content, styled through `lmk_apply`.
    let textLabel = UILabel()
    /// Markdown and attributed content. It never goes through `lmk_apply`: a label whose font is
    /// re-applied on a Dynamic Type change flattens its runs to that one font, so this label
    /// re-renders the rich string itself from its own trait handler.
    let richTextLabel = UILabel()
    private var content: LMKDetailCard.TextContent?
    private var textStyle: LMKTextStyle = .body
    private var color: UIColor = LMKColor.textPrimary

    init(rowID: String) {
        self.rowID = rowID
        super.init(frame: .zero)
        stack.axis = .vertical
        stack.alignment = .fill
        titleLabel.numberOfLines = 0
        titleLabel.accessibilityTraits = .header
        textLabel.numberOfLines = 0
        richTextLabel.numberOfLines = 0
        richTextLabel.isHidden = true
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(textLabel)
        stack.addArrangedSubview(richTextLabel)
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self, LMKThemeTrait.self]) { (view: Self, _) in
            view.applyRichText(traits: view.traitCollection)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(_ row: LMKDetailCard.Row, context: LMKDetailCardView.RowContext) {
        guard case let .text(model) = row else { return }
        let style = context.style
        let theme = context.theme
        stack.spacing = theme.spacing.small
        titleLabel.lmk_apply(style.textTitleTextStyle ?? .h4, color: style.textColor ?? LMKColor.textPrimary)
        titleLabel.lmk_setText(model.title)
        titleLabel.isHidden = model.title == nil
        textStyle = model.textStyle ?? style.textStyle ?? .body
        color = model.color ?? style.textColor ?? LMKColor.textPrimary
        content = model.content
        textLabel.lmk_apply(textStyle, color: color)
        if case let .plain(text) = model.content {
            textLabel.lmk_setText(text)
            textLabel.isHidden = false
            richTextLabel.isHidden = true
        } else {
            textLabel.isHidden = true
            richTextLabel.isHidden = false
            applyRichText(traits: context.traits)
        }
    }

    /// Renders markdown at the font `traits` resolve to, or the attributed string as the host gave it.
    private func applyRichText(traits: UITraitCollection) {
        switch content {
        case let .markdown(markdown):
            let font = traits.lmkTheme.typography.font(for: textStyle, compatibleWith: traits)
            richTextLabel.attributedText = LMKMarkdownRenderer.render(markdown, font: font, color: color)
        case let .attributed(attributed):
            richTextLabel.attributedText = attributed
        case .plain, nil:
            break
        }
    }
}

// MARK: - Chips

final class LMKDetailChipsRowView: UIView, LMKDetailRowView {
    let rowID: String
    let kind = 2
    let scrollView = UIScrollView()
    let stack = UIStackView()
    private(set) var chips: [LMKChipView] = []
    private var chipIDs: [String] = []

    init(rowID: String) {
        self.rowID = rowID
        super.init(frame: .zero)
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.clipsToBounds = false
        stack.axis = .horizontal
        stack.alignment = .center
        addSubview(scrollView)
        scrollView.addSubview(stack)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(scrollView)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Chips are reused by `Chip.id`, so a reconfigure restyles them in place instead of
    /// rebuilding the row.
    func update(_ row: LMKDetailCard.Row, context: LMKDetailCardView.RowContext) {
        guard case let .chips(model) = row else { return }
        let style = context.style
        stack.spacing = style.chipSpacing ?? context.theme.spacing.small
        var existing = Dictionary(zip(chipIDs, chips), uniquingKeysWith: { first, _ in first })
        var ordered: [LMKChipView] = []
        for item in model.items {
            let chip = existing.removeValue(forKey: item.id) ?? LMKChipView(text: item.text, icon: item.icon)
            chip.text = item.text
            chip.icon = item.icon
            chip.style = item.tint.map { style.chip.tint($0) } ?? style.chip
            chip.onTap = item.onTap
            chip.accessibilityIdentifier = item.id
            ordered.append(chip)
        }
        for chip in existing.values {
            stack.removeArrangedSubview(chip)
            chip.removeFromSuperview()
        }
        for (index, chip) in ordered.enumerated() where stack.arrangedSubviews[lmk_safe: index] !== chip {
            stack.insertArrangedSubview(chip, at: index)
        }
        chips = ordered
        chipIDs = model.items.map(\.id)
    }
}

// MARK: - Progress

final class LMKDetailProgressRowView: UIView, LMKDetailRowView {
    let rowID: String
    let kind = 4
    let stack = UIStackView()
    let textRow = UIStackView()
    let titleLabel = UILabel()
    let detailLabel = UILabel()
    let trackView: UIView = LMKSurfaceView()
    let barView: UIView = LMKSurfaceView()
    private var heightConstraint: Constraint?

    init(rowID: String) {
        self.rowID = rowID
        super.init(frame: .zero)
        stack.axis = .vertical
        stack.alignment = .fill
        textRow.axis = .horizontal
        textRow.alignment = .firstBaseline
        titleLabel.numberOfLines = 0
        detailLabel.textAlignment = .right
        detailLabel.setContentHuggingPriority(.required, for: .horizontal)
        detailLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        textRow.addArrangedSubview(titleLabel)
        textRow.addArrangedSubview(detailLabel)
        trackView.addSubview(barView)
        trackView.snp.makeConstraints { make in
            heightConstraint = make.height.equalTo(8).constraint
        }
        barView.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalTo(0)
        }
        stack.addArrangedSubview(textRow)
        stack.addArrangedSubview(trackView)
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
        isAccessibilityElement = true
        accessibilityTraits = .staticText
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// The fraction the bar shows (`0 ... 1`).
    private(set) var value: Float = 0

    func update(_ row: LMKDetailCard.Row, context: LMKDetailCardView.RowContext) {
        guard case let .progress(model) = row else { return }
        let style = context.style
        let theme = context.theme
        // The model clamps too; a non-finite multiplier would still throw inside Auto Layout.
        let fraction = model.value.isFinite ? min(max(model.value, 0), 1) : 0
        value = fraction
        stack.spacing = theme.spacing.xs
        textRow.spacing = theme.spacing.medium
        titleLabel.lmk_apply(style.stackedKeyTextStyle ?? .captionMedium, color: style.keyColor ?? LMKColor.textSecondary)
        titleLabel.lmk_setText(model.title)
        detailLabel.lmk_apply(style.descriptionTextStyle ?? .caption, color: style.valueColor ?? LMKColor.textPrimary)
        detailLabel.lmk_setText(model.detail)
        detailLabel.isHidden = model.detail == nil
        heightConstraint?.update(offset: style.progressHeight ?? theme.spacing.small)
        _ = trackView.lmk_apply(surface: LMKSurfaceStyle(background: .solid(style.progressTrackColor ?? LMKColor.fill), corners: .capsule))
        _ = barView.lmk_apply(surface: LMKSurfaceStyle(background: .solid(model.tint ?? style.progressTint ?? LMKColor.primary), corners: .capsule))
        barView.snp.remakeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalTo(trackView).multipliedBy(CGFloat(fraction))
        }
        accessibilityLabel = model.title
        accessibilityValue = model.detail ?? LMKFormat.progressPercent(fraction)
    }
}

// MARK: - Navigation

final class LMKDetailNavigationRowView: UIControl, LMKDetailRowView {
    let rowID: String
    let kind = 5
    private(set) var contentView: LMKListRowContentView?
    private var onTap: (() -> Void)?
    private var configuration: LMKListRowConfiguration?
    private var surface = LMKSurfaceStyle()

    init(rowID: String) {
        self.rowID = rowID
        super.init(frame: .zero)
        isAccessibilityElement = false
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        addInteraction(UIPointerInteraction(delegate: self))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        lmk_layoutSurfaceIfNeeded()
    }

    /// The press reaches the row through the configuration state, as a cell's would.
    override var isHighlighted: Bool {
        didSet {
            guard isHighlighted != oldValue, var configuration else { return }
            configuration.isHighlighted = isHighlighted
            contentView?.configuration = configuration
        }
    }

    /// The pressed look a navigation row shows on its own (a cell would show its background's).
    static let defaultRowStyle = LMKListRowConfiguration.Style(highlighted: LMKControlStateStyle(background: .solid(LMKColor.pressedOverlay)))

    func update(_ row: LMKDetailCard.Row, context: LMKDetailCardView.RowContext) {
        guard case let .navigation(model) = row else { return }
        let style = context.style
        var configuration = model.configuration
        configuration.trailing = .disclosure
        configuration.style = Self.defaultRowStyle.merging(style.navigationRow).merging(configuration.style)
        configuration.isHighlighted = isHighlighted
        self.configuration = configuration
        onTap = model.onTap
        surface = style.navigationRowSurface
        let resolvedSurface = lmk_apply(surface: surface, defaults: LMKSurfaceStyle(background: .clear), clipsContent: false)
        if let contentView {
            contentView.stateBackgroundCorners = resolvedSurface.corners ?? .square
            contentView.configuration = configuration
        } else {
            let content = LMKListRowContentView(configuration: configuration)
            content.stateBackgroundCorners = resolvedSurface.corners ?? .square
            content.isUserInteractionEnabled = false
            addSubview(content)
            content.snp.makeConstraints { $0.edges.equalToSuperview() }
            contentView = content
        }
    }

    @objc private func handleTap() {
        onTap?()
    }
}

extension LMKDetailNavigationRowView: UIPointerInteractionDelegate {
    func pointerInteraction(_: UIPointerInteraction, styleFor _: UIPointerRegion) -> UIPointerStyle? {
        LMKPointerStyle.hover(for: self)
    }
}

// MARK: - Link

final class LMKDetailLinkRowView: UIView, LMKDetailRowView {
    let rowID: String
    let kind = 6
    let openControl: UIControl = LMKHitExpandingControl()
    let openStack = UIStackView()
    let iconView = UIImageView()
    let textStack = UIStackView()
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let removeButton = LMKButton(systemImage: "trash", style: .iconOnly(.neutral))
    private var model: LMKDetailCard.Link?

    init(rowID: String) {
        self.rowID = rowID
        super.init(frame: .zero)
        let row = UIStackView(lmk_axis: .horizontal, alignment: .center)
        openStack.axis = .horizontal
        openStack.alignment = .center
        openStack.isUserInteractionEnabled = false
        iconView.contentMode = .scaleAspectFit
        textStack.axis = .vertical
        textStack.alignment = .fill
        titleLabel.numberOfLines = 0
        subtitleLabel.numberOfLines = 1
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)
        openStack.addArrangedSubview(iconView)
        openStack.addArrangedSubview(textStack)
        openControl.addSubview(openStack)
        openStack.snp.makeConstraints { $0.edges.equalToSuperview() }
        openControl.isAccessibilityElement = true
        openControl.accessibilityTraits = .link
        openControl.addTarget(self, action: #selector(handleOpen), for: .touchUpInside)
        removeButton.onTap = { [weak self] in self?.model?.onRemove?() }
        row.addArrangedSubview(openControl)
        row.addArrangedSubview(removeButton)
        openControl.setContentHuggingPriority(.defaultLow, for: .horizontal)
        removeButton.setContentHuggingPriority(.required, for: .horizontal)
        addSubview(row)
        row.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(_ row: LMKDetailCard.Row, context: LMKDetailCardView.RowContext) {
        guard case let .link(model) = row else { return }
        let style = context.style
        let theme = context.theme
        self.model = model
        openStack.spacing = theme.spacing.medium
        textStack.spacing = theme.spacing.xxs
        let linkColor = style.linkColor ?? LMKColor.link
        if let icon = model.icon {
            iconView.image = icon.image
            iconView.tintColor = icon.tint ?? LMKColor.primary
            iconView.snp.remakeConstraints { make in
                make.width.height.equalTo(theme.layout.iconMedium).priority(999)
            }
            iconView.isHidden = false
        } else {
            iconView.isHidden = true
        }
        let textStyle = style.linkTextStyle ?? .bodyMedium
        titleLabel.lmk_apply(textStyle, color: linkColor)
        if style.underlinesLinks ?? false {
            titleLabel.attributedText = NSAttributedString(string: model.title, attributes: [
                .font: theme.typography.font(for: textStyle, compatibleWith: context.traits),
                .foregroundColor: linkColor,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
            ])
        } else {
            titleLabel.lmk_setText(model.title)
        }
        subtitleLabel.lmk_apply(style.descriptionTextStyle ?? .caption, color: style.descriptionColor ?? LMKColor.textSecondary)
        subtitleLabel.lmk_setText(model.subtitle)
        subtitleLabel.isHidden = model.subtitle == nil
        removeButton.isHidden = model.onRemove == nil
        removeButton.accessibilityLabel = context.strings.removeLinkAccessibilityLabel
        openControl.accessibilityLabel = model.title
        openControl.accessibilityValue = model.subtitle ?? model.url?.host
    }

    @objc private func handleOpen() {
        guard let model else { return }
        if let onOpen = model.onOpen {
            onOpen()
        } else if let url = model.url {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Rating

final class LMKDetailRatingRowView: UIView, LMKDetailRowView {
    let rowID: String
    let kind = 7
    let stack = UIStackView()
    let titleLabel = UILabel()
    let ratingControl = LMKRatingControl()

    init(rowID: String) {
        self.rowID = rowID
        super.init(frame: .zero)
        stack.axis = .horizontal
        stack.alignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        ratingControl.setContentHuggingPriority(.required, for: .horizontal)
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(ratingControl)
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(_ row: LMKDetailCard.Row, context: LMKDetailCardView.RowContext) {
        guard case let .rating(model) = row else { return }
        let style = context.style
        stack.spacing = context.theme.spacing.medium
        titleLabel.lmk_apply(style.inlineKeyTextStyle ?? .subbodyMedium, color: style.keyColor ?? LMKColor.textSecondary)
        titleLabel.lmk_setText(model.title)
        ratingControl.style = style.rating
        ratingControl.maximum = max(1, model.maximum)
        ratingControl.value = model.value
        ratingControl.isInteractive = model.onValueChange != nil
        ratingControl.onValueChange = model.onValueChange
        ratingControl.accessibilityLabel = model.title
    }
}

// MARK: - Image

final class LMKDetailImageRowView: UIView, LMKDetailRowView {
    let rowID: String
    let kind = 8
    let imageView = UIImageView()
    private var loadTask: Task<Void, Never>?
    private var generation = 0
    private var onTap: (() -> Void)?
    private var maxHeight: CGFloat = LMKDetailImageRowView.defaultMaxHeight
    private lazy var tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))

    /// The height cap behind `Style.imageMaxHeight == nil`.
    static let defaultMaxHeight: CGFloat = 240

    init(rowID: String) {
        self.rowID = rowID
        super.init(frame: .zero)
        imageView.clipsToBounds = true
        addSubview(imageView)
        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        addGestureRecognizer(tap)
        isAccessibilityElement = true
        accessibilityTraits = .image
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        loadTask?.cancel()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.lmk_layoutSurfaceIfNeeded()
    }

    /// A row with a `load` keeps the image it has while the next load runs, so a reconfigure
    /// never collapses the page; it hides only while there has never been one.
    func update(_ row: LMKDetailCard.Row, context: LMKDetailCardView.RowContext) {
        guard case let .image(model) = row else { return }
        let style = context.style
        let theme = context.theme
        maxHeight = model.maxHeight ?? style.imageMaxHeight ?? Self.defaultMaxHeight
        imageView.contentMode = model.contentMode
        _ = imageView.lmk_apply(surface: LMKSurfaceStyle(
            background: .solid(style.imageBackgroundColor ?? LMKColor.backgroundSecondary),
            corners: style.imageCorners ?? .fixed(theme.cornerRadius.medium)
        ))
        onTap = model.onTap
        tap.isEnabled = model.onTap != nil
        accessibilityLabel = model.accessibilityLabel
        var traits: UIAccessibilityTraits = .image
        if model.onTap != nil { traits.insert(.button) }
        accessibilityTraits = traits
        loadTask?.cancel()
        generation += 1
        let current = generation
        if let image = model.image {
            setImage(image)
        } else if let load = model.load {
            setImage(imageView.image)
            loadTask = Task { [weak self] in
                let image = await load()
                guard let self, current == generation, !Task.isCancelled else { return }
                setImage(image)
            }
        } else {
            setImage(nil)
        }
    }

    /// Binds the height to the image's aspect ratio, capped at `maxHeight`; hides without an image.
    private func setImage(_ image: UIImage?) {
        imageView.image = image
        guard let image, image.size.width > 0 else {
            isHidden = true
            return
        }
        isHidden = false
        let aspect = image.size.height / image.size.width
        imageView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(imageView.snp.width).multipliedBy(aspect).priority(.high)
            make.height.lessThanOrEqualTo(maxHeight)
        }
    }

    @objc private func handleTap() {
        onTap?()
    }
}

// MARK: - Divider and custom

final class LMKDetailDividerRowView: UIView, LMKDetailRowView {
    let rowID: String
    let kind = 9
    let divider = LMKDividerView()

    init(rowID: String) {
        self.rowID = rowID
        super.init(frame: .zero)
        addSubview(divider)
        divider.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(_: LMKDetailCard.Row, context _: LMKDetailCardView.RowContext) {}
}

final class LMKDetailCustomRowView: UIView, LMKDetailRowView {
    let rowID: String
    let kind = 10
    private(set) weak var hostedView: UIView?

    init(rowID: String) {
        self.rowID = rowID
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Hosts the view; a previous one is removed only while it is still ours (another row may
    /// have taken it), and the same view is re-added when something else took it meanwhile.
    func update(_ row: LMKDetailCard.Row, context _: LMKDetailCardView.RowContext) {
        guard case let .custom(_, view) = row else { return }
        if let old = hostedView, old !== view, old.superview === self {
            old.removeFromSuperview()
        }
        hostedView = view
        guard view.superview !== self else { return }
        addSubview(view)
        view.snp.remakeConstraints { $0.edges.equalToSuperview() }
    }
}
