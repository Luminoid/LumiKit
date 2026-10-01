//
//  LMKPhotoCropViewController.swift
//  LumiKit
//
//  Photo crop editor with a resizable crop frame, aspect ratio presets,
//  pinch-to-zoom, and a rule-of-thirds grid, styled from `theme.photoCrop`.
//

import LumiKitCore
import LumiKitUI
import SnapKit
import UIKit

/// Crop editor: a draggable crop frame with corner and edge handles, aspect ratio presets,
/// pinch-to-zoom on the image, and a rule-of-thirds grid. Gestures move frames directly (no
/// Auto Layout during a drag); the crop itself renders off the main actor.
///
/// ```swift
/// let crop = LMKPhotoCropViewController(image: picked, initialAspectRatio: .square)
/// crop.onCrop = { [weak self] image in self?.store(image); self?.dismiss(animated: true) }
/// crop.onCancel = { [weak self] in self?.dismiss(animated: true) }
/// present(crop, animated: true)
/// ```
///
/// Command-Return crops and Escape cancels on a hardware keyboard. Under VoiceOver the crop
/// frame is an adjustable element: swiping up or down resizes it, and custom actions move it.
public final class LMKPhotoCropViewController: UIViewController, LMKThemeApplying {
    /// Process-wide strings, read when a crop editor is created. Override at app launch to localize.
    public nonisolated(unsafe) static var strings = Strings()

    // MARK: - Status Bar

    override public var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    // MARK: - Public Properties

    /// The source image.
    public let image: UIImage
    /// The presets offered in the aspect ratio control.
    public let aspectRatios: [LMKCropAspectRatio]
    /// The preset in effect.
    public private(set) var currentAspectRatio: LMKCropAspectRatio
    /// Called with the cropped image when the user confirms; the host dismisses.
    public var onCrop: ((UIImage) -> Void)?
    /// Called when the user cancels; the host dismisses.
    public var onCancel: (() -> Void)?

    /// This editor's strings.
    public var strings: Strings = LMKPhotoCropViewController.strings {
        didSet {
            guard isViewLoaded else { return }
            applyStrings()
        }
    }

    /// Per-instance style, layered over `theme.photoCrop`.
    public var style: Style {
        didSet {
            guard style != oldValue, isViewLoaded else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKPhotoCropViewController) -> Void)?

    /// The style in effect after the theme and instance style are merged.
    public private(set) var resolvedStyle = Style()

    /// The crop frame in the editor's view coordinates.
    public var cropRect: CGRect { cropFrame }

    /// Whether a crop render is in flight (Done is ignored meanwhile).
    public private(set) var isCropping = false

    // MARK: - Views

    public let cancelButton = LMKButton(style: .iconOnly())
    public let doneButton = LMKButton(style: .iconOnly())
    public let imageView = UIImageView()
    public let overlayView = UIView()
    public let cropFrameView = UIView()
    public let aspectRatioControl: LMKSegmentedControl

    // MARK: - Internal State

    let overlayMaskLayer = CAShapeLayer()
    let gridLayer = CAShapeLayer()
    var cornerHandleViews: [ResizeHandle: UIView] = [:]
    var edgeHandleViews: [ResizeHandle: UIView] = [:]

    var cropFrame: CGRect = .zero
    var initialCropFrame: CGRect = .zero
    var initialTouchPoint: CGPoint = .zero
    var isResizing = false
    var activeResizeHandle: ResizeHandle?
    var needsInitialLayout = true

    var currentZoomScale: CGFloat = 1
    var initialZoomScale: CGFloat = 1
    /// Recalculated only when the view size changes.
    var cachedBaseScale: CGFloat = 0
    var lastViewSize: CGSize = .zero

    private var cropTask: Task<Void, Never>?
    private var cancelButtonSizeConstraint: Constraint?
    private var cancelButtonTopConstraint: Constraint?
    private var cancelButtonLeadingConstraint: Constraint?
    private var doneButtonSizeConstraint: Constraint?
    private var doneButtonTopConstraint: Constraint?
    private var doneButtonTrailingConstraint: Constraint?
    private var aspectControlInsetConstraint: Constraint?
    private var aspectControlBottomConstraint: Constraint?
    lazy var gestureDelegate = LMKPhotoCropGestureDelegate(controller: self)
    /// The crop frame as VoiceOver sees it (the frame view itself carries the handles).
    lazy var cropFrameAccessibilityElement = LMKPhotoCropFrameAccessibilityElement(controller: self)

