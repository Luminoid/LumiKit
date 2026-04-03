//
//  MediaExamples.swift
//  LumiKitExample
//
//  Photo grid, photo browser, photo crop, and QR code examples.
//

import LumiKitUI
import SnapKit
import UIKit

// MARK: - Photo Grid

final class PhotoGridDetailViewController: UIViewController, LMKPhotoGridDataSource, LMKPhotoGridDelegate {
    private var sampleImages: [UIImage] = []
    private var sampleDates: [Date] = []
    private var gridVC: LMKPhotoGridViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = LMKColor.backgroundPrimary
        generateSampleData()
        setupGrid()
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

    var numberOfPhotos: Int { sampleImages.count }

    func photoGridImage(at index: Int) -> UIImage? {
        guard index >= 0, index < sampleImages.count else { return nil }
        return sampleImages[index]
    }

    func photoGridDate(at index: Int) -> Date? {
        guard index >= 0, index < sampleDates.count else { return nil }
        return sampleDates[index]
    }

    // MARK: - LMKPhotoGridDelegate

    func photoGrid(_ grid: LMKPhotoGridViewController, didRequestActionForPhotoAt index: Int) {
        LMKToast.showInfo(message: "Action for photo \(index + 1)", on: self)
    }
}

// MARK: - Photo Browser

final class PhotoBrowserDetailViewController: DetailViewController, LMKPhotoBrowserDataSource, LMKPhotoBrowserDelegate {
    private var sampleImages: [UIImage] = []

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
        presentBrowser(at: view.tag)
    }

    @objc private func openBrowser() {
        presentBrowser(at: 0)
    }

    private func presentBrowser(at index: Int) {
        let browser = LMKPhotoBrowserViewController(initialIndex: index)
        browser.dataSource = self
        browser.delegate = self
        browser.modalPresentationStyle = .overFullScreen
        present(browser, animated: true)
    }

    // MARK: - LMKPhotoBrowserDataSource

    var numberOfPhotos: Int { sampleImages.count }

    func photo(at index: Int) -> UIImage? {
        guard index >= 0, index < sampleImages.count else { return nil }
        return sampleImages[index]
    }

    func photoDate(at index: Int) -> Date? {
        Calendar.current.date(byAdding: .day, value: -index, to: Date())
    }

    func photoSubtitle(at index: Int) -> String? {
        nil
    }

    // MARK: - LMKPhotoBrowserDelegate

    func photoBrowser(_ browser: LMKPhotoBrowserViewController, didRequestActionAt index: Int) {
        LMKToast.showInfo(message: "Action requested for photo \(index + 1)", on: browser)
    }

    func photoBrowserDidDismiss(_ browser: LMKPhotoBrowserViewController) {}
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
