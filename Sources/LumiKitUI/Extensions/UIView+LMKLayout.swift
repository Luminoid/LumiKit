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

    /// Pin edges to superview.
    func lmk_setEdgesEqualToSuperView() {
        snp.makeConstraints { make in make.edges.equalToSuperview() }
    }

    /// Set fixed Auto Layout size.
    func lmk_setAutoLayoutSize(width: CGFloat, height: CGFloat) {
        snp.makeConstraints { make in
            make.width.equalTo(width)
            make.height.equalTo(height)
        }
    }
}
