//
//  LMKListRowTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

@MainActor
struct LMKListRowTests {
    private func makeRow(_ configuration: LMKListRowConfiguration, width: CGFloat = 375) -> (LMKListRowContentView, UIWindow) {
        let view = LMKListRowContentView(configuration: configuration)
        let window = LMKThemeTesting.host(view)
        LMKThemeTesting.fit(view, width: width)
        return (view, window)
    }

    // MARK: - Configuration

    @Test
    func `Defaults: title only, disclosure, enabled`() {
        let configuration = LMKListRowConfiguration(title: "General")
        #expect(configuration.subtitle == nil)
        #expect(configuration.detail == nil)
        if case .none = configuration.leading {} else { Issue.record("leading defaults to none") }
        if case .disclosure = configuration.trailing {} else { Issue.record("trailing defaults to disclosure") }
        #expect(configuration.isEnabled)
        #expect(configuration.isSingleAccessibilityElement)
        #expect(configuration.makeContentView() is LMKListRowContentView)
        #expect(LMKListRowConfiguration.Style.defaultValue == LMKListRowConfiguration.Style())
    }

    @Test
    func `updated(for:) copies the cell state`() {
        var state = UICellConfigurationState(traitCollection: .current)
        state.isHighlighted = true
        state.isDisabled = true
        let updated = LMKListRowConfiguration(title: "T").updated(for: state)
        #expect(updated.isHighlighted)
        #expect(!updated.isEnabled)
        #expect(!updated.isSelected)
    }

    // MARK: - Content view

    @Test
    func `Renders title, subtitle, detail, a symbol circle, and a chevron`() {
        let (view, window) = makeRow(LMKListRowConfiguration(
            title: "Destinations",
            subtitle: "Tokyo, Kyoto, Osaka",
            detail: "3",
            leading: .symbol("mappin.and.ellipse", tint: .systemGreen)
        ))
        defer { window.isHidden = true }
        #expect(view.titleLabel.text == "Destinations")
        #expect(view.subtitleLabel.text == "Tokyo, Kyoto, Osaka")
        #expect(!view.subtitleLabel.isHidden)
        #expect(view.detailLabel.text == "3")
        #expect(!view.detailLabel.isHidden)
        #expect(view.titleLabel.textColor == LMKColor.textPrimary)
        #expect(view.subtitleLabel.textColor == LMKColor.textSecondary)
        #expect(view.titleLabel.font == LMKTypography.font(for: .body, compatibleWith: view.traitCollection))
        #expect(view.subtitleLabel.font == LMKTypography.font(for: .caption, compatibleWith: view.traitCollection))
        #expect(!view.leadingContainer.isHidden)
        #expect(view.leadingContainer.frame.width == LMKLayout.iconCircle)
        #expect(view.leadingContainer.frame.minX == LMKSpacing.large)
        #expect(view.leadingContainer.layer.cornerRadius == LMKLayout.iconCircle / 2)
        #expect(view.leadingContainer.backgroundColor == UIColor.systemGreen.withAlphaComponent(LMKAlpha.xxs))
        #expect(view.leadingImageView.tintColor == UIColor.systemGreen)
        #expect(view.leadingImageView.contentMode == .center)
        #expect(abs(view.textStack.frame.minX - (LMKSpacing.large + LMKLayout.iconCircle + LMKSpacing.medium)) < 0.01)
        #expect(!view.accessoryImageView.isHidden)
        #expect(view.accessoryImageView.tintColor == LMKColor.textTertiary)
        #expect(view.accessoryImageView.image == UIImage(systemName: "chevron.forward", withConfiguration: UIImage.SymbolConfiguration(pointSize: LMKLayout.symbolAccessory, weight: .semibold)))
        #expect(view.trailingStack.frame.maxX == 375 - LMKSpacing.large)
        #expect(view.frame.height >= LMKLayout.rowHeightCompact)
        #expect(view.isAccessibilityElement)
        #expect(view.accessibilityLabel == "Destinations, Tokyo, Kyoto, Osaka, 3")
        #expect(view.accessibilityTraits.contains(.button))
    }

