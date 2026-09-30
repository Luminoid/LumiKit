//
//  PhotoBrowserExample.swift
//  LumiKitExample
//
//  Photo Browser: Paging, zoom, swipe to dismiss, Live Photos.
//

import LumiKitCore
import LumiKitPhoto
import LumiKitUI
import PhotosUI
import SnapKit
import UIKit
import UniformTypeIdentifiers

// MARK: - Photo Browser

final class PhotoBrowserDetailViewController: DetailViewController, LMKPhotoBrowserDataSource, LMKPhotoBrowserDelegate {
    private var sampleImages: [UIImage] = []
    private var previewImageViews: [UIImageView] = []
    private let styledSwitch: LMKSwitch = {
        let toggle = LMKSwitch()
        toggle.accessibilityLabel = "Custom browser style"
        return toggle
    }()

    // Live Photo demo state. When `livePhotoMode` is true, the data source
    // serves just the single picked Live Photo instead of the sample grid.
    private var pickedLivePhoto: PHLivePhoto?
    private var pickedStill: UIImage?
    private var livePhotoMode = false
    private var didOpenLaunchLivePhoto = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Generate sample images using SF Symbols
        let symbols = ["star.fill", "camera.fill", "sun.max.fill", "drop.fill", "flame.fill"]
        let colors: [UIColor] = [LMKColor.success, LMKColor.primary, LMKColor.warning, LMKColor.info, LMKColor.error]

        for (symbol, color) in zip(symbols, colors) {
            if let image = LMKImage.makeSymbolImage(
                symbol, size: CGSize(width: 300, height: 300),
                symbolPointSize: 80, tintColor: color,
                backgroundColor: color.withAlphaComponent(0.2)
            ) {
                sampleImages.append(image)
            }
        }

        addSectionHeader("Photo Browser")
        stack.addArrangedSubview(UILabel.lmk_make(
            .body,
            text: "Full-screen photo viewer with swipe navigation, pinch-to-zoom, HDR rendering, and swipe-to-dismiss. "
                + "Tapping a thumbnail zooms the photo out of it, and the dismiss zooms back to the current photo; the page behind holds still."
        ))

