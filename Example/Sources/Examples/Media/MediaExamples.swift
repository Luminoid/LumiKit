//
//  MediaExamples.swift
//  LumiKitExample
//
//  Photo grid, photo browser, photo crop, and QR code examples.
//

import LumiKitUI
import PhotosUI
import SnapKit
import UIKit
import UniformTypeIdentifiers

// MARK: - Photo Grid

final class PhotoGridDetailViewController: UIViewController, LMKPhotoGridDataSource, LMKPhotoGridDelegate {
    private var sampleImages: [UIImage] = []
    private var sampleDates: [Date] = []
    private var gridVC: LMKPhotoGridViewController?
    private var showsEmptyState = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = LMKColor.backgroundPrimary
        generateSampleData()
        setupGrid()
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Empty",
            style: .plain,
            target: self,
            action: #selector(toggleEmptyState)
        )
    }

    @objc private func toggleEmptyState() {
        showsEmptyState.toggle()
        navigationItem.rightBarButtonItem?.title = showsEmptyState ? "Populate" : "Empty"
        gridVC?.reloadData()
    }

    private static let sampleSymbols = [
        "star.fill", "camera.fill", "sun.max.fill", "drop.fill", "flame.fill",
        "leaf.fill", "heart.fill", "bolt.fill", "moon.fill", "cloud.fill",
        "snowflake", "wind", "tornado", "sparkles", "wand.and.stars",
        "paintbrush.fill", "eyedropper.full", "scissors", "pencil", "trash.fill",
        "globe", "map.fill", "location.fill", "flag.fill", "pin.fill",
        "bell.fill", "tag.fill", "bookmark.fill", "envelope.fill", "phone.fill",
        "video.fill", "mic.fill", "speaker.wave.3.fill", "music.note",
        "play.fill", "pause.fill", "stop.fill", "forward.fill", "backward.fill",
        "shuffle", "repeat", "airplayaudio", "antenna.radiowaves.left.and.right",
        "wifi", "network", "lock.fill", "key.fill", "shield.fill",
        "person.fill", "person.2.fill", "person.3.fill",
    ]

    private static let sampleColors: [UIColor] = [
        .systemRed, .systemOrange, .systemYellow, .systemGreen, .systemMint,
        .systemTeal, .systemCyan, .systemBlue, .systemIndigo, .systemPurple,
        .systemPink, .systemBrown, .systemGray, .systemGray2, .systemGray3,
    ]

    private static let sampleAspectRatios: [CGSize] = [
        CGSize(width: 200, height: 200),   // 1:1
        CGSize(width: 200, height: 150),   // 4:3 landscape
        CGSize(width: 150, height: 200),   // 3:4 portrait
        CGSize(width: 200, height: 112),   // 16:9 landscape
        CGSize(width: 112, height: 200),   // 9:16 portrait
        CGSize(width: 200, height: 133),   // 3:2 landscape
        CGSize(width: 133, height: 200),   // 2:3 portrait
        CGSize(width: 200, height: 260),   // tall portrait
        CGSize(width: 260, height: 200),   // wide landscape
    ]

    private func generateSampleData() {
        let symbols = Self.sampleSymbols
        let colors = Self.sampleColors
        let ratios = Self.sampleAspectRatios
        let calendar = Calendar.current
        let photoCount = 300

        for i in 0 ..< photoCount {
            let symbol = symbols[i % symbols.count]
            let color = colors[i % colors.count]
            let size = ratios[i % ratios.count]
            let pointSize = min(size.width, size.height) * 0.3
            if let image = LMKImageUtil.makeSymbolImage(
                symbol, size: size,
                symbolPointSize: pointSize, tintColor: color,
                backgroundColor: color.withAlphaComponent(0.15)
            ) {
                sampleImages.append(image)
                // Spread dates across the last 2 years with some randomness
                let dayOffset = -(i * 2 + (i * 7) % 5)
                let date = calendar.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
                sampleDates.append(date)
            }
        }
    }

    private func setupGrid() {
        let grid = LMKPhotoGridViewController(columnCount: 3)
        grid.dataSource = self
        grid.delegate = self
        gridVC = grid

        addChild(grid)
        view.addSubview(grid.view)
        grid.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        grid.didMove(toParent: self)
    }

    // MARK: - LMKPhotoGridDataSource

    var numberOfPhotos: Int { showsEmptyState ? 0 : sampleImages.count }

    func photoGridImage(at index: Int) -> UIImage? {
        guard index >= 0, index < sampleImages.count else { return nil }
        return sampleImages[index]
    }

    func photoGridDate(at index: Int) -> Date? {
        guard index >= 0, index < sampleDates.count else { return nil }
        return sampleDates[index]
    }

    /// Demo: mark every 5th cell as a Live Photo so the LIVE badge overlay is
    /// visible in the example. Real hosts would check whichever paired-file
    /// metadata they track alongside the still image.
    func photoGridIsLivePhoto(at index: Int) -> Bool {
        index >= 0 && index < sampleImages.count && index.isMultiple(of: 5)
    }

    // MARK: - LMKPhotoGridDelegate

    func photoGrid(_ grid: LMKPhotoGridViewController, didRequestActionForPhotoAt index: Int) {
        LMKToast.showInfo(message: "Action for photo \(index + 1)", on: self)
    }
}

