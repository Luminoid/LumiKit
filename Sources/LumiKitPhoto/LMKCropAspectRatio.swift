//
//  LMKCropAspectRatio.swift
//  LumiKit
//
//  Aspect ratio presets of the crop editor.
//

import Foundation

/// Crop aspect ratio presets.
public nonisolated enum LMKCropAspectRatio: Sendable, Hashable, CaseIterable {
    case square
    case fourThree
    case threeTwo
    case sixteenNine
    case twoThree
    case threeFour
    case nineSixteen
    /// No fixed ratio; every edge is draggable.
    case free

    /// The six presets the crop editor offers by default.
    public static let standard: [Self] = [.square, .fourThree, .threeTwo, .twoThree, .threeFour, .free]

    /// Numeric ratio (width / height), or `nil` for free.
    public var ratio: CGFloat? {
        switch self {
        case .square: 1
        case .fourThree: 4 / 3
        case .threeTwo: 3 / 2
        case .sixteenNine: 16 / 9
        case .twoThree: 2 / 3
        case .threeFour: 3 / 4
        case .nineSixteen: 9 / 16
        case .free: nil
        }
    }

    /// Display name ("1:1", "16:9", or the localized "Free").
    public var displayName: String {
        switch self {
        case .square: "1:1"
        case .fourThree: "4:3"
        case .threeTwo: "3:2"
        case .sixteenNine: "16:9"
        case .twoThree: "2:3"
        case .threeFour: "3:4"
        case .nineSixteen: "9:16"
        case .free: LMKPhotoCropViewController.strings.free
        }
    }
}
