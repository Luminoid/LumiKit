//
//  LMKActionSheetTests.swift
//  LumiKit
//

import Testing
import UIKit
@testable import LumiKitUI

// MARK: - Models

@MainActor
struct LMKActionSheetModelTests {
    @Test
    func `Actions keep their fields and navigation actions carry a page`() {
        let regular = LMKActionSheet.Action(title: "Delete", subtitle: "Detail", style: .destructive, icon: UIImage(systemName: "trash"), isSelected: true, isEnabled: false) {}
        #expect(regular.title == "Delete")
        #expect(regular.subtitle == "Detail")
        #expect(regular.style == .destructive)
        #expect(regular.icon != nil)
        #expect(regular.isSelected)
        #expect(!regular.isEnabled)
        #expect(regular.handler != nil)
        #expect(regular.page == nil)

        let navigation = LMKActionSheet.Action(title: "Edit", page: LMKActionSheet.Page(title: "Sub"))
        #expect(navigation.page?.title == "Sub")
        #expect(navigation.handler == nil)
        #expect(!navigation.isSelected)
        #expect(LMKActionSheet.Action.Style.default != .destructive)
    }

    @Test
    func `Configuration builds the root page`() {
        let content = UIView()
        let configuration = LMKActionSheet.Configuration(title: "T", message: "M", actions: [.init(title: "A") {}], contentView: content, confirmTitle: "Save", onConfirm: {})
        let page = configuration.rootPage
        #expect(page.title == "T")
        #expect(page.message == "M")
        #expect(page.actions.count == 1)
        #expect(page.contentView === content)
        #expect(page.confirmTitle == "Save")
        #expect(page.onConfirm != nil)
        #expect(LMKActionSheet.Page().actions.isEmpty)
        #expect(LMKActionSheet.Strings().back == "Back")
    }
}

// MARK: - Row view

@MainActor
struct LMKActionSheetRowViewTests {
    @Test
    func `Content drives icon, subtitle, accessory, colors, and accessibility`() {
        let row = LMKActionSheetRowView()
        row.configure(LMKActionSheet.Action(title: "Edit", subtitle: "Detail", icon: UIImage(systemName: "pencil"), isSelected: true) {})
        #expect(row.titleLabel.text == "Edit")
        #expect(!row.subtitleLabel.isHidden)
        #expect(!row.iconView.isHidden)
        #expect(!row.checkmarkView.isHidden)
        #expect(row.chevronView.isHidden)
        #expect(row.accessibilityLabel == "Edit, Detail")
        #expect(row.accessibilityTraits.contains(.selected))
        #expect(row.titleLabel.textColor === LMKColor.textPrimary)
        #expect(row.containerView.backgroundColor === LMKColor.backgroundSecondary)

        row.configure(LMKActionSheet.Action(title: "More", page: LMKActionSheet.Page()))
        #expect(!row.chevronView.isHidden)
        #expect(row.checkmarkView.isHidden)
        #expect(row.subtitleLabel.isHidden)
        #expect(row.iconView.isHidden)
        #expect(row.accessibilityHint == "Opens submenu")

        row.configure(LMKActionSheet.Action(title: "Delete", style: .destructive) {})
        #expect(row.titleLabel.textColor === LMKColor.error)
        #expect(row.iconView.tintColor === LMKColor.error)
    }

    @Test
    func `Disabled rows dim and ignore taps; highlight tints the background`() {
        let row = LMKActionSheetRowView()
        var taps = 0
        row.onTap = { taps += 1 }
        row.configure(LMKActionSheet.Action(title: "Off", isEnabled: false) {})
        #expect(!row.isEnabled)
        #expect(abs(row.alpha - LMKTheme.current.alpha.disabled) < 0.001)
        #expect(row.accessibilityTraits.contains(.notEnabled))
        row.didTap()
        #expect(taps == 0)
        row.style.disabled = LMKControlStateStyle(alpha: 0.25)
        #expect(abs(row.alpha - 0.25) < 0.001, "the disabled state style sets the alpha")

        row.configure(LMKActionSheet.Action(title: "On") {})
        row.didTap()
        #expect(taps == 1)
        row.isHighlighted = true
        #expect(row.containerView.backgroundColor != LMKColor.backgroundSecondary)
        row.isHighlighted = false
        #expect(row.containerView.backgroundColor === LMKColor.backgroundSecondary)
        row.style.highlightColor = .orange
        row.isHighlighted = true
        #expect(row.containerView.backgroundColor == UIColor.orange)
    }

