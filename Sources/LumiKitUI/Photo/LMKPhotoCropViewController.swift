//
//  LMKPhotoCropViewController.swift
//  LumiKit
//
//  Photo cropping view controller with resizable crop frame,
//  aspect ratio presets, pinch-to-zoom, and rule-of-thirds grid.
//

import LumiKitCore
import SnapKit
import UIKit

// MARK: - Delegate

/// Delegate for receiving crop results.
public protocol LMKPhotoCropDelegate: AnyObject {
    /// Called when the user confirms the crop.
    func photoCropViewController(_ controller: LMKPhotoCropViewController, didCropImage image: UIImage)
    /// Called when the user cancels cropping.
    func photoCropViewControllerDidCancel(_ controller: LMKPhotoCropViewController)
}

// MARK: - Configurable Strings

/// Localisable strings for `LMKPhotoCropViewController`.
public nonisolated struct LMKPhotoCropStrings: Sendable {
    public var title: String
    public var free: String

    public init(
        title: String = "Crop",
        free: String = "Free",
    ) {
        self.title = title
        self.free = free
    }
}

/// Override to provide localised strings. Set once at app launch.
public nonisolated(unsafe) var lmkPhotoCropStrings = LMKPhotoCropStrings()

// MARK: - Aspect Ratio

/// Predefined crop aspect ratios.
public nonisolated enum LMKCropAspectRatio: CaseIterable, Sendable {
    case square // 1:1
    case fourThree // 4:3
    case threeTwo // 3:2
    case twoThree // 2:3
    case threeFour // 3:4
    case free // No fixed ratio

    /// Numeric ratio (width / height), or `nil` for free.
    public var ratio: CGFloat? {
        switch self {
        case .square: 1.0
        case .fourThree: 4.0 / 3.0
        case .threeTwo: 3.0 / 2.0
        case .twoThree: 2.0 / 3.0
        case .threeFour: 3.0 / 4.0
        case .free: nil
        }
    }

    /// Default display name (e.g. "1:1", "4:3", "Free").
    public var displayName: String {
        switch self {
        case .square: "1:1"
        case .fourThree: "4:3"
        case .threeTwo: "3:2"
        case .twoThree: "2:3"
        case .threeFour: "3:4"
        case .free: lmkPhotoCropStrings.free
        }
    }
}

// MARK: - View Controller

/// Photo cropping view controller with resizable crop frame.
///
/// Features:
/// - Draggable crop frame with corner and edge handles
/// - Aspect ratio presets (1:1, 4:3, 3:2, 2:3, 3:4, free)
/// - Pinch-to-zoom on the image
/// - Rule-of-thirds grid overlay
/// - Optimised gesture handling (no Auto Layout during drag)
public final class LMKPhotoCropViewController: UIViewController {
    // MARK: - Status Bar

    override public var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    // MARK: - Constants

    private static let handleSize: CGFloat = 22
    private static let minCropSize: CGFloat = 100
    private static let maxZoomScale: CGFloat = 3.0
    private static let minZoomScale: CGFloat = 1.0
    private static let borderWidth: CGFloat = 2.0
    private static var aspectControlHeight: CGFloat { segmentedControlHeight + LMKSpacing.xl * 2 }
    private static var handleHitSize: CGFloat { handleSize + LMKSpacing.medium }
    private static let segmentedControlHeight: CGFloat = 32
    private static let gridLineWidth: CGFloat = 0.5
    private static let gridLineAlpha: CGFloat = 0.6
    private static let gridLineCount: Int = 2 // Rule of thirds

    // MARK: - Public Properties

    /// Delegate for receiving crop/cancel callbacks.
    public weak var delegate: (any LMKPhotoCropDelegate)?

    /// The source image to crop.
    public let image: UIImage

    // MARK: - Private Properties

    private let cancelButton = UIButton(type: .system)
    private let doneButton = UIButton(type: .system)
    private let imageView = UIImageView()
    private let overlayView = UIView()
    private let cropFrameView = UIView()
    private let aspectRatioControl = UISegmentedControl()

    /// Cached overlay mask layer — reused across updates instead of recreating.
    private let overlayMaskLayer = CAShapeLayer()

    /// Cached grid layer for rule-of-thirds lines.
    private let gridLayer = CAShapeLayer()

    /// Pre-created corner handle views — repositioned, never removed/re-added.
    private var cornerHandleViews: [ResizeHandle: UIView] = [:]

