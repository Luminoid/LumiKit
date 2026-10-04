//
//  LMKPhotoButton.swift
//  LumiKit
//
//  A photo well: a placeholder symbol until an image is set, then the image
//  clipped to a circle or rounded square. Tapping it is the host's cue to pick.
//

import LumiKitCore
import UIKit
import UniformTypeIdentifiers

/// Photo picker button (profile photos, product photos).
///
/// ```swift
/// let photoButton = LMKPhotoButton(size: 160)
/// photoButton.image = pet.photo
/// photoButton.onTap = { [weak self] in self?.pickPhoto() }
/// photoButton.onDropImage = { [weak self] data in self?.usePhoto(data) }   // drag a photo in (iPad, Mac)
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

    /// Accepts an image dragged onto the well (from Photos, Files, or another app) and hands
    /// over its original bytes, metadata included, on the main actor. While a drag hovers, the
    /// well takes `Style.highlighted`, or an accent outline when that is unset. Only the latest
    /// drop is delivered. `nil` (the default) installs no drop target. The well does not show the
    /// image itself: set `image` once the data is decoded.
    public var onDropImage: ((Data) -> Void)? {
        didSet { updateDropInteraction() }
    }

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
    private var dropInteraction: UIDropInteraction?
    /// The data load of the last drop, cancelled when another drop replaces it or drops turn off.
    private var dropLoad: Progress?
    /// Counts drops, so a load that finishes after a newer drop (or after drops turn off) is dropped.
    private var dropGeneration = 0
    /// Whether a drag carrying an image hovers over the well.
    var isDropTargeted = false {
        didSet {
            guard isDropTargeted != oldValue else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

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
        imageView.lmk_layoutCornersIfNeeded()
    }

    override public var intrinsicContentSize: CGSize {
        CGSize(width: size, height: size)
    }

    /// A small well still answers the minimum touch target; a disabled one absorbs a touch inside its bounds.
    override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard !isHidden else { return false }
        guard isEnabled else { return bounds.contains(point) }
        return lmk_hitTestBounds(minimumSide: traitCollection.lmkTheme.layout.minimumTouchTarget, insets: lmk_hitTestInsets).contains(point)
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
        if isHighlighted || isDropTargeted {
            if let background = resolved.highlighted?.background { surface.background = background }
            if let border = resolved.highlighted?.border { surface.border = border }
            stateAlpha = min(stateAlpha, resolved.highlighted?.alpha ?? 1)
        }
        if isDropTargeted, resolved.highlighted?.background == nil, resolved.highlighted?.border == nil {
            surface.border = .solid(LMKColor.primary, width: Self.dropTargetBorderWidth)
        }
        if !isEnabled {
            if let background = resolved.disabled?.background { surface.background = background }
            stateAlpha = min(stateAlpha, resolved.disabled?.alpha ?? theme.alpha.disabled)
        }
        let applied = lmk_apply(surface: surface, defaults: LMKSurfaceStyle(background: .solid(LMKColor.backgroundSecondary), corners: corners))
        // A visible shadow turns the well's own masking off, so the photo clips itself.
        imageView.lmk_applyCornerStyle(applied.corners ?? corners, masking: true)
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

    // MARK: - Drop

    private func updateDropInteraction() {
        if onDropImage != nil, dropInteraction == nil {
            let interaction = UIDropInteraction(delegate: self)
            addInteraction(interaction)
            dropInteraction = interaction
        } else if onDropImage == nil, let interaction = dropInteraction {
            removeInteraction(interaction)
            dropInteraction = nil
            dropGeneration += 1
            dropLoad?.cancel()
            dropLoad = nil
            isDropTargeted = false
        }
    }

    /// Loads the first image among `providers` and hands its bytes to `onDropImage`.
    func handleDrop(of providers: [NSItemProvider]) {
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) }) else { return }
        dropGeneration += 1
        let generation = dropGeneration
        dropLoad?.cancel()
        dropLoad = provider.loadDataRepresentation(for: UTType.image) { [weak self] data, error in
            Task { @MainActor [weak self] in
                guard let self, generation == dropGeneration else { return }
                dropLoad = nil
                guard let data else {
                    LMKLogger.warning("LMKPhotoButton: the dropped image could not be read", error: error, category: .lumiKit)
                    return
                }
                onDropImage?(data)
            }
        }
    }

    /// The accent outline a hovering drag shows when `Style.highlighted` is unset.
    private static let dropTargetBorderWidth: CGFloat = 2

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

// MARK: - UIDropInteractionDelegate

extension LMKPhotoButton: UIDropInteractionDelegate {
    public func dropInteraction(_: UIDropInteraction, canHandle session: any UIDropSession) -> Bool {
        isEnabled && onDropImage != nil && session.hasItemsConforming(toTypeIdentifiers: [UTType.image.identifier])
    }

    public func dropInteraction(_: UIDropInteraction, sessionDidUpdate _: any UIDropSession) -> UIDropProposal {
        UIDropProposal(operation: isEnabled ? .copy : .forbidden)
    }

    public func dropInteraction(_: UIDropInteraction, sessionDidEnter _: any UIDropSession) {
        isDropTargeted = true
    }

    public func dropInteraction(_: UIDropInteraction, sessionDidExit _: any UIDropSession) {
        isDropTargeted = false
    }

    public func dropInteraction(_: UIDropInteraction, sessionDidEnd _: any UIDropSession) {
        isDropTargeted = false
    }

    public func dropInteraction(_: UIDropInteraction, performDrop session: any UIDropSession) {
        isDropTargeted = false
        handleDrop(of: session.items.map(\.itemProvider))
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKPhotoButton`.
    var photoButton: LMKPhotoButton.Style {
        get { self[LMKPhotoButton.Style.self] }
        set { self[LMKPhotoButton.Style.self] = newValue }
    }
}
