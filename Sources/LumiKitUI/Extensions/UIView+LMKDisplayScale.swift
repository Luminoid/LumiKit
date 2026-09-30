//
//  UIView+LMKDisplayScale.swift
//  LumiKit
//
//  The scale a view renders at, for pixel-sized image requests.
//

import UIKit

public extension UIView {
    /// The display scale this view renders at: its own `displayScale` trait, else its window's,
    /// else `LMKScene.screenScale`. Multiply point sizes by it (or use
    /// `LMKImage.pixelSize(points:scale:)`) when requesting downsampled images, instead of
    /// `UIScreen.main.scale`, which is wrong on external displays and iPhone Mirroring.
    var lmk_displayScale: CGFloat {
        LMKScene.displayScale(of: self) ?? LMKScene.displayScale(of: window) ?? LMKScene.screenScale
    }
}
