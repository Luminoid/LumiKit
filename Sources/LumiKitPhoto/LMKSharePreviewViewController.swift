//
//  LMKSharePreviewViewController.swift
//  LumiKit
//
//  Sheet that previews an image with Share and Save Image actions, styled
//  from `theme.sharePreview`.
//

import LumiKitCore
import LumiKitUI
import Photos
import SnapKit
import UIKit

// MARK: - Style

public extension LMKSharePreviewViewController {
    /// Appearance of the sheet: background, image corners, the two action buttons, and the
    /// close button. Every field is optional; `nil` resolves from `theme.sharePreview`.
    nonisolated struct Style: Sendable, Equatable, LMKThemeExtension {
        /// Sheet background; `nil` = `backgroundPrimary`.
        public var backgroundColor: UIColor?
        /// Image corners; `nil` = `medium`.
        public var imageCorners: LMKCornerStyle?
        /// Behind the image (visible around a non-rectangular image); `nil` = clear.
        public var imageBackgroundColor: UIColor?
        /// Insets around the image and buttons; `nil` = `spacing.large` all around.
        public var contentInsets: NSDirectionalEdgeInsets?
        /// Gap between the image and the buttons; `nil` = `spacing.xl`.
        public var buttonsTopSpacing: CGFloat?
        /// Gap between the two buttons; `nil` = `spacing.medium`.
        public var buttonSpacing: CGFloat?
        /// Layered on the Share button (filled `secondary`, `medium` corners).
        public var shareButton: LMKButton.Style
        /// Layered on the Save Image button (filled `secondary`, `medium` corners).
        public var saveButton: LMKButton.Style
        /// Layered on the close button (a `backgroundSecondary` circle with a `textSecondary` glyph).
        public var closeButton: LMKButton.Style
        /// Visual side of the close button (its hit target stays 44pt); `nil` = 32.
        public var closeButtonSize: CGFloat?
        /// Whether the close button is installed; `nil` = true.
        public var showsCloseButton: Bool?
        /// Whether the Save Image button is installed; `nil` = true.
        public var showsSaveButton: Bool?

        public init(
            backgroundColor: UIColor? = nil,
            imageCorners: LMKCornerStyle? = nil,
            imageBackgroundColor: UIColor? = nil,
            contentInsets: NSDirectionalEdgeInsets? = nil,
            buttonsTopSpacing: CGFloat? = nil,
            buttonSpacing: CGFloat? = nil,
            shareButton: LMKButton.Style = LMKButton.Style(),
            saveButton: LMKButton.Style = LMKButton.Style(),
            closeButton: LMKButton.Style = LMKButton.Style(),
            closeButtonSize: CGFloat? = nil,
            showsCloseButton: Bool? = nil,
            showsSaveButton: Bool? = nil
        ) {
            self.backgroundColor = backgroundColor
            self.imageCorners = imageCorners
            self.imageBackgroundColor = imageBackgroundColor
            self.contentInsets = contentInsets
            self.buttonsTopSpacing = buttonsTopSpacing
            self.buttonSpacing = buttonSpacing
            self.shareButton = shareButton
            self.saveButton = saveButton
            self.closeButton = closeButton
            self.closeButtonSize = closeButtonSize
            self.showsCloseButton = showsCloseButton
            self.showsSaveButton = showsSaveButton
        }

        public static let defaultValue = Self()

        /// `other`'s non-nil fields over this style's.
        public func merging(_ other: Self) -> Self {
            Self(
                backgroundColor: other.backgroundColor ?? backgroundColor,
                imageCorners: other.imageCorners ?? imageCorners,
                imageBackgroundColor: other.imageBackgroundColor ?? imageBackgroundColor,
                contentInsets: other.contentInsets ?? contentInsets,
                buttonsTopSpacing: other.buttonsTopSpacing ?? buttonsTopSpacing,
                buttonSpacing: other.buttonSpacing ?? buttonSpacing,
                shareButton: shareButton.merging(other.shareButton),
                saveButton: saveButton.merging(other.saveButton),
                closeButton: closeButton.merging(other.closeButton),
                closeButtonSize: other.closeButtonSize ?? closeButtonSize,
                showsCloseButton: other.showsCloseButton ?? showsCloseButton,
                showsSaveButton: other.showsSaveButton ?? showsSaveButton
            )
        }
    }

