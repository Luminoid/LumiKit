//
//  LMKPhotoButton.swift
//  LumiKit
//
//  A photo well: a placeholder symbol until an image is set, then the image
//  clipped to a circle or rounded square. Tapping it is the host's cue to pick.
//

import UIKit

/// Photo picker button (profile photos, product photos).
///
/// ```swift
/// let photoButton = LMKPhotoButton(size: 160)
/// photoButton.image = pet.photo
/// photoButton.onTap = { [weak self] in self?.pickPhoto() }
/// ```
public final class LMKPhotoButton: UIControl, LMKThemeApplying {
    // MARK: - Style

    public nonisolated enum Shape: Sendable, Hashable {
        case circle
        /// Rounded square; `nil` = `LMKCornerRadius.large`.
        case rounded(radius: CGFloat? = nil)
    }

    public nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// `nil` = `.circle`. Ignored when `surface.corners` is set.
        public var shape: Shape?
        /// Background (default `backgroundSecondary`), corners (from `shape`), border, shadow.
        public var surface: LMKSurfaceStyle
        /// `nil` = "camera.fill".
        public var placeholderSymbol: String?
        /// `nil` = `symbolHero`.
        public var placeholderPointSize: CGFloat?
        /// `nil` = `.light`.
        public var placeholderWeight: UIImage.SymbolWeight?
        /// `nil` = `textTertiary`.
        public var placeholderTint: UIColor?
        /// Scale on press; `nil` = yes.
        public var pressAnimation: Bool?
        /// Haptic on tap; `nil` = no.
        public var haptics: Bool?
        public var highlighted: LMKControlStateStyle?
        public var disabled: LMKControlStateStyle?

