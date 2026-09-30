//
//  PickCropExample.swift
//  LumiKitExample
//
//  Pick & Crop: Pick, square-crop, and store; the single photo viewer.
//

import LumiKitCore
import LumiKitPhoto
import LumiKitUI
import PhotosUI
import SnapKit
import UIKit
import UniformTypeIdentifiers

// MARK: - Pick & Crop

final class PickCropDetailViewController: DetailViewController {
    // Both flows reference their delegates weakly through these objects,
    // so the host retains them for the duration of the interaction.
    private var pickCropCoordinator: LMKPhotoPickCropCoordinator?
    private var photoViewer: LMKSinglePhotoViewer?

    private var storedImage: UIImage?
    private var storedMetadata: LMKPhotoMetadata?
    private var storedIdentifier: String?

    private lazy var preview: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = LMKCornerRadius.medium
        imageView.backgroundColor = LMKColor.backgroundSecondary
        imageView.snp.makeConstraints { $0.height.equalTo(200) }
        return imageView
    }()

    private lazy var identifierLabel = UILabel.lmk_make(.caption, text: "No photo stored yet.")

    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("LMKPhotoPickCropCoordinator")
        stack.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "Pick, square-crop, and store a single photo using a permission-free PHPicker. "
                + "The picked bytes are read once, so the capture date and location reach save as LMKPhotoMetadata. "
                + "Storage is an async closure; here it keeps the image in memory and returns a UUID."
        ))

        let pickButton = LMKButton(title: "Pick & Crop Photo", style: .filled(.primary), target: self, action: #selector(startPickCrop))
        stack.addArrangedSubview(pickButton)

        stack.addArrangedSubview(preview)
        stack.addArrangedSubview(identifierLabel)

        addDivider()
        addSectionHeader("LMKSinglePhotoViewer")
        stack.addArrangedSubview(UILabel.lmk_make(
            .caption,
            text: "Presents one image full-screen in LMKPhotoBrowserViewController: data source and delegate in a single retained object, "
                + "zooming out of the preview. The action button is backed by the optional onAction callback."
        ))

        let viewButton = LMKButton(title: "View Full Screen", style: .outlined(.primary), target: self, action: #selector(viewFullScreen))
        stack.addArrangedSubview(viewButton)
    }

    @objc private func startPickCrop() {
        let coordinator = LMKPhotoPickCropCoordinator(
            host: self,
            maximumPixelSize: 2048,
            save: { [weak self] image, metadata in
                self?.storedImage = image
                self?.storedMetadata = metadata
                return UUID().uuidString
            },
            onSaved: { [weak self] identifier in
                guard let self else { return }
                storedIdentifier = identifier
                preview.image = storedImage
                let taken = storedMetadata?.date.map { LMKDateFormat.string($0) } ?? "no capture date"
                identifierLabel.text = "Stored as \(identifier) (\(taken))"
                LMKToast.show(.success, "Photo stored", in: self)
            },
            onCancel: { [weak self] in
                guard let self else { return }
                LMKToast.show(.info, "Pick cancelled", in: self)
            },
            onFailure: { [weak self] failure in
                guard let self else { return }
                LMKToast.show(.error, "Could not store photo: \(failure)", in: self)
            }
        )
        pickCropCoordinator = coordinator
        coordinator.start()
    }

    @objc private func viewFullScreen() {
        guard let storedImage else {
            LMKToast.show(.info, "Pick a photo first", in: self)
            return
        }
        let viewer = LMKSinglePhotoViewer(
            image: storedImage,
            subtitle: storedIdentifier,
            onAction: { [weak self] in
                guard let self else { return }
                LMKToast.show(.info, "Action button tapped", in: presentedViewController ?? self)
            }
        )
        viewer.zoomSourceView = { [weak self] in self?.preview }
        photoViewer = viewer
        viewer.present(from: self)
    }
}