    // MARK: - Strings

    /// User-visible strings of the sheet, defaulting to the package's localized values.
    nonisolated struct Strings: Sendable, Equatable {
        /// Share button title.
        public var share: String
        /// Save Image button title.
        public var saveImage: String
        /// Message shown when photo library permission is denied.
        public var photoPermissionDenied: String
        /// Accessibility label of the close button.
        public var closeAccessibilityLabel: String

        public init(
            share: String = LMKLocalized("sharePreview.share"),
            saveImage: String = LMKLocalized("sharePreview.saveImage"),
            photoPermissionDenied: String = LMKLocalized("sharePreview.photoPermissionDenied"),
            closeAccessibilityLabel: String = LMKLocalized("sharePreview.close.accessibilityLabel")
        ) {
            self.share = share
            self.saveImage = saveImage
            self.photoPermissionDenied = photoPermissionDenied
            self.closeAccessibilityLabel = closeAccessibilityLabel
        }
    }

    /// Why sharing or saving failed.
    nonisolated enum Failure: Error {
        case share(any Error)
        case save(any Error)
        /// Photo library add access was denied or restricted.
        case photoLibraryAccessDenied
    }
}

public nonisolated extension LMKTheme {
    /// App-wide default style for `LMKSharePreviewViewController`.
    var sharePreview: LMKSharePreviewViewController.Style {
        get { self[LMKSharePreviewViewController.Style.self] }
        set { self[LMKSharePreviewViewController.Style.self] = newValue }
    }
}

// MARK: - LMKSharePreviewViewController

/// Sheet that previews an image with Share and Save to Photos actions.
///
/// ```swift
/// let preview = LMKSharePreviewViewController(image: renderedCard)
/// preview.onShare = { [weak self] activity in self?.trackShare(activity) }
/// preview.onSave = { [weak self] in self?.showSavedToast() }
/// present(preview, animated: true)
/// ```
///
/// Saving writes to the photo library through `PHPhotoLibrary`'s add-only access, so the host
/// app's Info.plist must carry `NSPhotoLibraryAddUsageDescription`; without it the save button
/// should be hidden (`Style.showsSaveButton = false`).
public final class LMKSharePreviewViewController: UIViewController, LMKThemeApplying {
    // MARK: - Configurable Strings

    /// Process-wide strings, read when a sheet is created. Override at app launch to localize.
    public nonisolated(unsafe) static var strings = Strings()

    /// This sheet's strings.
    public var strings: Strings = LMKSharePreviewViewController.strings {
        didSet {
            guard isViewLoaded else { return }
            applyStrings()
        }
    }

    // MARK: - Properties

    /// The image being previewed.
    public let image: UIImage

    /// Called after a share completes, with the chosen activity.
    public var onShare: ((UIActivity.ActivityType?) -> Void)?
    /// Called after the image lands in the photo library.
    public var onSave: (() -> Void)?
    /// Called when sharing or saving fails. While `nil`, a denied photo library shows a warning alert.
    public var onFailure: ((Failure) -> Void)?
    /// Called when the sheet is dismissed (close button, swipe, or after a save).
    public var onDismiss: (() -> Void)?
    /// Whether a successful save dismisses the sheet. Default `true`.
    public var dismissesAfterSave = true

    /// Per-instance style, layered over `theme.sharePreview`.
    public var style: Style {
        didSet {
            guard style != oldValue, isViewLoaded else { return }
            applyTheme(traitCollection.lmkTheme)
        }
    }

    /// Called at the end of every `applyTheme`, for tweaks the style does not cover.
    public var didApplyStyle: ((LMKSharePreviewViewController) -> Void)?

    /// The style in effect after the theme and instance style are merged.
    public private(set) var resolvedStyle = Style()

