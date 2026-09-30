//
//  LMKDetailCardView+Rows.swift
//  LumiKit
//
//  The row views of a detail card: key/value, text, chips, progress,
//  navigation, link, rating, image, divider, custom. Each renders one
//  `LMKDetailCard.Row` and updates in place.
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

    func update(_ row: LMKDetailCard.Row, style: LMKDetailCardView.Style, theme: LMKTheme) {
        guard case let .keyValue(model) = row else { return }
        // At accessibility text sizes an inline pair leaves the value a few characters of width, so it stacks.
        let inline = model.layout == .inline && !traitCollection.preferredContentSizeCategory.isAccessibilityCategory
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
        valueLabel.textAlignment = inline ? (style.inlineValueAlignment ?? .right) : .natural
        valueLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        valueLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        valueLabel.isCopyEnabled = model.isCopyable
        valueLabel.copyTextProvider = model.copyText.map { text in { text } }
        descriptionLabel.lmk_apply(style.descriptionTextStyle ?? .caption, color: style.descriptionColor ?? LMKColor.textTertiary)
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
    let textLabel = UILabel()

    init(rowID: String) {
        self.rowID = rowID
        super.init(frame: .zero)
        stack.axis = .vertical
        stack.alignment = .fill
        titleLabel.numberOfLines = 0
        titleLabel.accessibilityTraits = .header
        textLabel.numberOfLines = 0
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(textLabel)
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(_ row: LMKDetailCard.Row, style: LMKDetailCardView.Style, theme: LMKTheme) {
        guard case let .text(model) = row else { return }
        stack.spacing = theme.spacing.small
        titleLabel.lmk_apply(style.textTitleTextStyle ?? .h4, color: style.textColor ?? LMKColor.textPrimary)
        titleLabel.lmk_setText(model.title)
        titleLabel.isHidden = model.title == nil
        let textStyle = model.textStyle ?? style.textStyle ?? .body
        let color = model.color ?? style.textColor ?? LMKColor.textPrimary
        textLabel.lmk_apply(textStyle, color: color)
        switch model.content {
        case let .plain(text):
            textLabel.lmk_setText(text)
        case let .markdown(markdown):
            textLabel.attributedText = LMKMarkdownRenderer.render(markdown, font: LMKTypography.font(for: textStyle, compatibleWith: traitCollection), color: color)
        case let .attributed(attributed):
            textLabel.attributedText = attributed
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

    func update(_ row: LMKDetailCard.Row, style: LMKDetailCardView.Style, theme: LMKTheme) {
        guard case let .chips(model) = row else { return }
        stack.spacing = style.chipSpacing ?? theme.spacing.small
        for chip in chips {
            stack.removeArrangedSubview(chip)
            chip.removeFromSuperview()
        }
        chips = model.items.map { item in
            let chipStyle = item.tint.map { style.chip.tint($0) } ?? style.chip
            let chip = LMKChipView(text: item.text, icon: item.icon, style: chipStyle)
            chip.onTap = item.onTap
            chip.accessibilityIdentifier = item.id
            stack.addArrangedSubview(chip)
            return chip
        }
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

    private(set) var value: Float = 0

    func update(_ row: LMKDetailCard.Row, style: LMKDetailCardView.Style, theme: LMKTheme) {
        guard case let .progress(model) = row else { return }
        value = model.value
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
            make.width.equalTo(trackView).multipliedBy(CGFloat(model.value))
        }
        accessibilityLabel = model.title
        accessibilityValue = model.detail ?? LMKFormat.progressPercent(model.value)
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

    override var isHighlighted: Bool {
        didSet {
            guard isHighlighted != oldValue, var configuration else { return }
            configuration.isHighlighted = isHighlighted
            contentView?.configuration = configuration
        }
    }

    func update(_ row: LMKDetailCard.Row, style: LMKDetailCardView.Style, theme _: LMKTheme) {
        guard case let .navigation(model) = row else { return }
        var configuration = model.configuration
        configuration.trailing = .disclosure
        configuration.style = style.navigationRow.merging(configuration.style)
        self.configuration = configuration
        onTap = model.onTap
        if let contentView {
            contentView.configuration = configuration
        } else {
            let view = LMKListRowContentView(configuration: configuration)
            view.isUserInteractionEnabled = false
            addSubview(view)
            view.snp.makeConstraints { $0.edges.equalToSuperview() }
            contentView = view
        }
        surface = style.navigationRowSurface
        _ = lmk_apply(surface: surface, defaults: LMKSurfaceStyle(background: .clear), clipsContent: false)
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
    private let strings: LMKDetailCardView.Strings
    private var model: LMKDetailCard.Link?

    init(rowID: String, strings: LMKDetailCardView.Strings) {
        self.rowID = rowID
        self.strings = strings
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

    func update(_ row: LMKDetailCard.Row, style: LMKDetailCardView.Style, theme: LMKTheme) {
        guard case let .link(model) = row else { return }
        self.model = model
        openStack.spacing = theme.spacing.medium
        textStack.spacing = theme.spacing.xxs
        let linkColor = style.linkColor ?? LMKColor.link
        if let icon = model.icon {
            iconView.image = icon.image
            iconView.tintColor = icon.tint ?? LMKColor.primary
            iconView.snp.remakeConstraints { make in
                make.width.height.equalTo(theme.layout.iconMedium)
            }
            iconView.isHidden = false
        } else {
            iconView.isHidden = true
        }
        let textStyle = style.linkTextStyle ?? .bodyMedium
        titleLabel.lmk_apply(textStyle, color: linkColor)
        if style.underlinesLinks ?? false {
            titleLabel.attributedText = NSAttributedString(string: model.title, attributes: [
                .font: LMKTypography.font(for: textStyle, compatibleWith: traitCollection),
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
        removeButton.accessibilityLabel = strings.removeLinkAccessibilityLabel
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

    func update(_ row: LMKDetailCard.Row, style: LMKDetailCardView.Style, theme: LMKTheme) {
        guard case let .rating(model) = row else { return }
        stack.spacing = theme.spacing.medium
        titleLabel.lmk_apply(style.inlineKeyTextStyle ?? .subbodyMedium, color: style.keyColor ?? LMKColor.textSecondary)
        titleLabel.lmk_setText(model.title)
        ratingControl.style = style.rating
        ratingControl.maximum = max(1, model.maximum)
        ratingControl.value = model.value
        ratingControl.isInteractive = model.onChange != nil
        ratingControl.onChange = model.onChange
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
    private var maxHeight: CGFloat = 240
    private lazy var tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))

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

    func update(_ row: LMKDetailCard.Row, style: LMKDetailCardView.Style, theme: LMKTheme) {
        guard case let .image(model) = row else { return }
        maxHeight = model.maxHeight ?? style.imageMaxHeight ?? 240
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
            setImage(nil)
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

    func update(_: LMKDetailCard.Row, style _: LMKDetailCardView.Style, theme _: LMKTheme) {}
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

    func update(_ row: LMKDetailCard.Row, style _: LMKDetailCardView.Style, theme _: LMKTheme) {
        guard case let .custom(_, view) = row else { return }
        guard hostedView !== view else { return }
        hostedView?.removeFromSuperview()
        addSubview(view)
        view.snp.makeConstraints { $0.edges.equalToSuperview() }
        hostedView = view
    }
}
