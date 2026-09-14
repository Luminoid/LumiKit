//
//  LMKDeviceHelperTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKDeviceHelper

@MainActor
struct LMKDeviceHelperTests {
    /// One row of the device table: canvas size in points plus the size classes
    /// UIKit reports for it, and the tier it must land in.
    private struct Canvas {
        let name: String
        let size: CGSize
        let horizontal: UIUserInterfaceSizeClass
        let vertical: UIUserInterfaceSizeClass
        let expected: LMKScreenSize

        init(
            _ name: String,
            _ width: CGFloat,
            _ height: CGFloat,
            horizontal: UIUserInterfaceSizeClass = .compact,
            vertical: UIUserInterfaceSizeClass = .regular,
            expected: LMKScreenSize
        ) {
            self.name = name
            self.size = CGSize(width: width, height: height)
            self.horizontal = horizontal
            self.vertical = vertical
            self.expected = expected
        }
    }

    private static let phoneCatalog: [Canvas] = [
        Canvas("iPhone SE (3rd gen)", 375, 667, expected: .compact),
        Canvas("iPhone 13 mini", 375, 812, expected: .compact),
        Canvas("iPhone 17e", 390, 844, expected: .regular),
        Canvas("iPhone 16", 393, 852, expected: .regular),
        Canvas("iPhone 17", 402, 874, expected: .regular),
        Canvas("iPhone 18 Pro", 402, 874, expected: .regular),
        Canvas("iPhone 11", 414, 896, expected: .large),
        Canvas("iPhone Air", 420, 912, expected: .large),
        Canvas("iPhone 16 Plus", 430, 932, expected: .large),
        Canvas("iPhone 18 Pro Max", 440, 956, expected: .large),
        Canvas("iPhone Duo cover display", 466, 678, expected: .large),
        Canvas("iPhone Duo inner display", 669, 951, horizontal: .regular, vertical: .regular, expected: .extraLarge),
    ]

    private func classify(_ canvas: Canvas) -> LMKScreenSize {
        LMKDeviceHelper.screenSize(
            forWindowSize: canvas.size,
            horizontalSizeClass: canvas.horizontal,
            verticalSizeClass: canvas.vertical
        )
    }

    // MARK: - Device type

    @Test
    func `deviceType returns a valid case`() {
        let type = LMKDeviceHelper.deviceType
        // Should be one of the valid cases (we can't predict which in tests)
        switch type {
        case .iPhone, .iPad, .macCatalyst, .other:
            break // All valid
        }
    }

    @Test
    func `isIPad and isMacCatalyst are consistent`() {
        let type = LMKDeviceHelper.deviceType
        if type == .iPad {
            #expect(LMKDeviceHelper.isIPad)
            #expect(!LMKDeviceHelper.isMacCatalyst)
        } else if type == .macCatalyst {
            #expect(!LMKDeviceHelper.isIPad)
            #expect(LMKDeviceHelper.isMacCatalyst)
        }
    }

    // MARK: - Classification

    @Test
    func `breakpoints are ordered`() {
        #expect(LMKDeviceHelper.compactMaxWidth < LMKDeviceHelper.regularMaxWidth)
    }

    @Test
    func `every current iPhone lands in its documented tier`() {
        for canvas in Self.phoneCatalog {
            #expect(classify(canvas) == canvas.expected, "\(canvas.name) should be \(canvas.expected)")
        }
    }

    @Test
    func `classification ignores orientation`() {
        for canvas in Self.phoneCatalog {
            let rotated = Canvas(
                canvas.name,
                canvas.size.height,
                canvas.size.width,
                horizontal: canvas.horizontal,
                vertical: canvas.vertical,
                expected: canvas.expected
            )
            #expect(classify(rotated) == canvas.expected, "\(canvas.name) rotated should stay \(canvas.expected)")
        }
    }

    @Test
    func `a Pro Max in landscape stays large, not extraLarge`() {
        // Regular width but compact height: wide, yet not an expanded canvas.
        let landscape = Canvas("iPhone 18 Pro Max landscape", 956, 440, horizontal: .regular, vertical: .compact, expected: .large)
        #expect(classify(landscape) == .large)
    }

    @Test
    func `regular by regular canvases are extraLarge regardless of size`() {
        let canvases = [
            Canvas("iPad Pro 13", 1024, 1366, horizontal: .regular, vertical: .regular, expected: .extraLarge),
            Canvas("iPad mini", 744, 1133, horizontal: .regular, vertical: .regular, expected: .extraLarge),
            Canvas("iPhone Duo inner landscape", 951, 669, horizontal: .regular, vertical: .regular, expected: .extraLarge),
            Canvas("Wide Stage Manager window", 700, 500, horizontal: .regular, vertical: .regular, expected: .extraLarge),
        ]
        for canvas in canvases {
            #expect(classify(canvas) == .extraLarge, "\(canvas.name) should be extraLarge")
        }
    }

    @Test
    func `compact width windows on iPad classify like phones by width`() {
        let slideOver = Canvas("Slide Over", 320, 1180, expected: .compact)
        let thirdSplit = Canvas("One-third Split View", 375, 1024, expected: .compact)
        let halfSplit11 = Canvas("Half Split View on 11-inch", 592, 834, expected: .large)
        #expect(classify(slideOver) == .compact)
        #expect(classify(thirdSplit) == .compact)
        #expect(classify(halfSplit11) == .large)
    }

    @Test
    func `unspecified size classes never reach extraLarge`() {
        let detached = Canvas("Detached iPad-sized view", 1024, 1366, horizontal: .unspecified, vertical: .unspecified, expected: .large)
        #expect(classify(detached) == .large)
    }

    @Test
    func `boundary widths sit on the documented side`() {
        #expect(classify(Canvas("at compact max", 375, 800, expected: .compact)) == .compact)
        #expect(classify(Canvas("just above compact max", 376, 800, expected: .regular)) == .regular)
        #expect(classify(Canvas("at regular max", 402, 800, expected: .regular)) == .regular)
        #expect(classify(Canvas("just above regular max", 403, 800, expected: .large)) == .large)
    }

    // MARK: - View-based lookup

    @Test
    func `screenSize(for:) reads a laid-out view's own bounds`() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 402, height: 874))
        #expect(LMKDeviceHelper.screenSize(for: view) == .regular)

        let wide = UIView(frame: CGRect(x: 0, y: 0, width: 440, height: 956))
        #expect(LMKDeviceHelper.screenSize(for: wide) == .large)
    }

    @Test
    func `screenSize(for:) on the key window matches the static lookup`() {
        guard let window = LMKSceneUtil.getKeyWindow() else { return }
        #expect(LMKDeviceHelper.screenSize(for: window) == LMKDeviceHelper.screenSize)
    }

    @Test
    func `screenSize returns a valid case`() {
        let size = LMKDeviceHelper.screenSize
        switch size {
        case .compact, .regular, .large, .extraLarge:
            break // All valid
        }
    }

    // MARK: - Display cutout

    @Test
    func `hasTopNotch is false off iPhone and follows the top inset on iPhone`() {
        guard LMKDeviceHelper.deviceType == .iPhone else {
            #expect(!LMKDeviceHelper.hasTopNotch)
            return
        }
        guard let window = LMKSceneUtil.getKeyWindow() else {
            #expect(!LMKDeviceHelper.hasTopNotch)
            return
        }
        #expect(LMKDeviceHelper.hasTopNotch == (window.safeAreaInsets.top > 20))
    }
}