    /// Stored so dismissing the sheet mid-save cancels the in-flight task.
    private var saveTask: Task<Void, Never>?
    private var contentInsets = NSDirectionalEdgeInsets.zero
    private var closeButtonSizeConstraint: Constraint?
    private var buttonsTopConstraint: Constraint?
    private var imageAspectConstraint: Constraint?

    deinit {
        saveTask?.cancel()
    }

    // MARK: - Views

    public let scrollView = UIScrollView()
    public let contentView = UIView()
    public let imageView = UIImageView()
    public let closeButton = LMKButton(style: .iconOnly(.neutral))
    public let shareButton = LMKButton(style: .filled(.secondary))
    public let saveButton = LMKButton(style: .filled(.secondary))
    private let buttonStack = UIStackView()

    // MARK: - Initialization

    /// - Parameters:
    ///   - image: The image to preview.
    ///   - detents: Sheet detents; default `[.large()]`.
    ///   - style: Per-instance style, layered over `theme.sharePreview`.
    public init(image: UIImage, detents: [UISheetPresentationController.Detent] = [.large()], style: Style = Style()) {
        self.image = image
        self.style = style
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
        if let sheet = sheetPresentationController {
            sheet.detents = detents.isEmpty ? [.large()] : detents
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
        }
        presentationController?.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        applyStrings()
        lmk_startApplyingTheme()
    }

    // MARK: - Setup