// MARK: - Photo Browser

final class PhotoBrowserDetailViewController: DetailViewController, LMKPhotoBrowserDataSource, LMKPhotoBrowserDelegate {
    private var sampleImages: [UIImage] = []

    // Live Photo demo state. When `livePhotoMode` is true, the data source
    // serves just the single picked Live Photo instead of the sample grid.
    private var pickedLivePhoto: PHLivePhoto?
    private var pickedStill: UIImage?
    private var livePhotoMode = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Generate sample images using SF Symbols
        let symbols = ["star.fill", "camera.fill", "sun.max.fill", "drop.fill", "flame.fill"]
        let colors: [UIColor] = [LMKColor.success, LMKColor.primary, LMKColor.warning, LMKColor.info, LMKColor.error]

        for (symbol, color) in zip(symbols, colors) {
            if let image = LMKImageUtil.makeSymbolImage(
                symbol, size: CGSize(width: 300, height: 300),
                symbolPointSize: 80, tintColor: color,
                backgroundColor: color.withAlphaComponent(0.2)
            ) {
                sampleImages.append(image)
            }
        }

        addSectionHeader("Photo Browser")
        stack.addArrangedSubview(LMKLabelFactory.body(text: "Full-screen photo viewer with swipe navigation, pinch-to-zoom, and swipe-to-dismiss."))

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
        }
        stack.addArrangedSubview(previewRow)

        addDivider()
        let openButton = LMKButtonFactory.filled(role: .primary, title: "Open Photo Browser", target: self, action: #selector(openBrowser))
        stack.addArrangedSubview(openButton)

        addDivider()
        addSectionHeader("Live Photo")
        stack.addArrangedSubview(LMKLabelFactory.body(
            text: "Pick a Live Photo from your library, then long-press inside the browser to play the paired video."
        ))
        let pickLiveButton = LMKButtonFactory.filled(
            role: .primary,
            title: "Pick a Live Photo",
            target: self,
            action: #selector(pickLivePhoto)
        )
        stack.addArrangedSubview(pickLiveButton)

        addDivider()
        addSectionHeader("Features")
        let features = [
            "Swipe left/right to navigate",
            "Double-tap or pinch to zoom",
            "Swipe down to dismiss",
            "Page indicators and photo counter",
            "Date label overlay",
            "Keyboard navigation on Mac Catalyst",
        ]
        for feature in features {
            let label = LMKLabelFactory.caption(text: "\u{2022} \(feature)")
            stack.addArrangedSubview(label)
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
        browser.modalPresentationStyle = .overFullScreen
        present(browser, animated: true)
    }

    // MARK: - LMKPhotoBrowserDataSource

    var numberOfPhotos: Int {
        livePhotoMode ? 1 : sampleImages.count
    }

    func photo(at index: Int) -> UIImage? {
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

    func photoLivePhoto(at _: Int) async -> PHLivePhoto? {
        livePhotoMode ? pickedLivePhoto : nil
    }

    // MARK: - LMKPhotoBrowserDelegate

    func photoBrowser(_ browser: LMKPhotoBrowserViewController, didRequestActionAt index: Int) {
        LMKToast.showInfo(message: "Action requested for photo \(index + 1)", on: browser)
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
            LMKToast.showInfo(message: "Not a Live Photo — try another", on: self)
            return
        }

        Task { @MainActor [weak self] in
            guard let self else { return }
            let livePhoto = await Self.loadPickedLivePhoto(from: result.itemProvider)
            let still = await Self.loadPickedStill(from: result.itemProvider)
            guard let livePhoto, let still else {
                LMKToast.showInfo(message: "Couldn't load the Live Photo", on: self)
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

// MARK: - Photo Crop

final class PhotoCropDetailViewController: DetailViewController, LMKPhotoCropDelegate {
    private var sampleImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()

        sampleImage = createSampleImage()

        addSectionHeader("Photo Crop")
        stack.addArrangedSubview(LMKLabelFactory.body(text: "Resizable crop frame with aspect ratio presets, pinch-to-zoom, and rule-of-thirds grid."))

        if let sampleImage {
            let preview = UIImageView(image: sampleImage)
            preview.contentMode = .scaleAspectFill
            preview.clipsToBounds = true
            preview.layer.cornerRadius = LMKCornerRadius.medium
            preview.snp.makeConstraints { $0.height.equalTo(200) }
            stack.addArrangedSubview(preview)
        }

        let cropButton = LMKButtonFactory.filled(role: .primary, title: "Open Photo Crop", target: self, action: #selector(openCrop))
        stack.addArrangedSubview(cropButton)

        addDivider()
        addSectionHeader("Aspect Ratios")
        let ratioRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        ratioRow.distribution = .fillEqually
        for ratio in LMKCropAspectRatio.allCases {
            let chip = LMKChipView(text: ratio.displayName, style: .outlined)
            ratioRow.addArrangedSubview(chip)
        }
        stack.addArrangedSubview(ratioRow)

        addDivider()
        addSectionHeader("Features")
        let features = [
            "Drag corners and edges to resize",
            "Pinch to zoom the image",
            "Aspect ratio presets (1:1, 4:3, 3:2, etc.)",
            "Free-form cropping",
            "Rule-of-thirds grid overlay",
        ]
        for feature in features {
            let label = LMKLabelFactory.caption(text: "\u{2022} \(feature)")
            stack.addArrangedSubview(label)
        }
    }

    @objc private func openCrop() {
        guard let sampleImage else { return }
        let cropVC = LMKPhotoCropViewController(image: sampleImage)
        cropVC.delegate = self
        cropVC.modalPresentationStyle = .overFullScreen
        present(cropVC, animated: true)
    }

    private func createSampleImage() -> UIImage? {
        let size = CGSize(width: 600, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let colors = [LMKColor.primary.cgColor, LMKColor.secondary.cgColor]
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1]) else { return }

            ctx.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])

            let config = UIImage.SymbolConfiguration(pointSize: 80, weight: .regular)
            if let symbol = UIImage(systemName: "leaf.fill", withConfiguration: config) {
                let symbolSize = symbol.size
                let origin = CGPoint(
                    x: (size.width - symbolSize.width) / 2,
                    y: (size.height - symbolSize.height) / 2
                )
                symbol.withTintColor(.white.withAlphaComponent(0.8), renderingMode: .alwaysOriginal)
                    .draw(at: origin)
            }
        }
    }

    // MARK: - LMKPhotoCropDelegate

    func photoCropViewController(_ controller: LMKPhotoCropViewController, didCropImage image: UIImage) {
        controller.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            LMKToast.showSuccess(message: "Image cropped (\(Int(image.size.width))\u{00D7}\(Int(image.size.height)))", on: self)
        }
    }

    func photoCropViewControllerDidCancel(_ controller: LMKPhotoCropViewController) {
        controller.dismiss(animated: true)
    }
}

