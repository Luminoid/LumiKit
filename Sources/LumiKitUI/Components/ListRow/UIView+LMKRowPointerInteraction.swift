//
//  UIView+LMKRowPointerInteraction.swift
//  LumiKit
//
//  A whole-row pointer effect (iPad pointer, Mac Catalyst), installed once
//  however often the row is reconfigured.
//

import UIKit

/// The pointer effect for a row.
public enum LMKRowPointerEffect: Sendable, Hashable {
    case automatic
    case highlight
    case lift
    case hover
}

private nonisolated(unsafe) var lmk_rowPointerDelegateKey: UInt8 = 0

public extension UIView {
    /// Installs a pointer interaction covering the whole view, exactly once: rows reconfigure on
    /// every dequeue, so the retained delegate doubles as the installed marker (a second call
    /// only updates the effect). The style is routed through `LMKPointerStyle`, so a windowless
    /// row (recycled mid-hover) yields no style instead of tripping `UITargetedPreview`'s window
    /// assertion. Inert on platforms without pointer support.
    func lmk_installRowPointerInteraction(_ effect: LMKRowPointerEffect = .hover) {
        if let delegate = objc_getAssociatedObject(self, &lmk_rowPointerDelegateKey) as? LMKRowPointerDelegate {
            delegate.effect = effect
            return
        }
        let delegate = LMKRowPointerDelegate(effect: effect)
        objc_setAssociatedObject(self, &lmk_rowPointerDelegateKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        addInteraction(UIPointerInteraction(delegate: delegate))
    }

    /// Whether `lmk_installRowPointerInteraction(_:)` has run on this view.
    var lmk_hasRowPointerInteraction: Bool {
        objc_getAssociatedObject(self, &lmk_rowPointerDelegateKey) != nil
    }
}

private final class LMKRowPointerDelegate: NSObject, UIPointerInteractionDelegate {
    var effect: LMKRowPointerEffect

    init(effect: LMKRowPointerEffect) {
        self.effect = effect
    }

    func pointerInteraction(_ interaction: UIPointerInteraction, styleFor _: UIPointerRegion) -> UIPointerStyle? {
        switch effect {
        case .automatic: LMKPointerStyle.automatic(for: interaction.view)
        case .highlight: LMKPointerStyle.highlight(for: interaction.view)
        case .lift: LMKPointerStyle.lift(for: interaction.view)
        case .hover: LMKPointerStyle.hover(for: interaction.view)
        }
    }
}
