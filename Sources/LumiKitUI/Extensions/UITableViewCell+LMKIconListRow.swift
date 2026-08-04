//
//  UITableViewCell+LMKIconListRow.swift
//  LumiKit
//
//  Standard icon-in-tinted-circle list row configuration.
//

import UIKit

private nonisolated(unsafe) var lmk_iconListRowPointerDelegateKey: UInt8 = 0

public extension UITableViewCell {
    /// Standard detail-list row: an SF Symbol in a tinted circle, bodyMedium
    /// title, caption subtitle, disclosure, and the LumiKit highlight. Use for
    /// secondary list pages (settings, people, destinations) so they read as
    /// one family.
    ///
    /// - Parameter pointerEnabled: When `true` (the default), installs a
    ///   `UIPointerInteraction` on the cell — once, guarded against repeated
    ///   reconfiguration — whose hover effect targets the whole row. Inert on
    ///   platforms without pointer support.
    func lmk_configureIconListRow(
        iconSystemName: String,
        title: String,
        subtitle: String? = nil,
        tint: UIColor = LMKColor.primary,
        pointerEnabled: Bool = true
    ) {
        var content = defaultContentConfiguration()
        content.text = title
        content.textProperties.font = LMKTypography.bodyMedium
        content.textProperties.color = LMKColor.textPrimary
        content.secondaryText = subtitle
        content.secondaryTextProperties.font = LMKTypography.caption
        content.secondaryTextProperties.color = LMKColor.textSecondary
        content.image = LMKImageUtil.makeSymbolImage(
            iconSystemName,
            size: CGSize(width: LMKLayout.iconCircle, height: LMKLayout.iconCircle),
            symbolPointSize: LMKLayout.iconExtraSmall,
            tintColor: tint,
            backgroundColor: tint.withAlphaComponent(LMKAlpha.overlayLight)
        )
        content.imageProperties.cornerRadius = LMKLayout.iconCircle / 2
        contentConfiguration = content
        backgroundColor = LMKColor.backgroundSecondary
        accessoryType = .disclosureIndicator
        lmk_configureCustomHighlight()

        if pointerEnabled {
            lmk_installIconListRowPointerInteraction()
        }
    }
}

private extension UITableViewCell {
    /// Installs the row's pointer interaction exactly once. Rows are
    /// reconfigured on every dequeue, so the retained delegate doubles as the
    /// "already installed" marker — without it, each reconfiguration would
    /// stack another interaction on the cell.
    func lmk_installIconListRowPointerInteraction() {
        guard objc_getAssociatedObject(self, &lmk_iconListRowPointerDelegateKey) == nil else { return }
        let delegate = LMKIconListRowPointerDelegate()
        objc_setAssociatedObject(self, &lmk_iconListRowPointerDelegateKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        addInteraction(UIPointerInteraction(delegate: delegate))
    }
}

/// Pointer delegate for icon list rows. The style is routed through
/// `LMKPointerStyle` so a windowless cell (recycled mid-hover) yields `nil`
/// instead of tripping `UITargetedPreview`'s window assertion — see
/// `LMKPointerStyle`'s documentation.
private final class LMKIconListRowPointerDelegate: NSObject, UIPointerInteractionDelegate {
    func pointerInteraction(_ interaction: UIPointerInteraction, styleFor _: UIPointerRegion) -> UIPointerStyle? {
        LMKPointerStyle.hover(for: interaction.view)
    }
}