        public init(
            shape: Shape? = nil,
            surface: LMKSurfaceStyle = LMKSurfaceStyle(),
            placeholderSymbol: String? = nil,
            placeholderPointSize: CGFloat? = nil,
            placeholderWeight: UIImage.SymbolWeight? = nil,
            placeholderTint: UIColor? = nil,
            pressAnimation: Bool? = nil,
            haptics: Bool? = nil,
            highlighted: LMKControlStateStyle? = nil,
            disabled: LMKControlStateStyle? = nil
        ) {
            self.shape = shape
            self.surface = surface
            self.placeholderSymbol = placeholderSymbol
            self.placeholderPointSize = placeholderPointSize
            self.placeholderWeight = placeholderWeight
            self.placeholderTint = placeholderTint
            self.pressAnimation = pressAnimation
            self.haptics = haptics
            self.highlighted = highlighted
            self.disabled = disabled
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                shape: other.shape ?? shape,
                surface: surface.merging(other.surface),
                placeholderSymbol: other.placeholderSymbol ?? placeholderSymbol,
                placeholderPointSize: other.placeholderPointSize ?? placeholderPointSize,
                placeholderWeight: other.placeholderWeight ?? placeholderWeight,
                placeholderTint: other.placeholderTint ?? placeholderTint,
                pressAnimation: other.pressAnimation ?? pressAnimation,
                haptics: other.haptics ?? haptics,
                highlighted: LMKControlStateStyle.merge(highlighted, other.highlighted),
                disabled: LMKControlStateStyle.merge(disabled, other.disabled)
            )
        }
    }

    // MARK: - Strings

    public nonisolated struct Strings: Sendable, Equatable {
        /// VoiceOver label while no image is set.
        public var addAccessibilityLabel: String
        /// VoiceOver label once an image is set.
        public var changeAccessibilityLabel: String

        public init(
            addAccessibilityLabel: String = LMKLocalized("photoButton.add.accessibilityLabel"),
            changeAccessibilityLabel: String = LMKLocalized("photoButton.change.accessibilityLabel")
        ) {
            self.addAccessibilityLabel = addAccessibilityLabel
            self.changeAccessibilityLabel = changeAccessibilityLabel
        }
    }

    /// Process-wide defaults; set at app launch to override.
    public nonisolated(unsafe) static var strings = Strings()

    /// Per-instance strings (default `Self.strings`).
    public var strings: Strings = LMKPhotoButton.strings {
        didSet { updateAccessibility() }
    }

    // MARK: - Public API

    /// The side length in points.
    public var size: CGFloat {
        didSet {
            guard size != oldValue else { return }
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    /// The photo; `nil` shows the placeholder symbol.
    public var image: UIImage? {
        didSet { updateImage() }
    }

    /// Called on tap.
    public var onTap: (() -> Void)?

    /// Per-instance style; `nil` fields resolve from `theme.photoButton`, then the built-in look.
    public var style: Style {
        didSet {
            guard style != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKPhotoButton) -> Void)?

    public let imageView = UIImageView()

    private var resolved = Style()

    // MARK: - Initialization

    public init(size: CGFloat, style: Style = Style()) {
        self.size = size
        self.style = style
        super.init(frame: .zero)
        setupUI()
        lmk_startApplyingTheme()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        clipsToBounds = true
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = false
        addSubview(imageView)
        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .vertical)
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
        addTarget(self, action: #selector(handleTouchDown), for: .touchDown)
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        addInteraction(UIPointerInteraction(delegate: self))
        isAccessibilityElement = true
        accessibilityTraits = .button
        updateAccessibility()
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
        lmk_layoutSurfaceIfNeeded()
    }

    override public var intrinsicContentSize: CGSize {
        CGSize(width: size, height: size)
    }

    override public var isEnabled: Bool {
        didSet {
            guard isEnabled != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
            updateAccessibility()
        }
    }

    override public var isHighlighted: Bool {
        didSet {
            guard isHighlighted != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    // MARK: - Theme

    public func applyTheme(_ theme: LMKTheme) {
        resolved = theme.photoButton.merging(style)
        let corners: LMKCornerStyle = switch resolved.shape ?? .circle {
        case .circle: .circle
        case let .rounded(radius): .fixed(radius ?? theme.cornerRadius.large)
        }
        var surface = resolved.surface
        var stateAlpha: CGFloat = 1
        if isHighlighted {
            if let background = resolved.highlighted?.background { surface.background = background }
            if let border = resolved.highlighted?.border { surface.border = border }
            stateAlpha = min(stateAlpha, resolved.highlighted?.alpha ?? 1)
        }
        if !isEnabled {
            if let background = resolved.disabled?.background { surface.background = background }
            stateAlpha = min(stateAlpha, resolved.disabled?.alpha ?? theme.alpha.disabled)
        }
        lmk_apply(surface: surface, defaults: LMKSurfaceStyle(background: .solid(LMKColor.backgroundSecondary), corners: corners))
        alpha = stateAlpha
        updateImage()
        invalidateIntrinsicContentSize()
        didApplyStyle?(self)
    }

    private func updateImage() {
        if let image {
            imageView.image = image
            imageView.contentMode = .scaleAspectFill
            imageView.tintColor = nil
        } else {
            let configuration = UIImage.SymbolConfiguration(
                pointSize: resolved.placeholderPointSize ?? traitCollection.lmkTheme.layout.symbolHero,
                weight: resolved.placeholderWeight ?? .light
            )
            imageView.image = UIImage(systemName: resolved.placeholderSymbol ?? "camera.fill", withConfiguration: configuration)
            imageView.contentMode = .center
            imageView.tintColor = resolved.placeholderTint ?? LMKColor.textTertiary
        }
        updateAccessibility()
    }

    // MARK: - Actions

    @objc private func handleTap() {
        guard isEnabled else { return }
        if resolved.haptics ?? false { LMKHaptics.light() }
        onTap?()
        sendActions(for: .primaryActionTriggered)
    }

    @objc private func handleTouchDown() {
        guard resolved.pressAnimation ?? true else { return }
        LMKAnimation.animateButtonPressDown(self)
    }

    @objc private func handleTouchUp() {
        guard resolved.pressAnimation ?? true else { return }
        LMKAnimation.animateButtonPressUp(self)
    }

    // MARK: - Accessibility

    private func updateAccessibility() {
        accessibilityLabel = image == nil ? strings.addAccessibilityLabel : strings.changeAccessibilityLabel
        var traits: UIAccessibilityTraits = [.button, .image]
        if image == nil { traits.remove(.image) }
        if !isEnabled { traits.insert(.notEnabled) }
        accessibilityTraits = traits
    }
}

// MARK: - UIPointerInteractionDelegate

extension LMKPhotoButton: UIPointerInteractionDelegate {
    public func pointerInteraction(_: UIPointerInteraction, styleFor _: UIPointerRegion) -> UIPointerStyle? {
        LMKPointerStyle.lift(for: self)
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKPhotoButton`.
    var photoButton: LMKPhotoButton.Style {
        get { self[LMKPhotoButton.Style.self] }
        set { self[LMKPhotoButton.Style.self] = newValue }
    }
}
