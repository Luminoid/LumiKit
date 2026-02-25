//
//  LMKSharePreviewViewController.swift
//  LumiKit
//
//  Sheet that previews an image with Share and Save Image actions.
//

import LumiKitCore
import Photos
import SnapKit
import UIKit

// MARK: - Configurable Strings

/// Configurable strings for the share preview, allowing localization without R.swift.
public nonisolated struct LMKSharePreviewStrings: Sendable {
    /// Share button title.
    public var share: String
    /// Save image button title.
    public var saveImage: String
    /// Error message shown when saving fails.
    public var saveError: String
    /// Success message shown after saving.
    public var saveSuccess: String
    /// Message shown when photo library permission is denied.
    public var photoPermissionDenied: String

    public init(
        share: String = "Share",
        saveImage: String = "Save Image",
        saveError: String = "Failed to save image",
        saveSuccess: String = "Image saved to Photos",
        photoPermissionDenied: String = "Photo library access is required to save images. Please enable it in Settings."
    ) {
        self.share = share
        self.saveImage = saveImage
        self.saveError = saveError
        self.saveSuccess = saveSuccess
        self.photoPermissionDenied = photoPermissionDenied
    }
}

// MARK: - Delegate

/// Delegate for share preview actions.
public protocol LMKSharePreviewDelegate: AnyObject {
    /// Called after the user shares the image.
    func sharePreview(_ preview: LMKSharePreviewViewController, didShareWith activityType: UIActivity.ActivityType?)
    /// Called after the image is saved to the photo library.
    func sharePreviewDidSave(_ preview: LMKSharePreviewViewController)
    /// Called when the preview is dismissed.
    func sharePreviewDidDismiss(_ preview: LMKSharePreviewViewController)
}

public extension LMKSharePreviewDelegate {
    func sharePreview(_ preview: LMKSharePreviewViewController, didShareWith activityType: UIActivity.ActivityType?) {}
    func sharePreviewDidSave(_ preview: LMKSharePreviewViewController) {}
    func sharePreviewDidDismiss(_ preview: LMKSharePreviewViewController) {}
}

// MARK: - LMKSharePreviewViewController

/// Sheet that previews an image with Share and Save to Photos actions.
///
/// Configure strings at app launch:
/// ```swift
/// LMKSharePreviewViewController.strings = .init(share: "Share", saveImage: "Save Image")
/// ```
///
/// Present the preview:
/// ```swift
/// let preview = LMKSharePreviewViewController(image: renderedCard)
/// present(preview, animated: true)
/// ```
public final class LMKSharePreviewViewController: UIViewController {
    // MARK: - Configurable Strings

    /// Override at app launch with localized values.
    public nonisolated(unsafe) static var strings = LMKSharePreviewStrings()

    // MARK: - Properties

    private let image: UIImage
    public weak var delegate: (any LMKSharePreviewDelegate)?

    // MARK: - UI Components

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = true
        return scrollView
    }()

    private lazy var contentView = UIView()

    private lazy var cardImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = LMKCornerRadius.medium
        return imageView
    }()

    private lazy var shareButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "square.and.arrow.up")
        config.title = Self.strings.share
        config.imagePadding = LMKSpacing.xs
        config.cornerStyle = .medium
        config.baseBackgroundColor = LMKColor.secondary
        config.baseForegroundColor = .white
        config.buttonSize = .large
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var saveImageButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "square.and.arrow.down")
        config.title = Self.strings.saveImage
        config.imagePadding = LMKSpacing.xs
        config.cornerStyle = .medium
        config.baseBackgroundColor = LMKColor.secondary
        config.baseForegroundColor = .white
        config.buttonSize = .large
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(saveImageTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Initialization

    public init(image: UIImage) {
        self.image = image
        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .pageSheet
        if let sheet = sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = LMKColor.backgroundPrimary

        // Close button — 32pt visual size with expanded 44pt touch target
        let closeButton = LMKTouchExpandedButton(type: .system)
        let closeConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        closeButton.setImage(UIImage(systemName: "xmark", withConfiguration: closeConfig), for: .normal)
        closeButton.tintColor = LMKColor.textSecondary
        closeButton.backgroundColor = LMKColor.backgroundSecondary
        closeButton.layer.cornerRadius = LMKCornerRadius.large
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        let closeButtonSize: CGFloat = 32
        let touchInset = -(LMKLayout.minimumTouchTarget - closeButtonSize) / 2
        closeButton.lmk_touchAreaEdgeInsets = UIEdgeInsets(top: touchInset, left: touchInset, bottom: touchInset, right: touchInset)
        view.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(LMKSpacing.large)
            make.trailing.equalToSuperview().inset(LMKSpacing.large)
            make.width.height.equalTo(closeButtonSize)
        }

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

        // Card image
        cardImageView.image = image
        contentView.addSubview(cardImageView)

        let imageAspectRatio = image.size.height / image.size.width

        cardImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(LMKSpacing.large)
            make.leading.trailing.equalToSuperview().inset(LMKSpacing.large)
            make.height.equalTo(cardImageView.snp.width).multipliedBy(imageAspectRatio)
        }

        // Button stack
        let buttonStack = UIStackView(arrangedSubviews: [shareButton, saveImageButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = LMKSpacing.medium
        buttonStack.distribution = .fillEqually

        contentView.addSubview(buttonStack)
        buttonStack.snp.makeConstraints { make in
            make.top.equalTo(cardImageView.snp.bottom).offset(LMKSpacing.xl)
            make.leading.trailing.equalToSuperview().inset(LMKSpacing.large)
            make.height.equalTo(LMKLayout.minimumTouchTarget)
            make.bottom.equalToSuperview().offset(-LMKSpacing.xl)
        }
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        dismiss(animated: true) { [weak self] in
            guard let self else { return }
            delegate?.sharePreviewDidDismiss(self)
        }
    }

    @objc private func shareButtonTapped() {
        LMKShareService.shareImage(
            image,
            from: self,
            sourceView: shareButton
        ) { [weak self] activityType in
            guard let self else { return }
            self.delegate?.sharePreview(self, didShareWith: activityType)
        }
    }

    @objc private func saveImageTapped() {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)

        switch status {
        case .authorized, .limited:
            performSaveImage()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        self?.performSaveImage()
                    } else {
                        self?.showPhotoPermissionDenied()
                    }
                }
            }
        case .denied, .restricted:
            showPhotoPermissionDenied()
        @unknown default:
            showPhotoPermissionDenied()
        }
    }

    // MARK: - Helpers

    private func performSaveImage() {
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: self.image)
        } completionHandler: { [weak self] success, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    LMKLogger.error("Failed to save image to photos", error: error, category: .general)
                    LMKToast.showError(message: Self.strings.saveError, on: self)
                } else if success {
                    LMKLogger.info("Image saved to photos", category: .general)
                    LMKToast.showSuccessOnWindow(message: Self.strings.saveSuccess)
                    self.delegate?.sharePreviewDidSave(self)
                    self.dismiss(animated: true) { [weak self] in
                        guard let self else { return }
                        self.delegate?.sharePreviewDidDismiss(self)
                    }
                }
            }
        }
    }

    private func showPhotoPermissionDenied() {
        LMKErrorHandler.present(
            on: self,
            message: Self.strings.photoPermissionDenied,
            severity: .warning
        )
    }
}

// MARK: - Touch Expanded Button

/// Button subclass that respects `lmk_touchAreaEdgeInsets` for hit-testing.
private final class LMKTouchExpandedButton: UIButton {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        lmk_pointInside(point, with: event)
    }
}
