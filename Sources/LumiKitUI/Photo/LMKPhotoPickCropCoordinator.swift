//
//  LMKPhotoPickCropCoordinator.swift
//  LumiKit
//
//  Pick, square-crop, and store a single photo.
//

import PhotosUI
import UIKit

/// Orchestrates pick → square-crop → store for a single photo, then hands back the
/// stored identifier. Uses a permission-free `PHPicker` (no photo-library access,
/// no Info.plist usage string). Storage is injected via `save`, so the coordinator
/// stays storage-agnostic. `croppingEnabled: false` skips the crop editor and
/// stores the picked image as-is (receipts, documents). Retain it for the flow's duration: the host view
/// controller holds it in a property, since `PHPickerViewController` and the crop
/// controller only weakly reference their delegates through this object.
///
/// ```swift
/// coordinator = LMKPhotoPickCropCoordinator(
///     host: self,
///     save: { PhotoStorageService.shared.save($0) },
///     onSaved: { [weak self] identifier in self?.viewModel.setCover(identifier) }
/// )
/// coordinator?.start()
/// ```
public final class LMKPhotoPickCropCoordinator: NSObject {
    // MARK: - Properties

    private weak var host: UIViewController?
    private let save: (UIImage) -> String?
    private let onSaved: (String) -> Void
    private let onFailure: () -> Void
    private let croppingEnabled: Bool

    // MARK: - Init

    /// - Parameters:
    ///   - host: The view controller to present the picker and crop editor from.
    ///   - croppingEnabled: Whether the picked photo goes through the square-crop
    ///     editor before storage. Pass `false` for content whose full frame matters
    ///     (receipts, documents); the picked image then stores as-is.
    ///   - save: Stores the resulting image and returns its identifier, or `nil` on failure.
    ///   - onSaved: Called with the identifier returned by `save`.
    ///   - onFailure: Called when `save` returns `nil`. Defaults to a no-op.
    public init(
        host: UIViewController,
        croppingEnabled: Bool = true,
        save: @escaping (UIImage) -> String?,
        onSaved: @escaping (String) -> Void,
        onFailure: @escaping () -> Void = {}
    ) {
        self.host = host
        self.croppingEnabled = croppingEnabled
        self.save = save
        self.onSaved = onSaved
        self.onFailure = onFailure
        super.init()
    }

    // MARK: - Flow

    /// Presents the photo picker from the host.
    public func start() {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        host?.present(picker, animated: true)
    }

    private func presentCrop(_ image: UIImage) {
        let crop = LMKPhotoCropViewController(image: image, delegate: self)
        crop.modalPresentationStyle = .overFullScreen
        crop.modalPresentationCapturesStatusBarAppearance = true
        host?.present(crop, animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate

extension LMKPhotoPickCropCoordinator: PHPickerViewControllerDelegate {
    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let image = object as? UIImage else { return }
            Task { @MainActor in
                guard let self else { return }
                if self.croppingEnabled {
                    self.presentCrop(image)
                } else {
                    self.commit(image)
                }
            }
        }
    }

    private func commit(_ image: UIImage) {
        if let identifier = save(image) {
            onSaved(identifier)
        } else {
            onFailure()
        }
    }
}

// MARK: - LMKPhotoCropDelegate

extension LMKPhotoPickCropCoordinator: LMKPhotoCropDelegate {
    public func photoCropViewController(_ controller: LMKPhotoCropViewController, didCropImage image: UIImage) {
        controller.dismiss(animated: true)
        commit(image)
    }

    public func photoCropViewControllerDidCancel(_ controller: LMKPhotoCropViewController) {
        controller.dismiss(animated: true)
    }
}
