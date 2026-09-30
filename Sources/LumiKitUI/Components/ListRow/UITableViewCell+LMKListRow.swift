//
//  UITableViewCell+LMKListRow.swift
//  LumiKit
//
//  One-call list row setup for table and collection list cells.
//

import UIKit

public extension UITableViewCell {
    /// Renders `configuration` in the cell with the LumiKit highlight and an optional pointer
    /// effect. Clears the system accessory (the row draws its own, inside the highlight area).
    ///
    /// - Parameters:
    ///   - configuration: The row.
    ///   - backgroundColor: When given, the cell background (`backgroundSecondary` for inset-grouped tables); `nil` leaves it.
    ///   - pointer: The whole-row pointer effect, installed once; `nil` installs none.
    func lmk_applyListRow(_ configuration: LMKListRowConfiguration, backgroundColor: UIColor? = nil, pointer: LMKRowPointerEffect? = .hover) {
        contentConfiguration = configuration
        accessoryType = .none
        accessoryView = nil
        if let backgroundColor {
            self.backgroundColor = backgroundColor
        }
        lmk_configureCustomHighlight()
        if case .toggle = configuration.trailing {
            selectionStyle = .none
        } else if !configuration.isEnabled {
            selectionStyle = .none
        }
        if let pointer {
            lmk_installRowPointerInteraction(pointer)
        }
    }
}

public extension UICollectionViewListCell {
    /// Renders `configuration` in the cell with an optional background color and pointer effect.
    /// Clears the cell's accessories (the row draws its own).
    func lmk_applyListRow(_ configuration: LMKListRowConfiguration, backgroundColor: UIColor? = nil, pointer: LMKRowPointerEffect? = .hover) {
        contentConfiguration = configuration
        accessories = []
        if let backgroundColor {
            var background = defaultBackgroundConfiguration()
            background.backgroundColor = backgroundColor
            backgroundConfiguration = background
        }
        if let pointer {
            lmk_installRowPointerInteraction(pointer)
        }
    }
}