    // MARK: - Init

    /// - Parameters:
    ///   - image: The source image.
    ///   - aspectRatios: The presets to offer; `initialAspectRatio` is added when missing.
    ///   - initialAspectRatio: The preset selected at first.
    ///   - style: Per-instance style, layered over `theme.photoCrop`.
    public init(
        image: UIImage,
        aspectRatios: [LMKCropAspectRatio] = LMKCropAspectRatio.standard,
        initialAspectRatio: LMKCropAspectRatio = .square,
        style: Style = Style()
    ) {
        self.image = image
        var presets = aspectRatios.isEmpty ? LMKCropAspectRatio.standard : aspectRatios
        if !presets.contains(initialAspectRatio) {
            presets.insert(initialAspectRatio, at: 0)
        }
        self.aspectRatios = presets
        currentAspectRatio = initialAspectRatio
        self.style = style
        aspectRatioControl = LMKSegmentedControl(items: presets.map(\.displayName))
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalPresentationCapturesStatusBarAppearance = true
        // Read by the navigation controller at push time, before the view loads.
        hidesBottomBarWhenPushed = true
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        cropTask?.cancel()
    }

    // MARK: - Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark
        setupUI()
        setupHandleViews()
        setupCachedLayers()
        setupAccessibility()
        applyStrings()
        lmk_startApplyingTheme()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if resolvedStyle.playsHaptics {
            LMKHaptics.prepare()
        }
        becomeFirstResponder()
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateLayout()
    }

    override public var canBecomeFirstResponder: Bool { true }

    override public var keyCommands: [UIKeyCommand]? {
        lmk_formKeyCommands(save: #selector(doneTapped), cancel: #selector(cancelTapped))
    }

    /// The VoiceOver escape gesture cancels, like the cancel button.
    override public func accessibilityPerformEscape() -> Bool {
        cancelTapped()
        return true
    }

    /// iOS 26 only: earlier systems have no per-controller lock, so the editor rotates there
    /// and re-fits the crop frame to the photo.
    @available(iOS 26.0, *)
    override public var prefersInterfaceOrientationLocked: Bool {
        resolvedStyle.locksOrientation ?? true
    }

    // MARK: - Setup

    private func setupUI() {
        // Spacing constraints start at zero and take their values from the theme in `applyTheme`.
        cancelButton.setSymbol("xmark")
        cancelButton.onTap = { [weak self] in self?.cancelTapped() }
        view.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { make in
            cancelButtonTopConstraint = make.top.equalTo(view.safeAreaLayoutGuide).offset(0).constraint
            cancelButtonLeadingConstraint = make.leading.equalTo(view.safeAreaLayoutGuide).offset(0).constraint
            // 999: the button's own minimum height is required, and `applyTheme` sets both to
            // the same side; until then the floor wins without a conflict.
            cancelButtonSizeConstraint = make.size.equalTo(0).priority(999).constraint
        }

        doneButton.setSymbol("checkmark")
        doneButton.onTap = { [weak self] in self?.doneTapped() }
        view.addSubview(doneButton)
        doneButton.snp.makeConstraints { make in
            doneButtonTopConstraint = make.top.equalTo(view.safeAreaLayoutGuide).offset(0).constraint
            doneButtonTrailingConstraint = make.trailing.equalTo(view.safeAreaLayoutGuide).offset(0).constraint
            doneButtonSizeConstraint = make.size.equalTo(0).priority(999).constraint
        }

        aspectRatioControl.selectedSegmentIndex = aspectRatios.firstIndex(of: currentAspectRatio) ?? 0
        aspectRatioControl.onValueChange = { [weak self] index in
            guard let self, index >= 0, index < aspectRatios.count else { return }
            setAspectRatio(aspectRatios[index], animated: true)
        }
        view.addSubview(aspectRatioControl)
        aspectRatioControl.snp.makeConstraints { make in
            aspectControlBottomConstraint = make.bottom.equalTo(view.safeAreaLayoutGuide).offset(0).constraint
            aspectControlInsetConstraint = make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(0).constraint
        }

        // Frames are assigned directly: no Auto Layout during gestures.
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        view.addSubview(imageView)

        overlayView.isUserInteractionEnabled = false
        view.addSubview(overlayView)
        overlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        cropFrameView.backgroundColor = .clear
        cropFrameView.isUserInteractionEnabled = true
        view.addSubview(cropFrameView)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = gestureDelegate
        cropFrameView.addGestureRecognizer(panGesture)

        let resizePanGesture = UIPanGestureRecognizer(target: self, action: #selector(handleResizePan(_:)))
        resizePanGesture.delegate = gestureDelegate
        view.addGestureRecognizer(resizePanGesture)

        // On the editor's view, not the image view: touches inside the crop frame hit-test to
        // the frame view above the image, and a pinch must work with the fingers there too.
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinchGesture.delegate = gestureDelegate
        view.addGestureRecognizer(pinchGesture)

        bringChromeToFront()
    }

    /// VoiceOver walks cancel, the crop frame, the ratio control, then done; the image and
    /// the dimming stay out of the way.
    private func setupAccessibility() {
        view.accessibilityElements = [cancelButton, cropFrameAccessibilityElement, aspectRatioControl, doneButton]
    }

    /// Handle views are created once and only repositioned afterwards.
    private func setupHandleViews() {
        for handle in ResizeHandle.corners {
            let handleView = makeHandleView()
            cropFrameView.addSubview(handleView)
            cornerHandleViews[handle] = handleView
        }
        for handle in ResizeHandle.edges {
            let handleView = makeHandleView()
            cropFrameView.addSubview(handleView)
            edgeHandleViews[handle] = handleView
        }
    }

    private func makeHandleView() -> UIView {
        let handleView = UIView()
        handleView.isUserInteractionEnabled = false
        return handleView
    }

    private func setupCachedLayers() {
        overlayView.layer.mask = overlayMaskLayer
        gridLayer.fillColor = nil
        cropFrameView.layer.addSublayer(gridLayer)
    }

    func bringChromeToFront() {
        view.bringSubviewToFront(aspectRatioControl)
        view.bringSubviewToFront(cropFrameView)
        view.bringSubviewToFront(cancelButton)
        view.bringSubviewToFront(doneButton)
    }

    private func applyStrings() {
        title = strings.title
        cancelButton.accessibilityLabel = strings.cancel
        doneButton.accessibilityLabel = strings.done
        aspectRatioControl.accessibilityLabel = strings.aspectRatioAccessibilityLabel
        aspectRatioControl.setItems(aspectRatios.map { $0 == .free ? strings.free : $0.displayName })
        aspectRatioControl.selectedSegmentIndex = aspectRatios.firstIndex(of: currentAspectRatio) ?? 0
        cropFrameAccessibilityElement.apply(strings: strings)
    }

    // MARK: - Theme

    public func applyTheme(_ theme: LMKTheme) {
        resolvedStyle = theme.photoCrop.merging(style)
        let resolved = resolvedStyle
        let chrome = resolved.chrome

        view.backgroundColor = resolved.stageColor
        overlayView.backgroundColor = (resolved.dimmingColor ?? resolved.stageColor).withAlphaComponent(resolved.dimmingAlpha ?? theme.alpha.large)

        let buttonStyle = resolved.overlayButtonStyle(theme: theme)
        cancelButton.style = buttonStyle
        doneButton.style = buttonStyle
        let buttonSide = resolved.buttonSize(theme: theme)
        cancelButtonSizeConstraint?.update(offset: buttonSide)
        doneButtonSizeConstraint?.update(offset: buttonSide)
        let margin = theme.spacing.large
        cancelButtonTopConstraint?.update(offset: margin)
        cancelButtonLeadingConstraint?.update(offset: margin)
        doneButtonTopConstraint?.update(offset: margin)
        doneButtonTrailingConstraint?.update(offset: -margin)

        aspectRatioControl.style = resolved.aspectControlStyle(theme: theme)
        let padding = resolved.padding(theme: theme)
        aspectControlInsetConstraint?.update(inset: padding)
        aspectControlBottomConstraint?.update(offset: -padding)

        let border = resolved.cropFrameBorder ?? .solid(chrome, width: LMKPhotoCropMetrics.cropFrameBorderWidth)
        cropFrameView.lmk_applyBorder(color: border.color ?? chrome, width: border.width ?? LMKPhotoCropMetrics.cropFrameBorderWidth)

        let handleSide = resolved.handleSide
        let handleColor = resolved.handleColor ?? chrome
        for handleView in cornerHandleViews.values.map(\.self) + edgeHandleViews.values.map(\.self) {
            handleView.backgroundColor = handleColor
            handleView.frame.size = CGSize(width: handleSide, height: handleSide)
            handleView.lmk_applyCornerStyle(.circle)
            handleView.lmk_layoutCornersIfNeeded()
        }

        gridLayer.isHidden = !resolved.drawsGrid
        gridLayer.strokeColor = (resolved.gridColor ?? chrome).withAlphaComponent(resolved.gridAlpha ?? theme.alpha.large).resolvedColor(with: traitCollection).cgColor
        gridLayer.lineWidth = resolved.gridLineWidth ?? LMKLayout.hairline(for: view)

        lastViewSize = .zero
        if isViewLoaded, view.bounds.width > 0 {
            updateLayout()
        }
        if #available(iOS 26, *) {
            setNeedsUpdateOfPrefersInterfaceOrientationLocked()
        }
        didApplyStyle?(self)
    }

    // MARK: - Aspect Ratio

    /// Selects a preset, reshaping the crop frame around its center.
    public func setAspectRatio(_ aspectRatio: LMKCropAspectRatio, animated: Bool) {
        guard let index = aspectRatios.firstIndex(of: aspectRatio) else { return }
        let changed = aspectRatio != currentAspectRatio
        currentAspectRatio = aspectRatio
        if aspectRatioControl.selectedSegmentIndex != index {
            aspectRatioControl.setSelectedSegmentIndex(index, animated: animated)
        }
        guard changed, isViewLoaded, view.bounds.width > 0 else { return }
        if resolvedStyle.playsHaptics {
            LMKHaptics.selection()
        }
        applyAspectRatioToCropFrame()
        updateLayout()
    }

    // MARK: - Actions

    /// Cancels, dropping a render still under way so `onCrop` cannot follow `onCancel`.
    @objc func cancelTapped() {
        cropTask?.cancel()
        cropTask = nil
        isCropping = false
        onCancel?()
    }

    @objc func doneTapped() {
        guard !isCropping else { return }
        guard cropFrame.width > 0, cropFrame.height > 0, let pixelRect = currentCropRect else {
            LMKLogger.warning("Crop frame is empty; delivering the original image", category: .ui)
            onCrop?(image)
            return
        }
        if resolvedStyle.playsHaptics {
            LMKHaptics.success()
        }
        isCropping = true
        let source = image
        cropTask?.cancel()
        cropTask = Task { [weak self] in
            let cropped = await Self.render(image: source, cropRect: pixelRect)
            guard let self, !Task.isCancelled else { return }
            isCropping = false
            if let cropped {
                onCrop?(cropped)
            } else {
                LMKLogger.warning("Crop failed; delivering the original image", category: .ui)
                onCrop?(source)
            }
        }
    }

    /// The crop frame in the image's point space, its height derived from its width under a
    /// locked ratio.
    private var currentCropRect: CGRect? {
        Self.cropRect(cropFrame: cropFrame, imageFrame: imageView.frame, imageSize: image.size, ratio: currentAspectRatio.ratio)
    }

    /// The image cropped to the current frame, rendered off the main actor. `nil` when the
    /// crop frame is empty or the render fails.
    public func croppedImage() async -> UIImage? {
        guard let pixelRect = currentCropRect else { return nil }
        return await Self.render(image: image, cropRect: pixelRect)
    }
}
