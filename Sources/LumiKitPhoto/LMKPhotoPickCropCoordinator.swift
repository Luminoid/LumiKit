//
//  LMKPhotoPickCropCoordinator.swift
//  LumiKit
//
//  Pick, crop, and store a single photo.
//

import LumiKitCore
import LumiKitUI
import PhotosUI
import UIKit
import UniformTypeIdentifiers

/// Orchestrates pick → crop → store for a single photo, then hands back the stored identifier.
///
/// The picker is a permission-free `PHPicker` (no photo-library access, no usage string). The
/// picked bytes are read once, so the capture date and location survive the decode and reach
/// `onPicked` and `save` as `LMKPhotoMetadata` (the cropped image itself carries none; stamp
/// it back with `LMKPhotoMetadata.write(date:coordinate:to:)` when storing). Storage is
/// injected via `save`, so the coordinator stays storage-agnostic.
///
/// Retain the coordinator for the flow's duration: the host holds it in a property, since the
/// picker and the crop editor only weakly reference it.
/// ```swift
/// coordinator = LMKPhotoPickCropCoordinator(
///     host: self,
///     save: { image, metadata in await PhotoStorage.shared.save(image, takenOn: metadata.date) },
///     onSaved: { [weak self] identifier in self?.viewModel.setCover(identifier) }
/// )
/// coordinator?.start()
/// ```
public final class LMKPhotoPickCropCoordinator: NSObject {
    /// Why a flow ended without a stored photo.
    public nonisolated enum Failure: Error {
        /// The picked item has no image representation.
        case unsupportedItem
        /// Reading the picked bytes failed.
        case loadFailed(any Error)
        /// The bytes are not a decodable image.
        case decodeFailed
        /// `save` returned `nil`.
        case saveFailed
    }

    // MARK: - Properties

    private weak var host: UIViewController?
    private weak var cropController: LMKPhotoCropViewController?
    private let save: (UIImage, LMKPhotoMetadata) async -> String?
    private let onSaved: (String) -> Void
    private let onPicked: ((UIImage, LMKPhotoMetadata) -> Void)?
    private let onCancel: (() -> Void)?
    private let onFailure: ((Failure) -> Void)?
    private let croppingEnabled: Bool
    private let aspectRatio: LMKCropAspectRatio
    private let maximumPixelSize: CGFloat?
    private let cropStyle: LMKPhotoCropViewController.Style
    private var pickedMetadata = LMKPhotoMetadata.empty
    private var loadTask: Task<Void, Never>?
    private var saveTask: Task<Void, Never>?

    // MARK: - Init

    /// - Parameters:
    ///   - host: The view controller to present the picker and crop editor from.
    ///   - croppingEnabled: Whether the picked photo goes through the crop editor before
    ///     storage. Pass `false` for content whose full frame matters (receipts, documents).
    ///   - aspectRatio: The crop editor's initial preset (default square).
    ///   - maximumPixelSize: Downsamples the picked photo to this longest edge on decode;
    ///     `nil` decodes at full resolution.
    ///   - cropStyle: Per-instance style of the crop editor.
    ///   - save: Stores the image (with the metadata read from the original bytes) and returns
    ///     its identifier, or `nil` on failure.
    ///   - onSaved: Called with the identifier returned by `save`.
    ///   - onPicked: Called with the decoded photo and its metadata before the crop or save.
    ///   - onCancel: Called when the picker or the crop editor is dismissed without a photo.
    ///   - onFailure: Called when loading, decoding, or saving fails.
    public init(
        host: UIViewController,
        croppingEnabled: Bool = true,
        aspectRatio: LMKCropAspectRatio = .square,
        maximumPixelSize: CGFloat? = nil,
        cropStyle: LMKPhotoCropViewController.Style = LMKPhotoCropViewController.Style(),
        save: @escaping (UIImage, LMKPhotoMetadata) async -> String?,
        onSaved: @escaping (String) -> Void,
        onPicked: ((UIImage, LMKPhotoMetadata) -> Void)? = nil,
        onCancel: (() -> Void)? = nil,
        onFailure: ((Failure) -> Void)? = nil
    ) {
        self.host = host
        self.croppingEnabled = croppingEnabled
        self.aspectRatio = aspectRatio
        self.maximumPixelSize = maximumPixelSize
        self.cropStyle = cropStyle
        self.save = save
        self.onSaved = onSaved
        self.onPicked = onPicked
        self.onCancel = onCancel
        self.onFailure = onFailure
        super.init()
    }