    private func setupUI() {
        closeButton.setSymbol("xmark", weight: .semibold)
        closeButton.onTap = { [weak self] in self?.closeTapped() }
        view.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(LMKSpacing.large)
            make.trailing.equalTo(view.safeAreaLayoutGuide).inset(LMKSpacing.large)
            closeButtonSizeConstraint = make.size.equalTo(LMKLayout.minimumTouchTarget).constraint
        }

        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = true
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(closeButton.snp.bottom).offset(LMKSpacing.small)
            make.leading.trailing.bottom.equalToSuperview()
        }

        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }

        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)

        shareButton.setSymbol("square.and.arrow.up")
        shareButton.onTap = { [weak self] in self?.share() }
        saveButton.setSymbol("square.and.arrow.down")
        saveButton.onTap = { [weak self] in self?.saveToPhotoLibrary() }
        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.lmk_addArrangedSubviews([shareButton, saveButton])
        contentView.addSubview(buttonStack)

        let aspectRatio = image.size.width > 0 ? image.size.height / image.size.width : 1
        imageView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(LMKSpacing.large)
            make.leading.trailing.equalToSuperview().inset(LMKSpacing.large)
            imageAspectConstraint = make.height.equalTo(imageView.snp.width).multipliedBy(aspectRatio).constraint
        }
        buttonStack.snp.makeConstraints { make in
            buttonsTopConstraint = make.top.equalTo(imageView.snp.bottom).offset(LMKSpacing.xl).constraint
            make.leading.trailing.equalToSuperview().inset(LMKSpacing.large)
            make.height.greaterThanOrEqualTo(LMKLayout.minimumTouchTarget)
            make.bottom.equalToSuperview().inset(LMKSpacing.xl)
        }
    }

    private func applyStrings() {
        shareButton.title = strings.share
        saveButton.title = strings.saveImage
        closeButton.accessibilityLabel = strings.closeAccessibilityLabel
    }

    // MARK: - Theme

    public func applyTheme(_ theme: LMKTheme) {
        resolvedStyle = theme.sharePreview.merging(style)
        let resolved = resolvedStyle

        view.backgroundColor = resolved.backgroundColor ?? LMKColor.backgroundPrimary
        imageView.backgroundColor = resolved.imageBackgroundColor ?? .clear
        imageView.lmk_applyCornerStyle(resolved.imageCorners ?? .fixed(theme.cornerRadius.medium))

        let insets = resolved.contentInsets ?? .lmk_all(theme.spacing.large)
        if insets != contentInsets {
            contentInsets = insets
            imageView.snp.updateConstraints { make in
                make.top.equalToSuperview().inset(insets.top)
                make.leading.equalToSuperview().inset(insets.leading)
                make.trailing.equalToSuperview().inset(insets.trailing)
            }
            buttonStack.snp.updateConstraints { make in
                make.leading.equalToSuperview().inset(insets.leading)
                make.trailing.equalToSuperview().inset(insets.trailing)
            }
        }
        buttonsTopConstraint?.update(offset: resolved.buttonsTopSpacing ?? theme.spacing.xl)
        buttonStack.spacing = resolved.buttonSpacing ?? theme.spacing.medium

        let actionBase = LMKButton.Style(
            role: .secondary,
            variant: .filled,
            surface: LMKSurfaceStyle(corners: .fixed(theme.cornerRadius.medium)),
            imagePadding: theme.spacing.xs,
            minimumHeight: theme.layout.minimumTouchTarget
        )
        shareButton.style = actionBase.merging(resolved.shareButton)
        saveButton.style = actionBase.merging(resolved.saveButton)
        saveButton.isHidden = !(resolved.showsSaveButton ?? true)

        let closeSide = resolved.closeButtonSize ?? Self.defaultCloseButtonSize
        closeButton.style = LMKButton.Style(
            role: .neutral,
            variant: .filled,
            surface: LMKSurfaceStyle(background: .solid(LMKColor.backgroundSecondary), corners: .circle, shadow: LMKShadowSource.none),
            foregroundColor: LMKColor.textSecondary,
            symbolPointSize: theme.layout.symbolRow,
            symbolWeight: .semibold,
            minimumHeight: closeSide
        ).merging(resolved.closeButton)
        closeButtonSizeConstraint?.update(offset: closeSide)
        closeButton.isHidden = !(resolved.showsCloseButton ?? true)
        didApplyStyle?(self)
    }

    private static let defaultCloseButtonSize: CGFloat = 32

    // MARK: - Actions

    private func closeTapped() {
        dismiss(animated: true) { [weak self] in
            self?.onDismiss?()
        }
    }

    /// Presents the system share sheet for the image.
    public func share() {
        LMKShare.image(image, from: self, sourceView: shareButton) { [weak self] result in
            guard let self else { return }
            switch result {
            case let .completed(activityType):
                onShare?(activityType)
            case let .failed(error):
                onFailure?(.share(error))
            case .cancelled:
                break
            }
        }
    }

    /// Saves the image to the photo library, asking for add-only access first when needed.
    public func saveToPhotoLibrary() {
        switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
        case .authorized, .limited:
            performSave()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] newStatus in
                Task { @MainActor in
                    if newStatus == .authorized || newStatus == .limited {
                        self?.performSave()
                    } else {
                        self?.reportPhotoLibraryDenied()
                    }
                }
            }
        case .denied, .restricted:
            reportPhotoLibraryDenied()
        @unknown default:
            reportPhotoLibraryDenied()
        }
    }

    // MARK: - Helpers

    private func performSave() {
        let imageToSave = image
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            let (success, error) = await Self.saveImageToPhotoLibrary(imageToSave)
            guard let self, !Task.isCancelled else { return }
            if let error {
                LMKLogger.error("Failed to save image to photos", error: error, category: .general)
                onFailure?(.save(error))
            } else if success {
                LMKLogger.info("Image saved to photos", category: .general)
                onSave?()
                if dismissesAfterSave {
                    dismiss(animated: true) { [weak self] in
                        self?.onDismiss?()
                    }
                }
            }
        }
    }

    /// Fully severs main-actor isolation so the `performChanges` closure runs on the background
    /// queue Photos dispatches it to.
    private nonisolated static func saveImageToPhotoLibrary(_ image: UIImage) async -> (Bool, (any Error)?) {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                continuation.resume(returning: (success, error))
            }
        }
    }

    private func reportPhotoLibraryDenied() {
        if let onFailure {
            onFailure(.photoLibraryAccessDenied)
        } else {
            LMKErrorHandler.present(from: self, message: strings.photoPermissionDenied, severity: .warning)
        }
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension LMKSharePreviewViewController: UIAdaptivePresentationControllerDelegate {
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        onDismiss?()
    }
}
