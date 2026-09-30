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

        row.configure(LMKActionSheet.Action(title: "On") {})
        row.didTap()
        #expect(taps == 1)
        row.isHighlighted = true
        #expect(row.containerView.backgroundColor != LMKColor.backgroundSecondary)
        row.isHighlighted = false
        #expect(row.containerView.backgroundColor === LMKColor.backgroundSecondary)
    }

    @Test
    func `Row style and theme.actionSheet.row apply`() {
        let row = LMKActionSheetRowView(style: LMKActionSheet.RowStyle(minimumHeight: 60, titleColor: .purple, iconTint: .orange))
        row.configure(LMKActionSheet.Action(title: "A", icon: UIImage(systemName: "star")) {})
        #expect(row.titleLabel.textColor == UIColor.purple)
        #expect(row.iconView.tintColor == UIColor.orange)
        LMKThemeTesting.fit(row, width: 300)
        #expect(row.bounds.height >= 60)

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
        let sub = LMKActionSheet.Page(title: "Sub", actions: [.init(title: "One") {}, .init(title: "Two") {}])
        let sheet = LMKActionSheet.present(from: host, title: "Root", actions: [.init(title: "Open", page: sub)])
        sheet.view.layoutIfNeeded()
        sheet.actionTapped(at: 0)
        #expect(sheet.canGoBack)
        #expect(!sheet.backButton.isHidden)
        #expect(sheet.currentPage.title == "Sub")
        #expect(sheet.currentRows.count == 2)
        #expect(host.children.count == 1, "navigation does not dismiss")
        await LMKWait.until { sheet.contentContainerView.subviews.count == 1 }
        sheet.goBack()
        #expect(!sheet.canGoBack)
        #expect(sheet.currentPage.title == "Root")
        #expect(sheet.currentRows.count == 1)
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

    @Test
    func `Style flows from the configuration and the theme into the chrome and rows`() {
        let (host, window) = makeHost()
        defer { window.isHidden = true }
        let style = LMKActionSheet.Style(
            sheet: LMKBottomSheetViewController.Style(showsDragIndicator: false),
            row: LMKActionSheet.RowStyle(titleColor: .purple),
            titleColor: .green
        )
        let sheet = LMKActionSheet.present(LMKActionSheet.Configuration(title: "T", actions: [.init(title: "A") {}], style: style), from: host)
        #expect(sheet.dragIndicator.isHidden)
        #expect(sheet.currentRows[0].titleLabel.textColor == UIColor.purple)
        #expect(sheet.resolvedActionSheetStyle.titleColor == UIColor.green)

        var theme = LMKTheme()
        theme.actionSheet = LMKActionSheet.Style(sheet: LMKBottomSheetViewController.Style(dimmingColor: .magenta, dimmingAlpha: 1))
        sheet.applyTheme(theme)
        #expect(sheet.dimmingView.backgroundColor == UIColor.magenta.withAlphaComponent(1))
    }
}
