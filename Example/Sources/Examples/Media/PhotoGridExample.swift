//
//  PhotoGridExample.swift
//  LumiKitExample
//
//  Photo Grid: Pinch columns, drag to select, sort, fit or fill.
//

import LumiKitCore
import LumiKitPhoto
import LumiKitUI
import PhotosUI
import SnapKit
import UIKit
import UniformTypeIdentifiers

// MARK: - Photo Grid

final class PhotoGridDetailViewController: UIViewController, LMKPhotoGridDataSource, LMKPhotoGridDelegate {
    /// JPEG bytes rather than decoded images: the grid data source is async,
    /// and this page demonstrates the intended conformance shape for disk- or
    /// network-backed sources — decode off the main actor per request and
    /// return a ready-to-display image.
    private var sampleImageData: [Data] = []
    private var sampleDates: [Date] = []
    private var gridVC: LMKPhotoGridViewController?
    private var showsEmptyState = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = LMKColor.backgroundPrimary
        generateSampleData()
        setupGrid()
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Empty", style: .plain, target: self, action: #selector(toggleEmptyState)),
            UIBarButtonItem(title: "Select", style: .plain, target: self, action: #selector(toggleSelection)),
        ]
    }

    @objc private func toggleEmptyState() {
        showsEmptyState.toggle()
        navigationItem.rightBarButtonItems?.first?.title = showsEmptyState ? "Populate" : "Empty"
        gridVC?.reloadData()
    }

    /// Multi-selection: taps toggle cells instead of opening the browser.
    @objc private func toggleSelection() {
        guard let gridVC else { return }
        gridVC.allowsMultipleSelection.toggle()
        navigationItem.rightBarButtonItems?.last?.title = gridVC.allowsMultipleSelection ? "Done" : "Select"
        title = gridVC.allowsMultipleSelection ? "0 selected" : nil
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
            if let image = LMKImage.makeSymbolImage(
                symbol, size: size,
                symbolPointSize: pointSize, tintColor: color,
                backgroundColor: color.withAlphaComponent(0.15)
            ), let data = image.jpegData(compressionQuality: 0.9) {
                sampleImageData.append(data)
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
        grid.onSelectionChange = { [weak self] selection in
            self?.title = "\(selection.count) selected"
        }
        grid.contextMenuProvider = { [weak self] index in
            UIMenu(children: [
                UIAction(title: "Show index", image: UIImage(systemName: "number")) { _ in
                    guard let self else { return }
                    LMKToast.show(.info, "Data source index \(index)", in: self)
                },
            ])
        }
        gridVC = grid

        addChild(grid)
        view.addSubview(grid.view)
        grid.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        grid.didMove(toParent: self)
    }

    // MARK: - LMKPhotoGridDataSource

    var numberOfPhotos: Int { showsEmptyState ? 0 : sampleImageData.count }

    /// The reference async conformance: hop off the main actor, decode, and
    /// hand back a ready-to-display image. The grid shows its neutral
    /// placeholder meanwhile, and its generation token drops results that
    /// land after the cell was recycled — no reuse bookkeeping needed here.
    func photoGridImage(at index: Int) async -> UIImage? {
        guard index >= 0, index < sampleImageData.count else { return nil }
        let data = sampleImageData[index]
        return await Task.detached { () -> UIImage? in
            guard let image = UIImage(data: data) else { return nil }
            return image.preparingForDisplay() ?? image
        }.value
    }

    func photoGridDate(at index: Int) -> Date? {
        guard index >= 0, index < sampleDates.count else { return nil }
        return sampleDates[index]
    }

    /// Demo: mark every 5th cell as a Live Photo so the LIVE badge overlay is
    /// visible in the example. Real hosts would check whichever paired-file
    /// metadata they track alongside the still image.
    func photoGridIsLivePhoto(at index: Int) -> Bool {
        index >= 0 && index < sampleImageData.count && index.isMultiple(of: 5)
    }

    // MARK: - LMKPhotoGridDelegate

    func photoGrid(_ grid: LMKPhotoGridViewController, didRequestActionForPhotoAt index: Int) {
        LMKToast.show(.info, "Action for photo \(index + 1)", in: self)
    }
}