    deinit {
        loadTask?.cancel()
        saveTask?.cancel()
    }

    // MARK: - Flow

    /// Presents the photo picker from the host.
    public func start() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        host?.present(picker, animated: true)
    }

    /// Cancels an in-flight decode or save; nothing is reported.
    public func cancel() {
        loadTask?.cancel()
        loadTask = nil
        saveTask?.cancel()
        saveTask = nil
    }

    /// Decodes the picked bytes (and their metadata) off the main actor, then crops or commits.
    func handlePicked(data: Data) {
        loadTask?.cancel()
        let maximumPixelSize = maximumPixelSize
        loadTask = Task { [weak self] in
            let (image, metadata) = await Self.decode(data, maximumPixelSize: maximumPixelSize)
            guard let self, !Task.isCancelled else { return }
            guard let image else {
                onFailure?(.decodeFailed)
                return
            }
            pickedMetadata = metadata
            onPicked?(image, metadata)
            if croppingEnabled {
                presentCrop(image)
            } else {
                commit(image)
            }
        }
    }

    func handleCropped(_ image: UIImage) {
        cropController?.dismiss(animated: true)
        cropController = nil
        commit(image)
    }

    func handleCropCancelled() {
        cropController?.dismiss(animated: true)
        cropController = nil
        onCancel?()
    }

    private func presentCrop(_ image: UIImage) {
        let crop = LMKPhotoCropViewController(image: image, initialAspectRatio: aspectRatio, style: cropStyle)
        crop.onCrop = { [weak self] cropped in self?.handleCropped(cropped) }
        crop.onCancel = { [weak self] in self?.handleCropCancelled() }
        cropController = crop
        host?.present(crop, animated: true)
    }

    private func commit(_ image: UIImage) {
        saveTask?.cancel()
        let metadata = pickedMetadata
        saveTask = Task { [weak self] in
            guard let self else { return }
            let identifier = await save(image, metadata)
            guard !Task.isCancelled else { return }
            if let identifier {
                onSaved(identifier)
            } else {
                onFailure?(.saveFailed)
            }
        }
    }

    /// Reads the metadata and decodes the image from the same bytes on the global executor.
    @concurrent
    nonisolated static func decode(_ data: Data, maximumPixelSize: CGFloat?) async -> (UIImage?, LMKPhotoMetadata) {
        let metadata = LMKPhotoMetadata.read(from: data)
        let image: UIImage? = if let maximumPixelSize {
            await LMKImage.downsample(data: data, maxPixelSize: maximumPixelSize)
        } else {
            UIImage(data: data).map { $0.preparingForDisplay() ?? $0 }
        }
        return (image, metadata)
    }
}

// MARK: - PHPickerViewControllerDelegate

extension LMKPhotoPickCropCoordinator: PHPickerViewControllerDelegate {
    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider else {
            onCancel?()
            return
        }
        guard provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) else {
            onFailure?(.unsupportedItem)
            return
        }
        // Raw bytes, never `loadObject(ofClass: UIImage.self)`: the decode strips the metadata.
        _ = provider.loadDataRepresentation(for: UTType.image) { [weak self] data, error in
            Task { @MainActor in
                guard let self else { return }
                if let data {
                    self.handlePicked(data: data)
                } else if let error {
                    self.onFailure?(.loadFailed(error))
                } else {
                    self.onFailure?(.unsupportedItem)
                }
            }
        }
    }
}