    @Test
    func `No leading view collapses the slot; no subtitle or detail hides the labels`() {
        let (view, window) = makeRow(LMKListRowConfiguration(title: "Help", trailing: .none))
        defer { window.isHidden = true }
        #expect(view.leadingContainer.isHidden)
        #expect(abs(view.textStack.frame.minX - LMKSpacing.large) < 0.01)
        #expect(view.subtitleLabel.isHidden)
        #expect(view.detailLabel.isHidden)
        #expect(view.accessoryImageView.isHidden)
        #expect(view.accessibilityLabel == "Help")
        #expect(!view.accessibilityTraits.contains(.button))
    }

    @Test
    func `Thumbnail, checkmark, badge, image, and custom trailing views`() throws {
        let thumbnail = UIImage.lmk_solidColor(.red, size: CGSize(width: 10, height: 10))
        let (view, window) = makeRow(LMKListRowConfiguration(title: "Food", leading: .image(thumbnail), trailing: .checkmark))
        defer { window.isHidden = true }
        #expect(view.leadingImageView.image === thumbnail)
        #expect(view.leadingImageView.contentMode == .scaleAspectFill)
        #expect(view.leadingContainer.layer.cornerRadius == LMKCornerRadius.small)
        #expect(view.accessoryImageView.tintColor == LMKColor.primary)
        #expect(view.accessibilityTraits.contains(.selected))

        view.configuration = LMKListRowConfiguration(title: "Inbox", trailing: .badge(.count(4)))
        #expect(view.badgeView?.isHidden == false)
        #expect(view.accessoryImageView.isHidden)

        let custom = UIView()
        view.configuration = LMKListRowConfiguration(title: "Custom", leading: .view(UIView()), trailing: .view(custom))
        #expect(view.trailingStack.arrangedSubviews.contains { $0 === custom })
        #expect(view.leadingImageView.isHidden)
        #expect(!view.isAccessibilityElement)

        view.configuration = try LMKListRowConfiguration(title: "Locked", trailing: .image(#require(UIImage(systemName: "lock")), tint: .orange))
        #expect(view.accessoryImageView.tintColor == UIColor.orange)
        #expect(!view.trailingStack.arrangedSubviews.contains { $0 === custom })
        #expect(view.badgeView?.isHidden == true)
    }

    @Test
    func `A toggle row hosts an LMKSwitch that forwards changes and keeps its own accessibility`() {
        var changes: [Bool] = []
        let (view, window) = makeRow(LMKListRowConfiguration(title: "Notifications", trailing: .toggle(isOn: true, onValueChange: { changes.append($0) })))
        defer { window.isHidden = true }
        let toggle = view.toggle
        #expect(toggle?.isOn == true)
        #expect(toggle?.isHidden == false)
        #expect(!view.isAccessibilityElement)
        toggle?.onValueChange?(false)
        #expect(changes == [false])
        view.configuration = LMKListRowConfiguration(title: "Sound", trailing: .toggle(isOn: false, onValueChange: { _ in }))
        #expect(view.toggle === toggle, "the switch is reused")
        #expect(toggle?.isOn == false)
    }

    @Test
    func `A flipped switch keeps its value across the next configuration pass`() throws {
        // Standalone: a theme pass re-applies the configuration, which now carries the flip.
        var changes: [Bool] = []
        let (view, window) = makeRow(LMKListRowConfiguration(title: "Notifications", trailing: .toggle(isOn: false, onValueChange: { changes.append($0) })))
        defer { window.isHidden = true }
        let toggle = try #require(view.toggle)
        toggle.isOn = true
        toggle.onValueChange?(true)
        #expect(changes == [true])
        if case let .toggle(isOn, _) = view.current.trailing { #expect(isOn) } else { Issue.record("trailing must stay a toggle") }
        view.applyTheme(view.traitCollection.lmkTheme)
        #expect(toggle.isOn, "a theme or Dynamic Type pass keeps the flip")

        // In a table cell: the flip is written back into the cell's stored configuration, so the
        // highlight pass UIKit runs when the row is touched keeps it too.
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.frame = CGRect(x: 0, y: 0, width: 375, height: 60)
        cell.lmk_applyListRow(LMKListRowConfiguration(title: "Sound", trailing: .toggle(isOn: false, onValueChange: { changes.append($0) })))
        cell.layoutIfNeeded()
        let content = try #require((cell.contentView as? LMKListRowContentView) ?? cell.contentView.subviews.compactMap { $0 as? LMKListRowContentView }.first)
        let cellToggle = try #require(content.toggle)
        cellToggle.isOn = true
        cellToggle.onValueChange?(true)
        #expect(changes == [true, true])
        if case let .toggle(isOn, _)? = (cell.contentConfiguration as? LMKListRowConfiguration)?.trailing { #expect(isOn) } else { Issue.record("the stored configuration must carry the flip") }
        cell.isHighlighted = true
        cell.setNeedsUpdateConfiguration()
        cell.updateConfiguration(using: cell.configurationState)
        cell.layoutIfNeeded()
        #expect(content.current.isHighlighted, "the state pass reached the content view")
        #expect(cellToggle.isOn, "and the switch stayed on")
        // The host can still reject the change by reapplying the old value.
        cell.lmk_applyListRow(LMKListRowConfiguration(title: "Sound", trailing: .toggle(isOn: false, onValueChange: { _ in })))
        #expect(content.toggle?.isOn == false)

        // The same for a collection list cell.
        let listCell = UICollectionViewListCell()
        listCell.frame = CGRect(x: 0, y: 0, width: 375, height: 60)
        listCell.lmk_applyListRow(LMKListRowConfiguration(title: "Sound", trailing: .toggle(isOn: false, onValueChange: { _ in })))
        listCell.layoutIfNeeded()
        let listContent = try #require((listCell.contentView as? LMKListRowContentView) ?? listCell.contentView.subviews.compactMap { $0 as? LMKListRowContentView }.first)
        listContent.toggle?.isOn = true
        listContent.toggle?.onValueChange?(true)
        if case let .toggle(isOn, _)? = (listCell.contentConfiguration as? LMKListRowConfiguration)?.trailing { #expect(isOn) } else { Issue.record("the stored configuration must carry the flip") }
        listCell.isHighlighted = true
        listCell.setNeedsUpdateConfiguration()
        listCell.updateConfiguration(using: listCell.configurationState)
        listCell.layoutIfNeeded()
        #expect(listContent.current.isHighlighted)
        #expect(listContent.toggle?.isOn == true)
    }

    @Test
    func `A reused row removes only the custom views it still owns`() {
        let leading = UIView()
        let trailing = UIView()
        let (a, windowA) = makeRow(LMKListRowConfiguration(title: "A", leading: .view(leading), trailing: .view(trailing)))
        defer { windowA.isHidden = true }
        #expect(leading.superview === a.leadingContainer)
        #expect(trailing.superview === a.trailingStack)
        // Row B takes both views (a reload handed row 0's views to another cell).
        let (b, windowB) = makeRow(LMKListRowConfiguration(title: "B", leading: .view(leading), trailing: .view(trailing)))
        defer { windowB.isHidden = true }
        #expect(leading.superview === b.leadingContainer)
        #expect(trailing.superview === b.trailingStack)
        // Row A is reconfigured for another row: it must not pull the views out of B.
        a.configuration = LMKListRowConfiguration(title: "Other", leading: .symbol("star"), trailing: .disclosure)
        #expect(leading.superview === b.leadingContainer)
        #expect(trailing.superview === b.trailingStack)
        #expect(b.trailingStack.arrangedSubviews.contains { $0 === trailing })
        // Re-applying the same views to B keeps them in place.
        b.configuration = LMKListRowConfiguration(title: "B", leading: .view(leading), trailing: .view(trailing))
        #expect(leading.superview === b.leadingContainer)
        #expect(b.trailingStack.arrangedSubviews.count(where: { $0 === trailing }) == 1)
    }

    @Test
    func `Highlighted and selected styles reach the row through the cell state`() {
        let style = LMKListRowConfiguration.Style(
            highlighted: LMKControlStateStyle(background: .solid(.yellow), foregroundColor: .red, alpha: 0.8),
            selected: LMKControlStateStyle(background: .solid(.green), foregroundColor: .blue)
        )
        let base = LMKListRowConfiguration(title: "Row", subtitle: "S", detail: "D", trailing: .disclosure, style: style)
        let (view, window) = makeRow(base)
        defer { window.isHidden = true }
        #expect(view.stateBackgroundView.isHidden)
        #expect(view.titleLabel.textColor == LMKColor.textPrimary)

        var state = UICellConfigurationState(traitCollection: .current)
        state.isSelected = true
        view.configuration = base.updated(for: state)
        #expect(view.stateBackgroundView.isHidden == false)
        #expect(view.stateBackgroundView.backgroundColor == UIColor.green)
        #expect(view.titleLabel.textColor == UIColor.blue)
        #expect(view.subtitleLabel.textColor == UIColor.blue)
        #expect(view.detailLabel.textColor == UIColor.blue)
        #expect(view.accessoryImageView.tintColor == UIColor.blue)
        #expect(view.alpha == 1)

        state.isHighlighted = true
        view.configuration = base.updated(for: state)
        #expect(view.stateBackgroundView.backgroundColor == UIColor.yellow, "highlighted layers over selected")
        #expect(view.titleLabel.textColor == UIColor.red)
        #expect(abs(view.alpha - 0.8) < 0.001)

        view.configuration = base
        #expect(view.titleLabel.textColor == LMKColor.textPrimary)
        #expect(view.accessoryImageView.tintColor == LMKColor.textTertiary)
        #expect(view.alpha == 1)
        // Without a state style the flags change nothing visible.
        let (plain, plainWindow) = makeRow(LMKListRowConfiguration(title: "Plain").updated(for: state))
        defer { plainWindow.isHidden = true }
        #expect(plain.current.isHighlighted && plain.current.isSelected)
        #expect(plain.stateBackgroundView.isHidden)
        #expect(plain.titleLabel.textColor == LMKColor.textPrimary)
    }

    @Test
    func `The title takes the width back when the row grows`() {
        let view = LMKListRowContentView(configuration: LMKListRowConfiguration(title: "A title that needs the whole row to stay on one line", trailing: .none))
        LMKThemeTesting.fit(view, width: 200)
        let lineHeight = view.titleLabel.font.lineHeight
        #expect(view.titleLabel.frame.height > lineHeight * 1.5, "wraps at 200")
        LMKThemeTesting.fit(view, width: 420)
        #expect(view.titleLabel.frame.height < lineHeight * 1.5, "one line at 420: \(view.titleLabel.frame)")
        #expect(abs(view.textStack.frame.maxX - (420 - LMKSpacing.large)) < 0.5, "the text stack is pinned to the trailing inset")
    }

    @Test
    func `Async images show a placeholder, then the loaded image, never a stale one`() async {
        let loaded = UIImage.lmk_solidColor(.blue, size: CGSize(width: 8, height: 8))
        let (view, window) = makeRow(LMKListRowConfiguration(title: "Photo", leading: .asyncImage(id: "a", load: { _ in loaded })))
        defer { window.isHidden = true }
        #expect(view.leadingImageView.contentMode == .center, "placeholder symbol first")
        await LMKWait.until { view.leadingImageView.image === loaded }
        #expect(view.leadingImageView.contentMode == .scaleAspectFill)

        let slow = UIImage.lmk_solidColor(.green, size: CGSize(width: 8, height: 8))
        view.configuration = LMKListRowConfiguration(title: "Photo", leading: .asyncImage(id: "b", load: { _ in
            try? await Task.sleep(for: .milliseconds(200))
            return slow
        }))
        #expect(view.leadingImageView.contentMode == .center, "a new id resets to the placeholder")
        view.configuration = LMKListRowConfiguration(title: "Photo", leading: .asyncImage(id: "c", load: { _ in loaded }))
        await LMKWait.until { view.leadingImageView.image === loaded }
        try? await Task.sleep(for: .milliseconds(350))
        #expect(view.leadingImageView.image === loaded, "the cancelled load for b never lands")
    }

    @Test
    func `Disabled rows dim and read as not enabled`() {
        let (view, window) = makeRow(LMKListRowConfiguration(title: "Off", isEnabled: false))
        defer { window.isHidden = true }
        #expect(abs(view.alpha - LMKAlpha.disabled) < 0.001)
        #expect(view.accessibilityTraits.contains(.notEnabled))
    }

    @Test
    func `Style and theme.listRow restyle the row`() {
        let style = LMKListRowConfiguration.Style(
            titleTextStyle: .bodyBold,
            subtitleTextStyle: .small,
            detailTextStyle: .h4,
            titleColor: .purple,
            subtitleColor: .brown,
            detailColor: .cyan,
            titleLines: 2,
            subtitleLines: 3,
            leadingSize: 40,
            leadingSymbolPointSize: 9,
            leadingCircleAlpha: 0.5,
            leadingCorners: .fixed(3),
            leadingSpacing: 4,
            textSpacing: 6,
            trailingSpacing: 12,
            accessoryChevronSize: 21,
            accessoryTint: .orange,
            checkmarkTint: .magenta,
            contentInsets: NSDirectionalEdgeInsets(top: 2, leading: 10, bottom: 2, trailing: 6),
            minimumHeight: 70,
            disabled: LMKControlStateStyle(alpha: 0.3)
        )
        let (view, window) = makeRow(LMKListRowConfiguration(title: "T", subtitle: "S", detail: "D", leading: .symbol("star", tint: .blue), style: style))
        defer { window.isHidden = true }
        #expect(view.titleLabel.textColor == UIColor.purple)
        #expect(view.subtitleLabel.textColor == UIColor.brown)
        #expect(view.subtitleLabel.font == LMKTypography.font(for: .small, compatibleWith: view.traitCollection))
        #expect(view.detailLabel.font == LMKTypography.font(for: .h4, compatibleWith: view.traitCollection))
        #expect(view.detailLabel.textColor == UIColor.cyan)
        #expect(view.titleLabel.numberOfLines == 2)
        #expect(view.subtitleLabel.numberOfLines == 3)
        #expect(view.leadingContainer.frame.width == 40)
        #expect(view.leadingContainer.frame.minX == 10)
        #expect(view.leadingImageView.image == UIImage(systemName: "star", withConfiguration: UIImage.SymbolConfiguration(pointSize: 9)))
        #expect(view.leadingContainer.backgroundColor == UIColor.blue.withAlphaComponent(0.5))
        #expect(abs(view.textStack.frame.minX - 54) < 0.01)
        #expect(view.textStack.spacing == 6)
        #expect(view.trailingStack.spacing == 12)
        #expect(abs(view.textStack.frame.maxX - (view.trailingStack.frame.minX - 12)) < 0.5)
        #expect(view.accessoryImageView.image == UIImage(systemName: "chevron.forward", withConfiguration: UIImage.SymbolConfiguration(pointSize: 21, weight: .semibold)))
        #expect(view.accessoryImageView.tintColor == UIColor.orange)
        #expect(view.trailingStack.frame.maxX == 369)
        #expect(view.frame.height == 70)
        view.configuration = LMKListRowConfiguration(title: "T", leading: .image(UIImage.lmk_solidColor(.red, size: CGSize(width: 4, height: 4))), trailing: .checkmark, style: style, isEnabled: false)
        #expect(view.leadingContainer.layer.cornerRadius == 3)
        #expect(view.accessoryImageView.tintColor == UIColor.magenta)
        #expect(abs(view.alpha - 0.3) < 0.001)
        #expect(LMKListRowConfiguration.Style().merging(style) == style, "merging over an empty style keeps every field")

        var theme = LMKTheme()
        theme.listRow = LMKListRowConfiguration.Style(titleColor: .magenta, minimumHeight: 60)
        let (themed, themedWindow) = makeRow(LMKListRowConfiguration(title: "T"))
        defer { themedWindow.isHidden = true }
        themed.applyTheme(theme)
        LMKThemeTesting.fit(themed)
        #expect(themed.titleLabel.textColor == UIColor.magenta)
        #expect(themed.frame.height == 60)
    }

    @Test
    func `Accessibility label and hint overrides`() {
        let (view, window) = makeRow(LMKListRowConfiguration(title: "T", subtitle: "S", accessibilityLabel: "Custom", accessibilityHint: "Opens"))
        defer { window.isHidden = true }
        #expect(view.accessibilityLabel == "Custom")
        #expect(view.accessibilityHint == "Opens")
        #expect(view.supports(LMKListRowConfiguration(title: "x")))
        #expect(!view.supports(UIListContentConfiguration.cell()))
    }

    // MARK: - Cells

    @Test
    func `lmk_applyListRow configures a table cell once per pointer interaction`() {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.accessoryType = .disclosureIndicator
        cell.lmk_applyListRow(LMKListRowConfiguration(title: "Row"), backgroundColor: .red)
        #expect(cell.contentConfiguration is LMKListRowConfiguration)
        #expect(cell.accessoryType == .none)
        #expect(cell.backgroundColor == UIColor.red)
        #expect(cell.selectedBackgroundView?.backgroundColor?.resolvedColor(with: cell.traitCollection) == LMKHighlightConstants.highlightOverlayColor.resolvedColor(with: cell.traitCollection))
        #expect(cell.lmk_hasRowPointerInteraction)
        let interactions = cell.interactions.count(where: { $0 is UIPointerInteraction })
        let selectedBackground = cell.selectedBackgroundView
        cell.lmk_applyListRow(LMKListRowConfiguration(title: "Again"))
        #expect(cell.interactions.count(where: { $0 is UIPointerInteraction }) == interactions)
        #expect(cell.selectedBackgroundView === selectedBackground, "the highlight view is installed once")
        #expect(cell.backgroundColor == UIColor.red, "nil leaves the background")
        #expect(cell.selectionStyle == .default)

        cell.lmk_applyListRow(LMKListRowConfiguration(title: "Toggle", trailing: .toggle(isOn: false, onValueChange: { _ in })))
        #expect(cell.selectionStyle == .none)
        cell.lmk_applyListRow(LMKListRowConfiguration(title: "Disclosure again"))
        #expect(cell.selectionStyle == .default, "a reused cell gets its highlight back")
        cell.lmk_applyListRow(LMKListRowConfiguration(title: "Off", isEnabled: false))
        #expect(cell.selectionStyle == .none)
        let plain = UITableViewCell(style: .default, reuseIdentifier: nil)
        plain.lmk_applyListRow(LMKListRowConfiguration(title: "No pointer"), pointer: nil)
        #expect(!plain.lmk_hasRowPointerInteraction)
    }

    @Test
    func `lmk_applyListRow configures a collection list cell`() {
        let cell = UICollectionViewListCell()
        cell.accessories = [.disclosureIndicator()]
        cell.lmk_applyListRow(LMKListRowConfiguration(title: "Row"), backgroundColor: .blue, pointer: .lift)
        #expect(cell.contentConfiguration is LMKListRowConfiguration)
        #expect(cell.accessories.isEmpty)
        #expect(cell.backgroundConfiguration?.backgroundColor == UIColor.blue)
        #expect(cell.lmk_hasRowPointerInteraction)
    }

    @Test
    func `Row pointer interaction installs once and updates its effect`() {
        let view = UIView()
        #expect(!view.lmk_hasRowPointerInteraction)
        view.lmk_installRowPointerInteraction(.hover)
        view.lmk_installRowPointerInteraction(.lift)
        #expect(view.interactions.count(where: { $0 is UIPointerInteraction }) == 1)
        #expect(view.lmk_hasRowPointerInteraction)
    }

    // MARK: - System configuration helpers and tables

    @Test
    func `UIListContentConfiguration helpers apply tokens`() {
        var content = UIListContentConfiguration.cell()
        content.lmk_applyTextStyle()
        #expect(content.textProperties.font == LMKTypography.font(for: .bodyMedium))
        #expect(content.textProperties.color == LMKColor.textPrimary)
        #expect(content.textProperties.adjustsFontForContentSizeCategory)
        #expect(content.secondaryTextProperties.font == LMKTypography.font(for: .caption))
        #expect(content.secondaryTextProperties.color == LMKColor.textSecondary)

        content.lmk_applyLeadingSymbol("gearshape", tint: .systemBlue)
        #expect(content.image != nil)
        #expect(content.imageProperties.cornerRadius == LMKLayout.iconCircle / 2)
        #expect(content.imageProperties.reservedLayoutSize == CGSize(width: LMKLayout.iconCircle, height: LMKLayout.iconCircle))
        let asset = content.image?.imageAsset
        let light = asset?.image(with: UITraitCollection(userInterfaceStyle: .light))
        let dark = asset?.image(with: UITraitCollection(userInterfaceStyle: .dark))
        #expect(light != nil && dark != nil && light !== dark, "a variant per appearance is registered")

        content.lmk_applyLeadingSymbol("gearshape", circle: false)
        #expect(content.imageProperties.cornerRadius == 0)
        #expect(content.imageProperties.tintColor == LMKColor.primary)

        let thumb = UIImage.lmk_solidColor(.red, size: CGSize(width: 4, height: 4))
        content.lmk_applyThumbnail(thumb, side: 50, cornerRadius: 7)
        #expect(content.image === thumb)
        #expect(content.imageProperties.cornerRadius == 7)
        #expect(content.imageProperties.maximumSize == CGSize(width: 50, height: 50))
        content.lmk_applyThumbnail(nil, fallbackSymbol: "photo", fallbackTint: .gray)
        #expect(content.image == UIImage(systemName: "photo", withConfiguration: UIImage.SymbolConfiguration(pointSize: LMKLayout.symbolProminent)))
        #expect(content.imageProperties.tintColor == UIColor.gray)
    }

    @Test
    func `LMKListTable builds an inset-grouped table with the standard setup`() {
        let table = LMKListTable.makeInsetGrouped()
        #expect(table.style == .insetGrouped)
        #expect(table.backgroundColor == LMKColor.backgroundPrimary)
        #expect(table.rowHeight == UITableView.automaticDimension)
        #expect(table.estimatedRowHeight == LMKLayout.rowHeightEstimated)
        #expect(table.cellLayoutMarginsFollowReadableWidth)
        #expect(table.dequeueReusableCell(withIdentifier: LMKListTable.cellReuseIdentifier) != nil)
        let plain = LMKListTable.make(style: .plain, registersDefaultCell: false)
        #expect(plain.style == .plain)
        #expect(plain.dequeueReusableCell(withIdentifier: LMKListTable.cellReuseIdentifier) == nil)
    }
}
