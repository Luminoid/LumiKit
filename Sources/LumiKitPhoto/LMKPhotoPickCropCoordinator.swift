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
/// The crop editor is presented once the picker's dismissal has finished and the photo is
/// decoded, whichever comes last. Every failure is logged; with no `onFailure` it is shown
/// to the user through `LMKErrorHandler` on the host.
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
    /// Why a flow ended without a stored photo. `errorDescription` is the user-facing message
    /// from the process-wide `strings`.
    public nonisolated enum Failure: LocalizedError {
        /// The picked item has no image representation.
        case unsupportedItem
        /// Reading the picked bytes failed.
        case loadFailed(any Error)
        /// The bytes are not a decodable image.
        case decodeFailed
        /// `save` returned `nil`.
        case saveFailed
        /// The host could not present the crop editor: it went away, is off screen, or is
        /// already presenting something else.
        case hostUnavailable

        public var errorDescription: String? {
            switch self {
            case .unsupportedItem, .loadFailed, .decodeFailed: LMKPhotoPickCropCoordinator.strings.loadFailedMessage
            case .saveFailed: LMKPhotoPickCropCoordinator.strings.saveFailedMessage
            case .hostUnavailable: LMKPhotoPickCropCoordinator.strings.hostUnavailableMessage
            }
        }
    }

    /// User-visible strings of the coordinator, defaulting to the package's localized values.
    public nonisolated struct Strings: Sendable, Equatable {
        /// Shown when the picked item cannot be read or decoded.
        public var loadFailedMessage: String
        /// Shown when `save` fails.
        public var saveFailedMessage: String
        /// Shown when the crop editor cannot be presented.
        public var hostUnavailableMessage: String

        public init(
            loadFailedMessage: String = LMKLocalized("photoPickCrop.loadFailed"),
            saveFailedMessage: String = LMKLocalized("photoPickCrop.saveFailed"),
            hostUnavailableMessage: String = LMKLocalized("photoPickCrop.hostUnavailable")
        ) {
            self.loadFailedMessage = loadFailedMessage
            self.saveFailedMessage = saveFailedMessage
            self.hostUnavailableMessage = hostUnavailableMessage
        }
    }

    /// Process-wide strings, read when a coordinator is created. Override at app launch to localize.
    public nonisolated(unsafe) static var strings = Strings()

    // MARK: - Properties

    /// This coordinator's strings.
    public var strings: Strings = LMKPhotoPickCropCoordinator.strings

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
    /// The item provider's load, cancelled with the flow.
    private var loadProgress: Progress?
    private var loadTask: Task<Void, Never>?
    private var saveTask: Task<Void, Never>?
    /// Bumped by `cancel()`; a load completion from an earlier flow compares it and stops.
    private var flowGeneration: UInt64 = 0
    /// True from the picker's dismissal until it has completed; the crop editor waits for it.
    private var isPickerDismissing = false
    /// The decoded photo waiting for the picker's dismissal to complete.
    private var pendingCropImage: UIImage?

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
    ///   - onFailure: Called when loading, decoding, presenting, or saving fails. While `nil`,
    ///     the failure is shown to the user through `LMKErrorHandler` on the host.
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
        loadProgress?.cancel()
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
        guard let host else {
            LMKLogger.warning("LMKPhotoPickCropCoordinator: the host is gone; the picker is not shown", category: .lumiKit)
            return
        }
        if !host.lmk_canPresentAlert {
            // UIKit refuses the presentation and the flow ends without a callback.
            LMKLogger.warning("LMKPhotoPickCropCoordinator: \(type(of: host)) is off screen or already presenting; the picker may not appear", category: .lumiKit)
        }
        host.present(picker, animated: true)
    }

    /// Cancels an in-flight load, decode, or save; nothing is reported, and a crop editor
    /// waiting to be presented is dropped.
    public func cancel() {
        flowGeneration &+= 1
        loadProgress?.cancel()
        loadProgress = nil
        loadTask?.cancel()
        loadTask = nil
        saveTask?.cancel()
        saveTask = nil
        pendingCropImage = nil
    }

    /// Decodes the picked bytes (and their metadata) off the main actor, then crops or commits.
    func handlePicked(data: Data) {
        loadTask?.cancel()
        let maximumPixelSize = maximumPixelSize
        loadTask = Task { [weak self] in
            let (image, metadata) = await Self.decode(data, maximumPixelSize: maximumPixelSize)
            guard let self, !Task.isCancelled else { return }
            guard let image else {
                report(.decodeFailed, note: "\(data.count) bytes, type \(Self.typeIdentifier(of: data))")
                return
            }
            pickedMetadata = metadata
            onPicked?(image, metadata)
            if croppingEnabled {
                pendingCropImage = image
                presentCropIfReady()
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

    /// Presents the crop editor once both the decode and the picker's dismissal are done.
    private func presentCropIfReady() {
        guard !isPickerDismissing, let image = pendingCropImage else { return }
        pendingCropImage = nil
        guard let host, host.presentedViewController == nil, host.viewIfLoaded?.window != nil else {
            report(.hostUnavailable)
            return
        }
        let crop = LMKPhotoCropViewController(image: image, initialAspectRatio: aspectRatio, style: cropStyle)
        crop.onCrop = { [weak self] cropped in self?.handleCropped(cropped) }
        crop.onCancel = { [weak self] in self?.handleCropCancelled() }
        cropController = crop
        host.present(crop, animated: true)
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
                report(.saveFailed)
            }
        }
    }

    /// The one path every failure takes: logged, then handed to `onFailure`, or shown to the
    /// user on the host when there is none. `note` adds public context (sizes, type identifiers).
    private func report(_ failure: Failure, note: String? = nil) {
        LMKLogger.error("LMKPhotoPickCropCoordinator: the flow failed\(note.map { " (\($0))" } ?? "")", error: failure, category: .lumiKit)
        if let onFailure {
            onFailure(failure)
        } else if let host {
            LMKErrorHandler.present(from: host, message: message(for: failure), severity: .error)
        }
    }

    private func message(for failure: Failure) -> String {
        switch failure {
        case .unsupportedItem, .loadFailed, .decodeFailed: strings.loadFailedMessage
        case .saveFailed: strings.saveFailedMessage
        case .hostUnavailable: strings.hostUnavailableMessage
        }
    }

    /// The uniform type identifier ImageIO reads from the bytes' header, or "unknown".
    private static func typeIdentifier(of data: Data) -> String {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil), let type = CGImageSourceGetType(source) else { return "unknown" }
        return type as String
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
        guard let provider = results.first?.itemProvider else {
            picker.dismiss(animated: true)
            onCancel?()
            return
        }
        guard provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) else {
            picker.dismiss(animated: true)
            report(.unsupportedItem)
            return
        }
        // The crop editor waits for this dismissal to complete: presenting while the picker
        // is still on its way out is refused by UIKit, and the flow would end silently.
        isPickerDismissing = true
        picker.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            isPickerDismissing = false
            presentCropIfReady()
        }
        handleLoad(from: provider)
    }

    /// Reads the raw bytes of `provider`'s image (never `loadObject(ofClass: UIImage.self)`:
    /// the decode strips the metadata), then decodes them. The load is cancelled with the flow,
    /// and a load from a cancelled flow that completes anyway is ignored.
    func handleLoad(from provider: NSItemProvider) {
        loadProgress?.cancel()
        let generation = flowGeneration
        loadProgress = provider.loadDataRepresentation(for: UTType.image) { [weak self] data, error in
            Task { @MainActor in
                guard let self, generation == self.flowGeneration else { return }
                self.loadProgress = nil
                if let data {
                    self.handlePicked(data: data)
                } else if let error {
                    self.report(.loadFailed(error))
                } else {
                    self.report(.unsupportedItem)
                }
            }
        }
    }
}
