//
//  UITableViewCell+LMKIconListRow.swift
//  LumiKit
//
//  Standard icon-in-tinted-circle list row configuration.
//

import UIKit

public extension UITableViewCell {
    /// Standard detail-list row: an SF Symbol in a tinted circle, bodyMedium
    /// title, caption subtitle, disclosure, and the LumiKit highlight. Use for
    /// secondary list pages (settings, people, destinations) so they read as
    /// one family.
    func lmk_configureIconListRow(
        iconSystemName: String,
        title: String,
        subtitle: String? = nil,
        tint: UIColor = LMKColor.primary
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
    }
}