    @Test
    func `A row answers the minimum touch target while enabled and swallows touches while disabled`() {
        let row = LMKActionSheetRowView(style: LMKActionSheet.RowStyle(minimumHeight: 30))
        row.configure(LMKActionSheet.Action(title: "Short") {})
        row.frame = CGRect(x: 0, y: 0, width: 200, height: 30)
        let outside = CGPoint(x: 100, y: -5)
        #expect(row.point(inside: outside, with: nil), "7pt above a 30pt row is inside the 44pt target")
        row.isEnabled = false
        #expect(!row.point(inside: outside, with: nil))
        #expect(row.point(inside: CGPoint(x: 100, y: 15), with: nil), "a disabled row still takes the touch")
        row.isHidden = true
        #expect(!row.point(inside: CGPoint(x: 100, y: 15), with: nil))
    }

    @Test
    func `Row style and theme.actionSheet.row apply`() {
        let row = LMKActionSheetRowView(style: LMKActionSheet.RowStyle(minimumHeight: 60, titleColor: .purple, iconTint: .orange, checkmarkColor: .cyan, destructiveColor: .brown))
        row.configure(LMKActionSheet.Action(title: "A", icon: UIImage(systemName: "star"), isSelected: true) {})
        #expect(row.titleLabel.textColor == UIColor.purple)
        #expect(row.iconView.tintColor == UIColor.orange)
        #expect(row.checkmarkView.tintColor == UIColor.cyan)
        LMKThemeTesting.fit(row, width: 300)
        #expect(row.bounds.height >= 60)
        row.configure(LMKActionSheet.Action(title: "Delete", style: .destructive) {})
        #expect(row.titleLabel.textColor == UIColor.brown)
        #expect(row.iconView.tintColor == UIColor.brown)
        #expect(LMKActionSheet.RowStyle(disabled: LMKControlStateStyle(alpha: 0.2)).merging(LMKActionSheet.RowStyle()).disabled?.alpha == 0.2)

        var theme = LMKTheme()
        theme.actionSheet = LMKActionSheet.Style(row: LMKActionSheet.RowStyle(subtitleColor: .magenta))
        let themed = LMKActionSheetRowView()
        themed.configure(LMKActionSheet.Action(title: "A", subtitle: "B") {})
        let window = LMKThemeTesting.host(themed, theme: theme)
        defer { window.isHidden = true }
        #expect(themed.subtitleLabel.textColor == UIColor.magenta)
    }
}

// MARK: - Sheet

@MainActor
struct LMKActionSheetTests {
    private func makeHost() -> (UIViewController, UIWindow) {
        let host = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = host
        window.makeKeyAndVisible()
        return (host, window)
    }

    @Test
    func `present builds rows, hides the back button at the root, and is findable`() {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let sheet = LMKActionSheet.present(from: host, title: "Actions", message: "Pick", actions: [
            .init(title: "Edit") {},
            .init(title: "Share", page: LMKActionSheet.Page(title: "Share via")),
            .init(title: "Delete", style: .destructive) {},
        ])
        #expect(host.children.first === sheet)
        #expect(LMKActionSheet.current(in: host) === sheet)
        #expect(sheet.currentRows.count == 3)
        #expect(sheet.currentRows[1].chevronView.isHidden == false)
        #expect(sheet.backButton.isHidden)
        #expect(!sheet.canGoBack)
        #expect(sheet.confirmButton == nil)
        #expect(sheet.cancelButton.title == "Cancel")
    }

    @Test
    func `Configuration with custom content and a confirm button`() {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let picker = UIDatePicker()
        let sheet = LMKActionSheet.present(LMKActionSheet.Configuration(title: "Date", contentView: picker, confirmTitle: "Save", onConfirm: {}), from: host)
        #expect(picker.isDescendant(of: sheet.contentContainerView))
        #expect(sheet.confirmButton?.title == "Save")
        #expect(sheet.confirmButton?.style.variant == .filled)
        #expect(sheet.currentRows.isEmpty)
    }