// MARK: - QR Code

final class QRCodeDetailViewController: DetailViewController {
    private let imageView = UIImageView()
    private let textField = UITextField()

    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionHeader("Generator")
        textField.placeholder = "Enter text or URL..."
        textField.text = "https://github.com/Luminoid/LumiKit"
        textField.borderStyle = .roundedRect
        textField.font = LMKTypography.body
        textField.clearButtonMode = .whileEditing
        textField.returnKeyType = .done
        textField.addTarget(self, action: #selector(generateQR), for: .editingChanged)
        textField.addTarget(self, action: #selector(dismissKeyboard), for: .editingDidEndOnExit)
        stack.addArrangedSubview(textField)

        let generateButton = LMKButtonFactory.filled(role: .primary, title: "Generate QR Code", target: self, action: #selector(generateQR))
        stack.addArrangedSubview(generateButton)

        addDivider()
        addSectionHeader("Result")

        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = LMKColor.backgroundSecondary
        imageView.layer.cornerRadius = LMKCornerRadius.medium
        imageView.clipsToBounds = true
        imageView.snp.makeConstraints { $0.height.equalTo(200) }
        stack.addArrangedSubview(imageView)

        generateQR()

        addDivider()
        addSectionHeader("Correction Levels")
        let levels: [(String, LMKQRCodeGenerator.CorrectionLevel)] = [
            ("Low (~7%)", .low),
            ("Medium (~15%)", .medium),
            ("Quartile (~25%)", .quartile),
            ("High (~30%)", .high),
        ]
        let levelRow = UIStackView(lmk_axis: .horizontal, spacing: LMKSpacing.small)
        levelRow.distribution = .fillEqually
        for (name, level) in levels {
            let col = UIStackView(lmk_axis: .vertical, spacing: LMKSpacing.xs)
            col.alignment = .center

            let qrImage = LMKQRCodeGenerator.generateQRCode(from: "LumiKit", size: 80, correctionLevel: level)
            let qrView = UIImageView(image: qrImage)
            qrView.contentMode = .scaleAspectFit
            qrView.snp.makeConstraints { $0.width.height.equalTo(80) }

            let label = LMKLabelFactory.small(text: name)
            label.textAlignment = .center

            col.addArrangedSubview(qrView)
            col.addArrangedSubview(label)
            levelRow.addArrangedSubview(col)
        }
        stack.addArrangedSubview(levelRow)
    }

    @objc private func generateQR() {
        let text = textField.text ?? ""
        imageView.image = LMKQRCodeGenerator.generateQRCode(from: text, size: 200)
    }

    @objc private func dismissKeyboard() {
        textField.resignFirstResponder()
    }
}

// MARK: - Share Preview

final class ShareDetailViewController: DetailViewController, LMKSharePreviewDelegate {
    private var sampleImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()

        sampleImage = createSampleImage()

        addSectionHeader("LMKSharePreviewViewController")
        stack.addArrangedSubview(LMKLabelFactory.body(text: "Image preview sheet with Share and Save to Photos actions. Uses LMKShareService internally."))

        if let sampleImage {
            let preview = UIImageView(image: sampleImage)
            preview.contentMode = .scaleAspectFit
            preview.clipsToBounds = true
            preview.layer.cornerRadius = LMKCornerRadius.medium
            preview.snp.makeConstraints { $0.height.equalTo(200) }
            stack.addArrangedSubview(preview)
        }

        let previewButton = LMKButtonFactory.filled(role: .primary, title: "Show Share Preview", target: self, action: #selector(showSharePreview))
        stack.addArrangedSubview(previewButton)

        addDivider()
        addSectionHeader("LMKShareService")
        stack.addArrangedSubview(LMKLabelFactory.caption(text: "Direct share sheet for images and files with iPad popover support."))

        let shareImageButton = LMKButtonFactory.outlined(role: .secondary, title: "Share Image Directly", target: self, action: #selector(shareImageDirectly))
        stack.addArrangedSubview(shareImageButton)
    }

    @objc private func showSharePreview() {
        guard let sampleImage else { return }
        let previewVC = LMKSharePreviewViewController(image: sampleImage)
        previewVC.delegate = self
        present(previewVC, animated: true)
    }

    @objc private func shareImageDirectly() {
        guard let sampleImage else { return }
        LMKShareService.shareImage(sampleImage, from: self) { [weak self] result in
            guard let self else { return }
            switch result {
            case let .completed(activityType):
                LMKToast.showSuccess(message: "Shared via \(activityType?.rawValue ?? "unknown")", on: self)
            case .failed:
                LMKToast.showError(message: "Share failed", on: self)
            case .cancelled:
                break
            }
        }
    }

    private func createSampleImage() -> UIImage? {
        let size = CGSize(width: 400, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let colors = [LMKColor.info.cgColor, LMKColor.primary.cgColor]
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1]) else { return }
            ctx.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])

            let config = UIImage.SymbolConfiguration(pointSize: 64, weight: .regular)
            if let symbol = UIImage(systemName: "square.and.arrow.up", withConfiguration: config) {
                let symbolSize = symbol.size
                let origin = CGPoint(x: (size.width - symbolSize.width) / 2, y: (size.height - symbolSize.height) / 2)
                symbol.withTintColor(.white.withAlphaComponent(0.8), renderingMode: .alwaysOriginal).draw(at: origin)
            }
        }
    }

    // MARK: - LMKSharePreviewDelegate

    func sharePreview(_ preview: LMKSharePreviewViewController, didShareWith activityType: UIActivity.ActivityType?) {
        LMKToast.showSuccess(message: "Shared!", on: self)
    }

    func sharePreview(_ preview: LMKSharePreviewViewController, didFailToShare error: any Error) {
        LMKToast.showError(message: "Share failed", on: self)
    }

    func sharePreviewDidSave(_ preview: LMKSharePreviewViewController) {
        LMKToast.showSuccess(message: "Saved to Photos!", on: self)
    }

    func sharePreview(_ preview: LMKSharePreviewViewController, didFailToSave error: any Error) {
        LMKToast.showError(message: "Failed to save image", on: self)
    }

    func sharePreviewDidDismiss(_ preview: LMKSharePreviewViewController) {}
}
