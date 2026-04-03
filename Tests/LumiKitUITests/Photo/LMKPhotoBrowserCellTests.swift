//
//  LMKPhotoBrowserCellTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKPhotoBrowserCellTests {
    // MARK: - Initialization

    @Test
    func `Cell has correct identifier`() {
        #expect(LMKPhotoBrowserCell.identifier == "LMKPhotoBrowserCell")
    }

    @Test
    func `Cell initializes with frame`() {
        let cell = LMKPhotoBrowserCell(frame: CGRect(x: 0, y: 0, width: 375, height: 667))

        #expect(cell.frame.width == 375)
        #expect(cell.frame.height == 667)
    }

    // MARK: - Image Configuration

    @Test
    func `configure sets image`() {
        let cell = LMKPhotoBrowserCell(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        let testImage = UIImage.lmk_solidColor(.red, size: CGSize(width: 100, height: 100))

        cell.configure(with: testImage, screenSize: CGSize(width: 375, height: 667))

        // Test completes without crashing
    }

    @Test
    func `configure with different screen sizes`() {
        let cell = LMKPhotoBrowserCell(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        let testImage = UIImage.lmk_solidColor(.blue, size: CGSize(width: 100, height: 100))

        cell.configure(with: testImage, screenSize: CGSize(width: 320, height: 568)) // iPhone SE
        cell.configure(with: testImage, screenSize: CGSize(width: 428, height: 926)) // iPhone Pro Max

        // Should handle different screen sizes without crashing
    }

    // MARK: - Reset

    @Test
    func `resetZoom completes without crashing`() {
        let cell = LMKPhotoBrowserCell(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        let testImage = UIImage.lmk_solidColor(.green, size: CGSize(width: 100, height: 100))
        cell.configure(with: testImage, screenSize: CGSize(width: 375, height: 667))

        cell.resetZoom()

        // Should complete without crashing
    }

    // MARK: - Reuse

    @Test
    func `prepareForReuse completes without crashing`() {
        let cell = LMKPhotoBrowserCell(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        let testImage = UIImage.lmk_solidColor(.yellow, size: CGSize(width: 100, height: 100))
        cell.configure(with: testImage, screenSize: CGSize(width: 375, height: 667))

        cell.prepareForReuse()

        // Should reset state without crashing
    }

    // MARK: - Layout

    @Test
    func `layoutSubviews completes without crashing`() {
        let cell = LMKPhotoBrowserCell(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        let testImage = UIImage.lmk_solidColor(.purple, size: CGSize(width: 100, height: 100))
        cell.configure(with: testImage, screenSize: CGSize(width: 375, height: 667))

        cell.layoutSubviews()

        // Should complete layout without crashing
    }

    // MARK: - Different Image Sizes

    @Test
    func `Handles portrait image`() {
        let cell = LMKPhotoBrowserCell(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        let portraitImage = UIImage.lmk_solidColor(.orange, size: CGSize(width: 100, height: 200))

        cell.configure(with: portraitImage, screenSize: CGSize(width: 375, height: 667))

        // Should handle portrait aspect ratio
    }

    @Test
    func `Handles landscape image`() {
        let cell = LMKPhotoBrowserCell(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        let landscapeImage = UIImage.lmk_solidColor(.cyan, size: CGSize(width: 200, height: 100))

        cell.configure(with: landscapeImage, screenSize: CGSize(width: 375, height: 667))

        // Should handle landscape aspect ratio
    }

    @Test
    func `Handles square image`() {
        let cell = LMKPhotoBrowserCell(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        let squareImage = UIImage.lmk_solidColor(.magenta, size: CGSize(width: 100, height: 100))

        cell.configure(with: squareImage, screenSize: CGSize(width: 375, height: 667))

        // Should handle square aspect ratio
    }
}
