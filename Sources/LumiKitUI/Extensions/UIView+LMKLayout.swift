//
//  UIView+LMKLayout.swift
//  LumiKit
//
//  SnapKit-based layout helper extensions.
//

import SnapKit
import UIKit

public extension UIView {
    /// Safe area SnapKit DSL accessor.
    var lmk_safeAreaSnp: ConstraintBasicAttributesDSL {
        safeAreaLayoutGuide.snp
    }

    /// Pin edges to superview. Must be called after `addSubview`.
    func lmk_setEdgesEqualToSuperview() {
        guard superview != nil else { return }
        snp.makeConstraints { make in make.edges.equalToSuperview() }
    }

    /// Center in superview. Must be called after `addSubview`.
    func lmk_centerInSuperview() {
        guard superview != nil else { return }
        snp.makeConstraints { make in make.center.equalToSuperview() }
    }

    @available(*, deprecated, renamed: "lmk_setEdgesEqualToSuperview")
    func lmk_setEdgesEqualToSuperView() {
        lmk_setEdgesEqualToSuperview()
    }

    /// Set fixed Auto Layout size.
    func lmk_setAutoLayoutSize(width: CGFloat, height: CGFloat) {
        snp.makeConstraints { make in
            make.width.equalTo(width)
            make.height.equalTo(height)
        }
    }
}
