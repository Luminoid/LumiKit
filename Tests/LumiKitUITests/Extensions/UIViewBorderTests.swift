//
//  UIViewBorderTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - UIView+LMKBorder

@MainActor
struct UIViewBorderTests {
    @Test
    func `lmk_applyBorder sets layer properties`() {
        let view = UIView()
        view.lmk_applyBorder(color: .red, width: 2, cornerRadius: 8)
        #expect(view.layer.borderWidth == 2)
        #expect(view.layer.cornerRadius == 8)
        #expect(view.layer.masksToBounds)
    }

    @Test
    func `lmk_removeBorder clears layer properties`() {
        let view = UIView()
        view.lmk_applyBorder(color: .red, width: 2)
        view.lmk_removeBorder()
        #expect(view.layer.borderWidth == 0)
    }

    @Test
    func `lmk_applyCornerRadius sets radius and masking`() {
        let view = UIView()
        view.lmk_applyCornerRadius(12, masking: false)
        #expect(view.layer.cornerRadius == 12)
        #expect(!view.layer.masksToBounds)
    }

    @Test
    func `lmk_applyConcentricCorners floors at the minimum radius and masks`() {
        let view = UIView()
        view.lmk_applyConcentricCorners(minimumRadius: 8)
        #expect(view.layer.masksToBounds)
        if #available(iOS 26, *) {
            #expect(view.cornerConfiguration == .corners(radius: .containerConcentric(minimum: 8)))
        } else {
            #expect(view.layer.cornerRadius == 8)
        }
    }

    @Test
    func `lmk_applyCornerRadius publishes a container configuration only when asked`() {
        let plain = UIView()
        plain.lmk_applyCornerRadius(12)
        #expect(plain.layer.cornerRadius == 12)

        let container = UIView()
        container.lmk_applyCornerRadius(12, asConcentricContainer: true)
        #expect(container.layer.cornerRadius == 12)
        #expect(container.layer.masksToBounds)
        if #available(iOS 26, *) {
            // A bare layer radius is invisible to UIKit's concentric math.
            #expect(plain.cornerConfiguration == UIView().cornerConfiguration)
            #expect(container.cornerConfiguration == .corners(radius: .fixed(12)))
        }
    }

    @Test
    func `lmk_applyConcentricCorners can leave masking off`() {
        let view = UIView()
        view.lmk_applyConcentricCorners(minimumRadius: 8, masking: false)
        #expect(!view.layer.masksToBounds)
    }
}
