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
        let (view, window) = makeRow(LMKListRowConfiguration(title: "Notifications", trailing: .toggle(isOn: true, onChange: { changes.append($0) })))
        defer { window.isHidden = true }
        let toggle = view.toggle
        #expect(toggle?.isOn == true)
        #expect(toggle?.isHidden == false)
        #expect(!view.isAccessibilityElement)
        toggle?.onValueChange?(false)
        #expect(changes == [false])
        view.configuration = LMKListRowConfiguration(title: "Sound", trailing: .toggle(isOn: false, onChange: { _ in }))
        #expect(view.toggle === toggle, "the switch is reused")
        #expect(toggle?.isOn == false)
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
            titleColor: .purple,
            subtitleColor: .brown,
            leadingSize: 40,
            leadingSpacing: 4,
            accessoryTint: .orange,
            contentInsets: NSDirectionalEdgeInsets(top: 2, leading: 10, bottom: 2, trailing: 6),
            minimumHeight: 70
        )
        let (view, window) = makeRow(LMKListRowConfiguration(title: "T", subtitle: "S", leading: .symbol("star"), style: style))
        defer { window.isHidden = true }
        #expect(view.titleLabel.textColor == UIColor.purple)
        #expect(view.subtitleLabel.textColor == UIColor.brown)
        #expect(view.subtitleLabel.font == LMKTypography.font(for: .small, compatibleWith: view.traitCollection))
        #expect(view.leadingContainer.frame.width == 40)
        #expect(view.leadingContainer.frame.minX == 10)
        #expect(abs(view.textStack.frame.minX - 54) < 0.01)
        #expect(view.accessoryImageView.tintColor == UIColor.orange)
        #expect(view.trailingStack.frame.maxX == 369)
        #expect(view.frame.height == 70)

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
        cell.lmk_applyListRow(LMKListRowConfiguration(title: "Again"))
        #expect(cell.interactions.count(where: { $0 is UIPointerInteraction }) == interactions)
        #expect(cell.backgroundColor == UIColor.red, "nil leaves the background")
        #expect(cell.selectionStyle == .default)

        cell.lmk_applyListRow(LMKListRowConfiguration(title: "Toggle", trailing: .toggle(isOn: false, onChange: { _ in })))
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