    @Test
    func `Navigation pushes a sub-page, shows the back button, and pops`() async {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        var events: [String] = []
        let sub = LMKActionSheet.Page(title: "Sub", actions: [.init(title: "One") { events.append("one") }, .init(title: "Two") {}])
        let sheet = LMKActionSheet.present(from: host, title: "Root", actions: [.init(title: "Open", page: sub)])
        sheet.view.layoutIfNeeded()
        sheet.actionTapped(at: 0)
        #expect(sheet.canGoBack)
        #expect(!sheet.backButton.isHidden)
        #expect(sheet.currentPage.title == "Sub")
        #expect(sheet.currentRows.count == 2)
        #expect(host.children.count == 1, "navigation does not dismiss")
        // The second tap of a double tap lands while the page is still sliding: nothing fires.
        sheet.actionTapped(at: 0)
        sheet.confirmTapped()
        #expect(host.children.count == 1, "taps during the slide are ignored")
        await LMKWait.until { sheet.contentContainerView.subviews.count == 1 }
        #expect(events.isEmpty)
        sheet.goBack()
        #expect(!sheet.canGoBack)
        #expect(sheet.currentPage.title == "Root")
        #expect(sheet.currentRows.count == 1)
    }

    @Test
    func `The back button keeps clear of the side safe area`() {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        host.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 62, bottom: 0, right: 62)
        let sheet = LMKActionSheet.present(from: host, title: "Root", actions: [.init(title: "Open", page: LMKActionSheet.Page(title: "Sub"))])
        sheet.view.layoutIfNeeded()
        sheet.actionTapped(at: 0)
        sheet.view.layoutIfNeeded()
        #expect(abs(sheet.backButton.frame.minX - (62 + LMKSpacing.small)) < 0.5, "\(sheet.backButton.frame)")
    }

    @Test
    func `Action and confirm handlers run after the sheet has gone; cancellation calls onCancel`() async {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        var events: [String] = []
        let sheet = LMKActionSheet.present(LMKActionSheet.Configuration(
            title: "T",
            actions: [.init(title: "A") { events.append("action") }, .init(title: "Off", isEnabled: false) { events.append("disabled") }],
            confirmTitle: "Save",
            onConfirm: { events.append("confirm") },
            onCancel: { events.append("cancel") }
        ), from: host)
        sheet.actionTapped(at: 1)
        #expect(events.isEmpty, "a disabled action does nothing")
        sheet.actionTapped(at: 0)
        #expect(events.isEmpty, "handlers wait for the dismissal")
        await LMKWait.until { !events.isEmpty }
        #expect(events == ["action"])
        #expect(host.children.isEmpty)

        let second = LMKActionSheet.present(LMKActionSheet.Configuration(title: "T", confirmTitle: "Save", onConfirm: { events.append("confirm") }, onCancel: { events.append("cancel") }), from: host)
        second.confirmTapped()
        await LMKWait.until { events.count == 2 }
        #expect(events == ["action", "confirm"])

        let third = LMKActionSheet.present(LMKActionSheet.Configuration(title: "T", onCancel: { events.append("cancel") }), from: host)
        third.dismiss(reason: .dimmingTap)
        await LMKWait.until { events.count == 3 }
        #expect(events == ["action", "confirm", "cancel"])
    }

    @Test
    func `Subtitled rows keep their content height when the sheet overflows its cap`() {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let sheet = LMKActionSheet.present(from: host, title: "Pick", actions: (0 ..< 30).map { index in
            .init(title: "Trip \(index)", subtitle: "Jun 6 to 8, 2026", icon: UIImage(systemName: "suitcase")) {}
        })
        sheet.view.layoutIfNeeded()
        #expect(sheet.currentRows.count == 30)
        for row in sheet.currentRows {
            #expect(row.frame.height > LMKActionSheetRowView.defaultMinimumHeight)
            #expect(row.subtitleLabel.frame.height > 8)
        }
    }

    private func labels(in view: UIView) -> [UILabel] {
        var found: [UILabel] = []
        if let label = view as? UILabel { found.append(label) }
        for subview in view.subviews {
            found.append(contentsOf: labels(in: subview))
        }
        return found
    }

    @Test
    func `Style flows from the configuration and the theme into the chrome, the root page, and the rows`() {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let style = LMKActionSheet.Style(
            sheet: LMKBottomSheetViewController.Style(surface: LMKSurfaceStyle(contentInsets: .lmk_all(30)), showsDragIndicator: false),
            row: LMKActionSheet.RowStyle(titleColor: .purple),
            titleTextStyle: .h1,
            titleColor: .green,
            messageTextStyle: .small,
            messageColor: .orange,
            confirmButton: LMKButton.Style(minimumHeight: 64),
            sectionSpacing: 24,
            rowSpacing: 9,
            pageTransitionDuration: 0.01
        )
        let sheet = LMKActionSheet.present(
            LMKActionSheet.Configuration(title: "T", message: "M", actions: [.init(title: "A") {}, .init(title: "B") {}], confirmTitle: "Go", onConfirm: {}, style: style),
            from: host
        )
        sheet.view.layoutIfNeeded()
        #expect(sheet.dragIndicator.isHidden)
        #expect(sheet.currentRows[0].titleLabel.textColor == UIColor.purple)
        #expect(sheet.resolvedActionSheetStyle.titleColor == UIColor.green)
        let title = labels(in: sheet.contentContainerView).first { $0.text == "T" }
        let message = labels(in: sheet.contentContainerView).first { $0.text == "M" }
        #expect(title?.textColor == UIColor.green, "the root page is built from the resolved style")
        #expect(title?.font.pointSize == LMKTypography.font(for: .h1, compatibleWith: sheet.traitCollection).pointSize)
        #expect(message?.textColor == UIColor.orange)
        #expect(message?.font.pointSize == LMKTypography.font(for: .small, compatibleWith: sheet.traitCollection).pointSize)
        #expect(sheet.confirmButton?.style.minimumHeight == 64)
        let rowA = sheet.currentRows[0].convert(sheet.currentRows[0].bounds, to: sheet.view)
        let rowB = sheet.currentRows[1].convert(sheet.currentRows[1].bounds, to: sheet.view)
        #expect(abs(rowB.minY - rowA.maxY - 9) < 0.5, "rowSpacing")
        #expect(abs(rowA.minX - 30) < 0.5, "the sheet's content inset reaches the rows")
        if let message {
            let messageFrame = message.convert(message.bounds, to: sheet.view)
            #expect(abs(rowA.minY - messageFrame.maxY - 24) < 0.5, "sectionSpacing")
        }

        var theme = LMKTheme()
        theme.actionSheet = LMKActionSheet.Style(sheet: LMKBottomSheetViewController.Style(dimmingColor: .magenta, dimmingAlpha: 1), titleColor: .brown)
        sheet.applyTheme(theme)
        #expect(sheet.dimmingView.backgroundColor == UIColor.magenta.withAlphaComponent(1))
        #expect(labels(in: sheet.contentContainerView).first { $0.text == "T" }?.textColor == UIColor.green, "the configuration still wins over the theme")

        let themed = LMKActionSheet.present(LMKActionSheet.Configuration(title: "T", actions: [.init(title: "A") {}]), from: host)
        themed.applyTheme(theme)
        #expect(labels(in: themed.contentContainerView).first { $0.text == "T" }?.textColor == UIColor.brown, "a theme change re-renders the page")
    }

    @Test
    func `The presented sheet's own style layers on top and sticks`() {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let sheet = LMKActionSheet.present(LMKActionSheet.Configuration(title: "T", style: LMKActionSheet.Style(sheet: LMKBottomSheetViewController.Style(dimmingAlpha: 0.9))), from: host)
        var applied = 0
        sheet.didApplyStyle = { _ in applied += 1 }
        sheet.style.showsCancelButton = false
        #expect(sheet.cancelButton.isHidden, "the instance style is not overwritten by the configuration's")
        #expect(sheet.resolvedStyle.dimmingAlpha == 0.9, "the configuration's sheet style still applies")
        #expect(applied == 1, "one applyTheme per style change")
    }
}