    /// Pre-created edge handle views — shown/hidden based on aspect ratio.
    private var edgeHandleViews: [ResizeHandle: UIView] = [:]

    private var currentAspectRatio: LMKCropAspectRatio = .square
    private var cropFrame: CGRect = .zero
    private var initialCropFrame: CGRect = .zero
    private var initialTouchPoint: CGPoint = .zero
    private var isResizing = false
    private var resizeHandle: ResizeHandle?
    private var isMoving = false
    private var needsInitialLayout = true

    // Zoom state
    private var currentZoomScale: CGFloat = 1.0
    private var initialZoomScale: CGFloat = 1.0

    /// Cached base scale factor — only recalculated when view size changes.
    private var cachedBaseScale: CGFloat = 0
    private var lastViewSize: CGSize = .zero

    private var boundaryConstraints: (minX: CGFloat, minY: CGFloat, maxX: CGFloat, maxY: CGFloat) {
        let padding = LMKSpacing.xl
        return (
            padding,
            padding,
            view.bounds.width - padding,
            view.bounds.height - Self.aspectControlHeight - padding,
        )
    }

    private static let aspectRatios: [LMKCropAspectRatio] = LMKCropAspectRatio.allCases

    enum ResizeHandle: Int, CaseIterable {
        case topLeft = 0, topRight, bottomLeft, bottomRight
        case top, bottom, left, right

        var isCorner: Bool {
            switch self {
            case .topLeft, .topRight, .bottomLeft, .bottomRight: true
            default: false
            }
        }
    }

    // MARK: - Init

    /// Create a photo crop view controller.
    /// - Parameters:
    ///   - image: The source image to crop.
    ///   - delegate: Delegate for receiving crop/cancel results.
    public init(image: UIImage, delegate: (any LMKPhotoCropDelegate)? = nil) {
        self.image = image
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
        modalPresentationCapturesStatusBarAppearance = true
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark
        hidesBottomBarWhenPushed = true
        setupUI()
        setupHandleViews()
        setupCachedLayers()
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateLayout()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = LMKColor.photoBrowserBackground

        // Cancel button
        cancelButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        cancelButton.tintColor = LMKColor.white
        cancelButton.backgroundColor = LMKColor.photoBrowserBackground.withAlphaComponent(LMKAlpha.overlay)
        cancelButton.layer.cornerRadius = LMKCornerRadius.xl
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        view.addSubview(cancelButton)

        #if targetEnvironment(macCatalyst)
            let buttonSize: CGFloat = 48
        #else
            let buttonSize: CGFloat = LMKLayout.minimumTouchTarget
        #endif

        cancelButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(LMKSpacing.large)
            make.leading.equalToSuperview().offset(LMKSpacing.large)
            make.width.height.equalTo(buttonSize)
        }

        // Done button
        doneButton.setImage(UIImage(systemName: "checkmark"), for: .normal)
        doneButton.tintColor = LMKColor.white
        doneButton.backgroundColor = LMKColor.photoBrowserBackground.withAlphaComponent(LMKAlpha.overlay)
        doneButton.layer.cornerRadius = LMKCornerRadius.xl
        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        view.addSubview(doneButton)

        doneButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(LMKSpacing.large)
            make.trailing.equalToSuperview().offset(-LMKSpacing.large)
            make.width.height.equalTo(buttonSize)
        }

        // Aspect ratio control
        setupAspectRatioControl()

        // Image view — uses direct frame assignment (no Auto Layout overhead during gestures)
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        view.addSubview(imageView)

        // Overlay view for darkening outside crop area
        overlayView.backgroundColor = LMKColor.photoBrowserBackground.withAlphaComponent(LMKAlpha.overlay)
        overlayView.isUserInteractionEnabled = false
        view.addSubview(overlayView)
        overlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Crop frame view
        cropFrameView.layer.borderColor = LMKColor.white.cgColor
        cropFrameView.layer.borderWidth = Self.borderWidth
        cropFrameView.backgroundColor = .clear
        cropFrameView.isUserInteractionEnabled = true
        view.addSubview(cropFrameView)

        // Gesture recognizers
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        cropFrameView.addGestureRecognizer(panGesture)

        let resizePanGesture = UIPanGestureRecognizer(target: self, action: #selector(handleResizePan(_:)))
        resizePanGesture.delegate = self
        view.addGestureRecognizer(resizePanGesture)

        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinchGesture.delegate = self
        imageView.addGestureRecognizer(pinchGesture)

        // Ensure proper z-ordering
        view.bringSubviewToFront(aspectRatioControl)
        view.bringSubviewToFront(cropFrameView)
        view.bringSubviewToFront(cancelButton)
        view.bringSubviewToFront(doneButton)
    }

    private func setupAspectRatioControl() {
        aspectRatioControl.removeAllSegments()
        for (index, ratio) in Self.aspectRatios.enumerated() {
            aspectRatioControl.insertSegment(withTitle: ratio.displayName, at: index, animated: false)
        }
        aspectRatioControl.selectedSegmentIndex = 0
        aspectRatioControl.addTarget(self, action: #selector(aspectRatioChanged), for: .valueChanged)
        aspectRatioControl.backgroundColor = LMKColor.photoBrowserBackground.withAlphaComponent(LMKAlpha.overlayStrong)
        aspectRatioControl.selectedSegmentTintColor = LMKColor.white
        aspectRatioControl.setTitleTextAttributes([.foregroundColor: LMKColor.white], for: .normal)
        aspectRatioControl.setTitleTextAttributes([.foregroundColor: LMKColor.photoBrowserBackground], for: .selected)
        aspectRatioControl.isUserInteractionEnabled = true
        view.addSubview(aspectRatioControl)
        aspectRatioControl.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-LMKSpacing.xl)
            make.leading.trailing.equalToSuperview().inset(LMKSpacing.xl)
            make.height.equalTo(Self.segmentedControlHeight)
        }
    }

    /// Pre-create all handle views once; only reposition them in `updateHandlePositions()`.
    private func setupHandleViews() {
        let corners: [ResizeHandle] = [.topLeft, .topRight, .bottomLeft, .bottomRight]
        for handle in corners {
            let handleView = makeHandleView()
            cropFrameView.addSubview(handleView)
            cornerHandleViews[handle] = handleView
        }

        let edges: [ResizeHandle] = [.top, .bottom, .left, .right]
        for handle in edges {
            let handleView = makeHandleView()
            cropFrameView.addSubview(handleView)
            edgeHandleViews[handle] = handleView
        }
    }

    private func makeHandleView() -> UIView {
        let v = UIView()
        v.backgroundColor = LMKColor.white
        v.layer.cornerRadius = Self.handleSize / 2
        v.frame.size = CGSize(width: Self.handleSize, height: Self.handleSize)
        return v
    }

    /// Set up cached CAShapeLayers for overlay mask and grid.
    private func setupCachedLayers() {
        overlayView.layer.mask = overlayMaskLayer

        gridLayer.strokeColor = UIColor.white.withAlphaComponent(Self.gridLineAlpha).cgColor
        gridLayer.fillColor = nil
        gridLayer.lineWidth = Self.gridLineWidth
        cropFrameView.layer.addSublayer(gridLayer)
    }

    // MARK: - Layout

    private func updateLayout() {
        guard view.bounds.width > 0, view.bounds.height > 0 else { return }

        updateImageViewFrame()

        if needsInitialLayout {
            needsInitialLayout = false
            createInitialCropFrame()
        } else {
            updateCropFrame()
        }

        updateOverlayMask()
        updateHandlePositions()
        updateGridLines()

        view.bringSubviewToFront(aspectRatioControl)
        view.bringSubviewToFront(cropFrameView)
        view.bringSubviewToFront(cancelButton)
        view.bringSubviewToFront(doneButton)
    }

    private func updateImageViewFrame() {
        guard image.size.width > 0, image.size.height > 0 else { return }

        let viewSize = view.bounds.size

        // Only recalculate base scale when the view size actually changes
        if viewSize != lastViewSize {
            lastViewSize = viewSize
            let padding = LMKSpacing.xl
            let availableSize = CGSize(
                width: viewSize.width - padding * 2,
                height: viewSize.height - padding * 2,
            )
            cachedBaseScale = min(
                availableSize.width / image.size.width,
                availableSize.height / image.size.height,
            )
        }

        let scaledWidth = image.size.width * cachedBaseScale * currentZoomScale
        let scaledHeight = image.size.height * cachedBaseScale * currentZoomScale

        // Direct frame assignment — avoids SnapKit constraint solver overhead during gestures
        imageView.frame = CGRect(
            x: (viewSize.width - scaledWidth) / 2,
            y: (viewSize.height - scaledHeight) / 2,
            width: scaledWidth,
            height: scaledHeight,
        )
    }

    private func createInitialCropFrame() {
        let constraints = boundaryConstraints
        let availableWidth = constraints.maxX - constraints.minX
        let availableHeight = constraints.maxY - constraints.minY

        var cropWidth: CGFloat
        var cropHeight: CGFloat

        if let ratio = currentAspectRatio.ratio {
            if ratio >= 1.0 {
                cropWidth = min(availableWidth, availableHeight * ratio)
                cropHeight = cropWidth / ratio
            } else {
                cropHeight = min(availableHeight, availableWidth / ratio)
                cropWidth = cropHeight * ratio
            }
        } else {
            cropWidth = availableWidth
            cropHeight = availableHeight
        }

        cropFrame = CGRect(
            x: (view.bounds.width - cropWidth) / 2,
            y: (view.bounds.height - cropHeight) / 2,
            width: cropWidth,
            height: cropHeight,
        )

        updateCropFrame()
    }

    private func updateCropFrame(updateHandles: Bool = true) {
        let constraints = boundaryConstraints

        cropFrame.origin.x = max(constraints.minX, min(cropFrame.origin.x, constraints.maxX - cropFrame.width))
        cropFrame.origin.y = max(constraints.minY, min(cropFrame.origin.y, constraints.maxY - cropFrame.height))
        cropFrame.size.width = min(cropFrame.width, constraints.maxX - cropFrame.origin.x)
        cropFrame.size.height = min(cropFrame.height, constraints.maxY - cropFrame.origin.y)

        // Ensure minimum size
        cropFrame.size.width = max(cropFrame.width, Self.minCropSize)
        cropFrame.size.height = max(cropFrame.height, Self.minCropSize)

        // Direct frame update for best performance during gestures
        cropFrameView.frame = cropFrame

        // Only update handles and grid if requested (skip during active gestures)
        if updateHandles {
            updateHandlePositions()
            updateGridLines()
        }
    }

    // MARK: - Overlay & Grid

    private func updateOverlayMask() {
        let path = UIBezierPath(rect: overlayView.bounds)
        path.append(UIBezierPath(rect: cropFrame).reversing())
        overlayMaskLayer.path = path.cgPath
    }

    /// Reposition pre-created handle views — no add/remove subview overhead.
    private func updateHandlePositions() {
        let w = cropFrame.width
        let h = cropFrame.height
        let half = Self.handleSize / 2

        // Corner handles — always visible
        cornerHandleViews[.topLeft]?.frame.origin = CGPoint(x: -half, y: -half)
        cornerHandleViews[.topRight]?.frame.origin = CGPoint(x: w - half, y: -half)
        cornerHandleViews[.bottomLeft]?.frame.origin = CGPoint(x: -half, y: h - half)
        cornerHandleViews[.bottomRight]?.frame.origin = CGPoint(x: w - half, y: h - half)

        // Edge handles — only visible for free aspect ratio
        let showEdges = currentAspectRatio == .free
        edgeHandleViews[.top]?.frame.origin = CGPoint(x: w / 2 - half, y: -half)
        edgeHandleViews[.bottom]?.frame.origin = CGPoint(x: w / 2 - half, y: h - half)
        edgeHandleViews[.left]?.frame.origin = CGPoint(x: -half, y: h / 2 - half)
        edgeHandleViews[.right]?.frame.origin = CGPoint(x: w - half, y: h / 2 - half)

        for (_, handleView) in edgeHandleViews {
            handleView.isHidden = !showEdges
        }
    }

    /// Draw rule-of-thirds grid lines inside crop frame.
    private func updateGridLines() {
        let w = cropFrame.width
        let h = cropFrame.height
        guard w > 0, h > 0 else {
            gridLayer.path = nil
            return
        }

        let path = UIBezierPath()
        let divisions = CGFloat(Self.gridLineCount + 1)

        // Vertical lines
        for i in 1 ... Self.gridLineCount {
            let x = w * CGFloat(i) / divisions
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: h))
        }

        // Horizontal lines
        for i in 1 ... Self.gridLineCount {
            let y = h * CGFloat(i) / divisions
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: w, y: y))
        }

        gridLayer.frame = cropFrameView.bounds
        gridLayer.path = path.cgPath
    }

    // MARK: - Aspect Ratio

    @objc private func aspectRatioChanged() {
        currentAspectRatio = Self.aspectRatios[aspectRatioControl.selectedSegmentIndex]

        if let ratio = currentAspectRatio.ratio {
            let center = CGPoint(x: cropFrame.midX, y: cropFrame.midY)
            var newWidth = cropFrame.width
            var newHeight = cropFrame.height

            let currentRatio = cropFrame.width / cropFrame.height
            if currentRatio > ratio {
                newHeight = newWidth / ratio
            } else {
                newWidth = newHeight * ratio
            }

            let constraints = boundaryConstraints
            let maxWidth = constraints.maxX - constraints.minX
            let maxHeight = constraints.maxY - constraints.minY

            if newWidth > maxWidth {
                newWidth = maxWidth
                newHeight = newWidth / ratio
            }
            if newHeight > maxHeight {
                newHeight = maxHeight
                newWidth = newHeight * ratio
            }

            cropFrame = CGRect(
                x: center.x - newWidth / 2,
                y: center.y - newHeight / 2,
                width: newWidth,
                height: newHeight,
            )
        }

        updateLayout()
    }

    // MARK: - Gesture Handlers

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)

        switch gesture.state {
        case .began:
            initialCropFrame = cropFrame
            isMoving = true
        case .changed:
            // Disable implicit Core Animation animations for snappy gesture tracking
            CATransaction.begin()
            CATransaction.setDisableActions(true)

            var newFrame = initialCropFrame
            newFrame.origin.x += translation.x
            newFrame.origin.y += translation.y
            cropFrame = newFrame
            updateCropFrame(updateHandles: false)
            updateOverlayMask()

            CATransaction.commit()
        case .ended, .cancelled:
            isMoving = false
            updateCropFrame(updateHandles: true)
            updateOverlayMask()
        default:
            break
        }
    }

    @objc private func handleResizePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: view)

        switch gesture.state {
        case .began:
            resizeHandle = getResizeHandle(at: location)
            if resizeHandle != nil {
                initialCropFrame = cropFrame
                initialTouchPoint = location
                isResizing = true
            }
        case .changed:
            guard let handle = resizeHandle, isResizing else { return }

            CATransaction.begin()
            CATransaction.setDisableActions(true)

            let deltaX = location.x - initialTouchPoint.x
            let deltaY = location.y - initialTouchPoint.y
            var newFrame = initialCropFrame

            if let ratio = currentAspectRatio.ratio {
                resizeWithFixedRatio(&newFrame, handle: handle, deltaX: deltaX, deltaY: deltaY, ratio: ratio)
            } else {
                resizeFreely(&newFrame, handle: handle, deltaX: deltaX, deltaY: deltaY)
                newFrame.size.width = max(newFrame.width, Self.minCropSize)
                newFrame.size.height = max(newFrame.height, Self.minCropSize)
            }

            cropFrame = newFrame
            updateCropFrame(updateHandles: false)
            updateOverlayMask()

            CATransaction.commit()
        case .ended, .cancelled:
            isResizing = false
            resizeHandle = nil
            updateCropFrame(updateHandles: true)
            updateOverlayMask()
        default:
            break
        }
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            initialZoomScale = currentZoomScale
        case .changed:
            CATransaction.begin()
            CATransaction.setDisableActions(true)

            currentZoomScale = max(Self.minZoomScale, min(Self.maxZoomScale, initialZoomScale * gesture.scale))
            updateImageViewFrame()
            updateOverlayMask()

            CATransaction.commit()
        default:
            break
        }
    }

    // MARK: - Resize with Fixed Ratio

    private func resizeWithFixedRatio(_ frame: inout CGRect, handle: ResizeHandle, deltaX: CGFloat, deltaY: CGFloat, ratio: CGFloat) {
        guard let anchor = anchorPointForFixedRatio(handle: handle, frame: frame),
              let corner = newCornerPointForFixedRatio(handle: handle, frame: frame, deltaX: deltaX, deltaY: deltaY) else {
            return
        }
        let constraints = boundaryConstraints
        var newWidth = abs(corner.x - anchor.x)
        var newHeight = abs(corner.y - anchor.y)
        let widthBasedHeight = newWidth / ratio
        let heightBasedWidth = newHeight * ratio
        if widthBasedHeight <= newHeight {
            newHeight = widthBasedHeight
        } else {
            newWidth = heightBasedWidth
        }
        var (newOriginX, newOriginY) = originFromAnchorForFixedRatio(handle: handle, anchorX: anchor.x, anchorY: anchor.y, width: newWidth, height: newHeight)
        (newOriginX, newOriginY, newWidth, newHeight) = applyBoundaryConstraintsForFixedRatio(
            handle: handle, anchorX: anchor.x, anchorY: anchor.y, ratio: ratio,
            originX: newOriginX, originY: newOriginY, width: newWidth, height: newHeight, constraints: constraints,
        )
        newOriginX = max(constraints.minX, min(newOriginX, constraints.maxX - newWidth))
        newOriginY = max(constraints.minY, min(newOriginY, constraints.maxY - newHeight))
        frame.origin.x = newOriginX
        frame.origin.y = newOriginY
        frame.size.width = newWidth
        frame.size.height = newHeight
    }

    private func anchorPointForFixedRatio(handle: ResizeHandle, frame: CGRect) -> (x: CGFloat, y: CGFloat)? {
        switch handle {
        case .topLeft: (frame.maxX, frame.maxY)
        case .topRight: (frame.minX, frame.maxY)
        case .bottomLeft: (frame.maxX, frame.minY)
        case .bottomRight: (frame.minX, frame.minY)
        default: nil
        }
    }

    private func newCornerPointForFixedRatio(handle: ResizeHandle, frame: CGRect, deltaX: CGFloat, deltaY: CGFloat) -> (x: CGFloat, y: CGFloat)? {
        switch handle {
        case .topLeft: (frame.minX + deltaX, frame.minY + deltaY)
        case .topRight: (frame.maxX + deltaX, frame.minY + deltaY)
        case .bottomLeft: (frame.minX + deltaX, frame.maxY + deltaY)
        case .bottomRight: (frame.maxX + deltaX, frame.maxY + deltaY)
        default: nil
        }
    }

    private func originFromAnchorForFixedRatio(handle: ResizeHandle, anchorX: CGFloat, anchorY: CGFloat, width: CGFloat, height: CGFloat) -> (x: CGFloat, y: CGFloat) {
        switch handle {
        case .topLeft: (anchorX - width, anchorY - height)
        case .topRight: (anchorX, anchorY - height)
        case .bottomLeft: (anchorX - width, anchorY)
        case .bottomRight: (anchorX, anchorY)
        default: (0, 0)
        }
    }

    private func applyBoundaryConstraintsForFixedRatio(
        handle: ResizeHandle, anchorX: CGFloat, anchorY: CGFloat, ratio: CGFloat,
        originX: CGFloat, originY: CGFloat, width: CGFloat, height: CGFloat,
        constraints: (minX: CGFloat, minY: CGFloat, maxX: CGFloat, maxY: CGFloat),
    ) -> (originX: CGFloat, originY: CGFloat, width: CGFloat, height: CGFloat) {
        var newOriginX = originX
        var newOriginY = originY
        var newWidth = width
        var newHeight = height

        if newOriginX < constraints.minX {
            newOriginX = constraints.minX
            newWidth = anchorX - newOriginX
            newHeight = newWidth / ratio
            (newOriginX, newOriginY) = originFromAnchorForFixedRatio(handle: handle, anchorX: anchorX, anchorY: anchorY, width: newWidth, height: newHeight)
        }
        if newOriginX + newWidth > constraints.maxX {
            newWidth = constraints.maxX - newOriginX
            newHeight = newWidth / ratio
            (newOriginX, newOriginY) = originFromAnchorForFixedRatio(handle: handle, anchorX: anchorX, anchorY: anchorY, width: newWidth, height: newHeight)
        }
        if newOriginY < constraints.minY {
            newOriginY = constraints.minY
            newHeight = anchorY - newOriginY
            newWidth = newHeight * ratio
            (newOriginX, newOriginY) = originFromAnchorForFixedRatio(handle: handle, anchorX: anchorX, anchorY: anchorY, width: newWidth, height: newHeight)
        }
        if newOriginY + newHeight > constraints.maxY {
            newHeight = constraints.maxY - newOriginY
            newWidth = newHeight * ratio
            (newOriginX, newOriginY) = originFromAnchorForFixedRatio(handle: handle, anchorX: anchorX, anchorY: anchorY, width: newWidth, height: newHeight)
        }
        if newWidth < Self.minCropSize {
            newWidth = Self.minCropSize
            newHeight = Self.minCropSize / ratio
            (newOriginX, newOriginY) = originFromAnchorForFixedRatio(handle: handle, anchorX: anchorX, anchorY: anchorY, width: newWidth, height: newHeight)
        }
        if newHeight < Self.minCropSize {
            newHeight = Self.minCropSize
            newWidth = Self.minCropSize * ratio
            (newOriginX, newOriginY) = originFromAnchorForFixedRatio(handle: handle, anchorX: anchorX, anchorY: anchorY, width: newWidth, height: newHeight)
        }
        return (newOriginX, newOriginY, newWidth, newHeight)
    }

    // MARK: - Resize Freely

    private func resizeFreely(_ frame: inout CGRect, handle: ResizeHandle, deltaX: CGFloat, deltaY: CGFloat) {
        let constraints = boundaryConstraints
        switch handle {
        case .topLeft, .topRight, .bottomLeft, .bottomRight:
            applyCornerResizeDelta(handle: handle, frame: &frame, deltaX: deltaX, deltaY: deltaY, constraints: constraints)
        case .top, .bottom, .left, .right:
            applyEdgeResizeDelta(handle: handle, frame: &frame, deltaX: deltaX, deltaY: deltaY, constraints: constraints)
        }
    }

    private func applyCornerResizeDelta(
        handle: ResizeHandle,
        frame: inout CGRect,
        deltaX: CGFloat,
        deltaY: CGFloat,
        constraints: (minX: CGFloat, minY: CGFloat, maxX: CGFloat, maxY: CGFloat),
    ) {
        var limitedDeltaX = deltaX
        var limitedDeltaY = deltaY
        switch handle {
        case .topLeft:
            if frame.minY + deltaY < constraints.minY { limitedDeltaY = constraints.minY - frame.minY }
            if frame.minX + deltaX < constraints.minX { limitedDeltaX = constraints.minX - frame.minX }
            frame.origin.x += limitedDeltaX
            frame.origin.y += limitedDeltaY
            frame.size.width -= limitedDeltaX
            frame.size.height -= limitedDeltaY
        case .topRight:
            if frame.minY + deltaY < constraints.minY { limitedDeltaY = constraints.minY - frame.minY }
            if frame.maxX + deltaX > constraints.maxX { limitedDeltaX = constraints.maxX - frame.maxX }
            frame.origin.y += limitedDeltaY
            frame.size.width += limitedDeltaX
            frame.size.height -= limitedDeltaY
        case .bottomLeft:
            if frame.maxY - deltaY > constraints.maxY { limitedDeltaY = frame.maxY - constraints.maxY }
            if frame.minX + deltaX < constraints.minX { limitedDeltaX = constraints.minX - frame.minX }
            frame.origin.x += limitedDeltaX
            frame.size.width -= limitedDeltaX
            frame.size.height += limitedDeltaY
        case .bottomRight:
            if frame.maxY + deltaY > constraints.maxY { limitedDeltaY = constraints.maxY - frame.maxY }
            if frame.maxX + deltaX > constraints.maxX { limitedDeltaX = constraints.maxX - frame.maxX }
            frame.size.width += limitedDeltaX
            frame.size.height += limitedDeltaY
        default:
            break
        }
    }

    private func applyEdgeResizeDelta(
        handle: ResizeHandle,
        frame: inout CGRect,
        deltaX: CGFloat,
        deltaY: CGFloat,
        constraints: (minX: CGFloat, minY: CGFloat, maxX: CGFloat, maxY: CGFloat),
    ) {
        var limitedDeltaX = deltaX
        var limitedDeltaY = deltaY
        switch handle {
        case .top:
            if frame.minY + deltaY < constraints.minY { limitedDeltaY = constraints.minY - frame.minY }
            frame.origin.y += limitedDeltaY
            frame.size.height -= limitedDeltaY
        case .bottom:
            if frame.maxY + deltaY > constraints.maxY { limitedDeltaY = constraints.maxY - frame.maxY }
            frame.size.height += limitedDeltaY
        case .left:
            if frame.minX + deltaX < constraints.minX { limitedDeltaX = constraints.minX - frame.minX }
            frame.origin.x += limitedDeltaX
            frame.size.width -= limitedDeltaX
        case .right:
            if frame.maxX + deltaX > constraints.maxX { limitedDeltaX = constraints.maxX - frame.maxX }
            frame.size.width += limitedDeltaX
        default:
            break
        }
    }

    // MARK: - Hit Testing

    /// Distance-based hit testing — avoids CGRect array allocation on every touch.
    private func getResizeHandle(at location: CGPoint) -> ResizeHandle? {
        let local = view.convert(location, to: cropFrameView)
        let w = cropFrame.width
        let h = cropFrame.height
        let halfHit = Self.handleHitSize / 2

        // Corner handles (check first — corners overlap edge hit areas)
        let cornerPoints: [(CGPoint, ResizeHandle)] = [
            (CGPoint(x: 0, y: 0), .topLeft),
            (CGPoint(x: w, y: 0), .topRight),
            (CGPoint(x: 0, y: h), .bottomLeft),
            (CGPoint(x: w, y: h), .bottomRight),
        ]
        for (point, handle) in cornerPoints {
            if abs(local.x - point.x) <= halfHit, abs(local.y - point.y) <= halfHit {
                return handle
            }
        }

        // Edge handles (only for free ratio)
        if currentAspectRatio == .free {
            let edgePoints: [(CGPoint, ResizeHandle)] = [
                (CGPoint(x: w / 2, y: 0), .top),
                (CGPoint(x: w / 2, y: h), .bottom),
                (CGPoint(x: 0, y: h / 2), .left),
                (CGPoint(x: w, y: h / 2), .right),
            ]
            for (point, handle) in edgePoints {
                if abs(local.x - point.x) <= halfHit, abs(local.y - point.y) <= halfHit {
                    return handle
                }
            }
        }

        return nil
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        delegate?.photoCropViewControllerDidCancel(self)
    }

    @objc private func doneTapped() {
        guard cropFrame.width > 0, cropFrame.height > 0,
              let croppedImage = cropImage() else {
            LMKLogger.warning("Crop failed — delivering original image. cropFrame=\(cropFrame)", category: .ui)
            delegate?.photoCropViewController(self, didCropImage: image)
            return
        }

        delegate?.photoCropViewController(self, didCropImage: croppedImage)
    }

    // MARK: - Crop

    private func cropImage() -> UIImage? {
        let imageViewFrame = imageView.frame

        // Convert crop frame from view coordinates to image view coordinates
        let cropInImageView = CGRect(
            x: cropFrame.origin.x - imageViewFrame.origin.x,
            y: cropFrame.origin.y - imageViewFrame.origin.y,
            width: cropFrame.width,
            height: cropFrame.height,
        )

        // Scale from image view to actual image pixel coordinates
        let scale = image.size.width / imageViewFrame.width
        let imageCropRect = CGRect(
            x: cropInImageView.origin.x * scale,
            y: cropInImageView.origin.y * scale,
            width: cropInImageView.width * scale,
            height: cropInImageView.height * scale,
        )

        // Clamp to image bounds, snapping to whole pixels to prevent
        // anti-aliasing artifacts (1px white line) at fractional boundaries
        let clampedRect = imageCropRect.intersection(CGRect(origin: .zero, size: image.size)).integral
        guard !clampedRect.isEmpty, clampedRect.width > 0, clampedRect.height > 0,
              let cgImage = image.cgImage?.cropping(to: clampedRect) else {
            return nil
        }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension LMKPhotoCropViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow pinch and pan to work simultaneously for better UX
        if (gestureRecognizer is UIPinchGestureRecognizer && otherGestureRecognizer is UIPanGestureRecognizer) ||
            (gestureRecognizer is UIPanGestureRecognizer && otherGestureRecognizer is UIPinchGestureRecognizer) {
            return true
        }
        return false
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UIPinchGestureRecognizer {
            return true
        }

        guard gestureRecognizer.view == cropFrameView || gestureRecognizer.view == view else {
            return true
        }

        guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }

        let location = panGesture.location(in: view)

        // Don't interfere with aspect ratio control
        if aspectRatioControl.frame.contains(location) {
            return false
        }

        // If touching resize handle, only allow resize gesture (on view)
        if getResizeHandle(at: location) != nil {
            return gestureRecognizer.view == view
        }

        // If touching crop frame area, allow crop frame pan gesture
        if cropFrame.contains(location) {
            return gestureRecognizer.view == cropFrameView
        }

        return false
    }
}