        let previewRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        previewRow.distribution = .fillEqually
        for (index, image) in sampleImages.enumerated() {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = LMKCornerRadius.small
            imageView.isUserInteractionEnabled = true
            imageView.tag = index
            imageView.snp.makeConstraints { $0.height.equalTo(80) }

            let tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:)))
            imageView.addGestureRecognizer(tap)
            previewRow.addArrangedSubview(imageView)
            previewImageViews.append(imageView)
        }
        stack.addArrangedSubview(previewRow)

        addDivider()
        let openButton = LMKButton(title: "Open Photo Browser", style: .filled(.primary), target: self, action: #selector(openBrowser))
        stack.addArrangedSubview(openButton)
        let styleRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.medium, alignment: .center, arrangedSubviews: [
            UILabel.lmk_make(.body, text: "Custom style (warm chrome, SDR, no orientation lock)"), UIView(), styledSwitch,
        ])
        stack.addArrangedSubview(styleRow)

        addDivider()
        addSectionHeader("Live Photo")
        stack.addArrangedSubview(UILabel.lmk_make(.body, text: "Pick a Live Photo from your library, then long-press anywhere in the browser to play the paired video."))
        let pickLiveButton = LMKButton(title: "Pick a Live Photo", style: .filled(.primary),
                                       target: self,
                                       action: #selector(pickLivePhoto))
        stack.addArrangedSubview(pickLiveButton)

        addDivider()
        addSectionHeader("Gestures")
        let features = [
            "Swipe left or right to page",
            "Double-tap to zoom on the tapped point, again to zoom out",
            "Pinch to zoom around your fingers",
            "Zoomed, drag to pan; drag past an edge to page",
            "Drag up or down to dismiss: the photo follows and the page behind shows through",
            "Tap to hide or show the controls",
            "Long-press anywhere to play a Live Photo",
            "Arrow keys page and Escape closes on iPad and Mac",
        ]
        for feature in features {
            let label = UILabel.lmk_make(.caption, text: "\u{2022} \(feature)")
            stack.addArrangedSubview(label)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        openLaunchLivePhotoIfNeeded()
    }

    /// `-lmk-live-photo <still> <video>`: builds the Live Photo from the two files and opens it,
    /// so the demo runs on a simulator whose library has no Live Photos.
    private func openLaunchLivePhotoIfNeeded() {
        let files = ExampleLaunchOptions.current.livePhotoFiles
        guard files.count == 2, !didOpenLaunchLivePhoto else { return }
        didOpenLaunchLivePhoto = true
        let urls = files.map { URL(fileURLWithPath: $0) }
        let still = UIImage(contentsOfFile: files[0])
        PHLivePhoto.request(withResourceFileURLs: urls, placeholderImage: still, targetSize: .zero, contentMode: .aspectFit) { [weak self] livePhoto, info in
            // The first answer may be a degraded placeholder; the full one follows.
            guard let self, let livePhoto, (info[PHLivePhotoInfoIsDegradedKey] as? Bool) != true, !livePhotoMode else { return }
            pickedLivePhoto = livePhoto
            pickedStill = still
            livePhotoMode = true
            presentBrowser(at: 0)
        }
    }

    @objc private func imageTapped(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view else { return }
        livePhotoMode = false
        presentBrowser(at: view.tag)
    }

    @objc private func openBrowser() {
        livePhotoMode = false
        presentBrowser(at: 0)
    }

    @objc private func pickLivePhoto() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .livePhotos
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func presentBrowser(at index: Int) {
        let browser = LMKPhotoBrowserViewController(initialIndex: index)
        browser.dataSource = self
        browser.delegate = self
        if styledSwitch.isOn {
            browser.style = LMKPhotoBrowserViewController.Style(chromeTint: LMKColor.warning, prefersHDR: false, locksOrientation: false)
        }
        if !livePhotoMode {
            browser.zoomSourceView = { [weak self] index in self?.previewImageViews[lmk_safe: index] }
        }
        browser.onDismiss = { [weak self] in
            guard let self else { return }
            LMKToast.show(.info, "Browser dismissed", in: self)
        }
        present(browser, animated: true)
    }

    // MARK: - LMKPhotoBrowserDataSource

    var numberOfPhotos: Int {
        livePhotoMode ? 1 : sampleImages.count
    }

    /// These images are generated up front and held decoded in memory, so this
    /// async source just returns immediately — the other valid conformance
    /// shape (see the photo grid page for the off-main decode pattern).
    func photo(at index: Int) async -> UIImage? {
        if livePhotoMode {
            return pickedStill
        }
        guard index >= 0, index < sampleImages.count else { return nil }
        return sampleImages[index]
    }

    func photoDate(at index: Int) -> Date? {
        Calendar.current.date(byAdding: .day, value: -index, to: Date())
    }

    func photoSubtitle(at index: Int) -> String? {
        livePhotoMode ? "Long-press to play" : nil
    }

    /// Shows the LIVE badge at once; the browser asks for the Live Photo either way.
    func photoIsLivePhoto(at _: Int) -> Bool {
        livePhotoMode
    }

    func photoLivePhoto(at _: Int) async -> PHLivePhoto? {
        livePhotoMode ? pickedLivePhoto : nil
    }

    // MARK: - LMKPhotoBrowserDelegate

    func photoBrowser(_ browser: LMKPhotoBrowserViewController, didRequestActionAt index: Int) {
        LMKToast.show(.info, "Action requested for photo \(index + 1)", in: browser)
    }

    func photoBrowserDidDismiss(_ browser: LMKPhotoBrowserViewController) {}
}

// MARK: - PHPickerViewControllerDelegate

extension PhotoBrowserDetailViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let result = results.first,
              result.itemProvider.canLoadObject(ofClass: PHLivePhoto.self)
        else {
            LMKToast.show(.info, "Not a Live Photo. Try another.", in: self)
            return
        }

        Task { @MainActor [weak self] in
            guard let self else { return }
            let livePhoto = await Self.loadPickedLivePhoto(from: result.itemProvider)
            let still = await Self.loadPickedStill(from: result.itemProvider)
            guard let livePhoto, let still else {
                LMKToast.show(.info, "Couldn't load the Live Photo", in: self)
                return
            }
            pickedLivePhoto = livePhoto
            pickedStill = still
            livePhotoMode = true
            presentBrowser(at: 0)
        }
    }

    /// `PHLivePhoto` conforms to `NSItemProviderReading`, so the picker can vend
    /// it directly via `loadObject(ofClass:)`. The completion may fire multiple
    /// times with progressive loads; we resolve once the continuation permits.
    private static func loadPickedLivePhoto(
        from provider: sending NSItemProvider
    ) async -> PHLivePhoto? {
        await withCheckedContinuation { continuation in
            _ = provider.loadObject(ofClass: PHLivePhoto.self) { obj, _ in
                continuation.resume(returning: obj as? PHLivePhoto)
            }
        }
    }

    /// Still image extracted from the same item provider so the browser can
    /// show it immediately while the live photo loads.
    private static func loadPickedStill(
        from provider: sending NSItemProvider
    ) async -> UIImage? {
        let data: Data? = await withCheckedContinuation { continuation in
            provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                continuation.resume(returning: data)
            }
        }
        guard let data else { return nil }
        return UIImage(data: data)
    }
}
