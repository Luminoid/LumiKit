//
//  LMKNavigationBarTests.swift
//  LumiKit
//

import SnapKit
import Testing
import UIKit
@testable import LumiKitUI

// MARK: - LMKNavigationBarItem

@MainActor
struct LMKNavigationBarItemTests {
    @Test
    func `Initializers keep image, title, label, and action`() {
        var called = false
        let image = LMKNavigationBarItem(image: UIImage(systemName: "plus"), title: "Add", accessibilityLabel: "Add item") { called = true }
        #expect(image.image != nil)
        #expect(image.title == "Add")
        #expect(image.accessibilityLabel == "Add item")
        image.action?()
        #expect(called)

        let symbol = LMKNavigationBarItem(systemName: "gear", accessibilityLabel: "Settings") {}
        #expect(symbol.image != nil)
        #expect(symbol.title == nil)
        #expect(symbol.accessibilityLabel == "Settings")

        let text = LMKNavigationBarItem(title: "Done") {}
        #expect(text.image == nil)
        #expect(text.accessibilityLabel == "Done", "a text item reads its title")
        #expect(LMKNavigationBarItem(title: "Save", accessibilityLabel: "Save changes") {}.accessibilityLabel == "Save changes")
    }

    @Test
    func `Defaults and identity`() {
        let item = LMKNavigationBarItem(systemName: "plus")
        #expect(item.role == .plain)
        #expect(item.isEnabled)
        #expect(item.menu == nil)
        #expect(item.badge == nil)
        #expect(item.action == nil)
        #expect(!item.identifier.isEmpty)

        let a = LMKNavigationBarItem(identifier: "x", title: "A")
        let b = LMKNavigationBarItem(identifier: "x", title: "B")
        #expect(a == b, "items compare by identifier")
        #expect(Set([a, b]).count == 1)
        #expect(LMKNavigationBarItem(systemName: "plus") != LMKNavigationBarItem(systemName: "plus"), "generated identifiers differ")
    }
}

// MARK: - LMKNavigationBar

@MainActor
struct LMKNavigationBarTests {
    private func near(_ a: CGFloat, _ b: CGFloat) -> Bool {
        abs(a - b) < 0.01
    }

    @Test
    func `Default state`() {
        let bar = LMKNavigationBar()
        #expect(bar.title == nil)
        #expect(bar.subtitle == nil)
        #expect(!bar.largeTitleEnabled)
        #expect(!bar.showsBackButton)
        #expect(bar.onBack == nil)
        #expect(bar.leftItems.isEmpty)
        #expect(bar.rightItems.isEmpty)
        #expect(bar.backgroundColor === LMKColor.backgroundPrimary)
        #expect(bar.backButton.accessibilityLabel == "Back")
        #expect(bar.titleLabel.accessibilityTraits.contains(.header))
    }

    @Test
    func `Title and subtitle feed both modes`() {
        let bar = LMKNavigationBar()
        bar.title = "Pets"
        #expect(bar.titleLabel.text == "Pets")
        #expect(bar.largeTitleLabel.text == "Pets")
        #expect(bar.subtitleLabel.isHidden)
        bar.subtitle = "3 due"
        #expect(bar.subtitleLabel.text == "3 due")
        #expect(!bar.subtitleLabel.isHidden)
        #expect(!bar.largeSubtitleLabel.isHidden)
        #expect(bar.titleLabel.accessibilityLabel == "Pets, 3 due")
        bar.subtitle = nil
        #expect(bar.largeSubtitleLabel.isHidden)
        bar.title = nil
        #expect(bar.titleLabel.text == nil)
    }

    @Test
    func `Large title mode swaps rows and grows the intrinsic height`() {
        let bar = LMKNavigationBar()
        let inline = bar.intrinsicContentSize.height
        #expect(near(inline, 44 + bar.separatorThickness))
        #expect(!bar.titleStack.isHidden)
        #expect(bar.largeTitleRow.isHidden)
        bar.largeTitleEnabled = true
        #expect(bar.titleStack.isHidden)
        #expect(!bar.largeTitleRow.isHidden)
        #expect(near(bar.intrinsicContentSize.height, inline + 52))
        bar.largeTitleEnabled = false
        #expect(near(bar.intrinsicContentSize.height, inline))
    }

    @Test
    func `Back button shows unless left items are set, and pops or calls onBack`() {
        let bar = LMKNavigationBar()
        #expect(bar.backButton.isHidden)
        bar.showsBackButton = true
        #expect(!bar.backButton.isHidden)
        bar.setLeftItems([.init(title: "Edit") {}])
        #expect(bar.backButton.isHidden, "left items replace the back button")
        #expect(bar.showsBackButton)
        bar.setLeftItems([])
        #expect(!bar.backButton.isHidden)
        #expect(bar.leftItemsStack.isHidden)

        var backs = 0
        bar.onBack = { backs += 1 }
        bar.backButton.didTap()
        #expect(backs == 1)
    }

    @Test
    func `Items render as buttons with content, state, menu, and role styles`() {
        let bar = LMKNavigationBar(style: LMKNavigationBar.Style(appearance: .classic))
        var added = false
        let menu = UIMenu(children: [UIAction(title: "One") { _ in }])
        bar.setRightItems([
            .init(identifier: "add", systemName: "plus", accessibilityLabel: "Add") { added = true },
            .init(identifier: "more", systemName: "ellipsis", menu: menu),
            .init(identifier: "save", title: "Save", role: .prominent),
            .init(identifier: "delete", title: "Delete", role: .destructive, isEnabled: false),
        ])
        #expect(bar.rightItemButtons.count == 4)
        #expect(bar.rightItemsStack.arrangedSubviews.count == 4)
        let add = bar.button(forItem: "add")
        #expect(add?.accessibilityLabel == "Add")
        #expect(add?.accessibilityIdentifier == "add")
        #expect(add?.image != nil)
        add?.didTap()
        #expect(added)

        let more = bar.button(forItem: "more")
        #expect(more?.menu?.identifier == menu.identifier, "UIKit may hand back a copy of the menu")
        #expect(more?.showsMenuAsPrimaryAction == true)

        let save = bar.button(forItem: "save")
        #expect(save?.title == "Save")
        #expect(save?.style.variant == .filled)

        let delete = bar.button(forItem: "delete")
        #expect(delete?.isEnabled == false)
        #expect(delete?.style.tintColor === LMKColor.error)
        #expect(bar.button(forItem: "missing") == nil)
    }

    @Test
    func `A badge stays inside the bar, whatever the row height`() throws {
        for subtitle in [nil, "3 unread"] {
            let bar = LMKNavigationBar()
            bar.title = "Inbox"
            bar.subtitle = subtitle
            bar.setRightItems([
                .init(identifier: "compose", systemName: "square.and.pencil", badge: .count(3)),
                .init(identifier: "done", title: "Done", role: .prominent),
            ])
            // A host that clips: a card with rounded corners around the bar.
            let host = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 80))
            host.clipsToBounds = true
            host.addSubview(bar)
            bar.snp.makeConstraints { $0.edges.equalToSuperview() }
            host.layoutIfNeeded()

            let badge = try #require(bar.badgeViews["compose"])
            let frame = badge.convert(badge.bounds, to: bar)
            #expect(frame.minY >= 0, "the top of the badge was cut by the host (subtitle: \(subtitle ?? "none"))")
            #expect(frame.maxX <= bar.bounds.width)
            let intrinsic = badge.intrinsicContentSize
            #expect(abs(frame.width - intrinsic.width) < 0.5 && abs(frame.height - intrinsic.height) < 0.5, "frame \(frame), intrinsic \(intrinsic)")
            // Still on the item's top trailing corner.
            let button = try #require(bar.rightItemButtons.first)
            let item = button.convert(button.bounds, to: bar)
            #expect(frame.midX > item.midX)
            #expect(frame.midY < item.midY)
            #expect(frame.intersects(item))
        }
    }

    @Test
    func `Replacing items rebuilds the buttons and drops stale badges`() {
        let bar = LMKNavigationBar()
        bar.setRightItems([.init(identifier: "a", systemName: "plus", badge: .count(3))])
        #expect(bar.badgeViews["a"] != nil)
        #expect(bar.badgeViews["a"]?.countLabel.text == "3")
        #expect(bar.badgeViews["a"]?.superview === bar.buttonRow)
        let first = bar.rightItemButtons[0]
        bar.setRightItems([.init(identifier: "b", systemName: "gear")])
        #expect(first.superview == nil)
        #expect(bar.badgeViews["a"] == nil)
        #expect(bar.rightItemButtons.count == 1)
        bar.setRightItems([])
        #expect(bar.rightItemsStack.arrangedSubviews.isEmpty)
    }

    @Test
    func `updateItem mutates one item and re-renders its button in place`() {
        let bar = LMKNavigationBar()
        bar.setLeftItems([.init(identifier: "edit", title: "Edit")])
        bar.setRightItems([.init(identifier: "add", systemName: "plus")])
        let button = bar.button(forItem: "add")
        #expect(bar.updateItem("add") { $0.isEnabled = false; $0.badge = .dot })
        #expect(bar.button(forItem: "add") === button, "the same button is reused")
        #expect(button?.isEnabled == false)
        #expect(bar.item(withIdentifier: "add")?.isEnabled == false)
        #expect(bar.badgeViews["add"] != nil)
        #expect(bar.updateItem("add") { $0.badge = nil })
        #expect(bar.badgeViews["add"] == nil)
        #expect(bar.updateItem("edit") { $0.title = "Done" })
        #expect(bar.button(forItem: "edit")?.title == "Done")
        #expect(!bar.updateItem("nope") { $0.isEnabled = false })
    }

    @Test
    func `Item buttons meet the minimum touch target`() {
        let bar = LMKNavigationBar()
        bar.setLeftItems([.init(title: "A")])
        bar.setRightItems([.init(systemName: "plus")])
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 100))
        bar.install(in: host)
        host.layoutIfNeeded()
        for button in bar.leftItemButtons + bar.rightItemButtons {
            #expect(button.bounds.width >= 44)
            #expect(button.bounds.height >= 44)
        }
        #expect(bar.backButton.bounds.size == CGSize(width: 44, height: 44))
    }

    @Test
    func `Accessory views live outside the item stacks`() {
        let bar = LMKNavigationBar()
        bar.setRightItems([.init(systemName: "plus") {}])
        let indicator = UIActivityIndicatorView()
        bar.setRightAccessoryView(indicator)
        #expect(indicator.superview === bar.buttonRow)
        bar.setRightItems([.init(systemName: "plus") {}, .init(systemName: "ellipsis") {}])
        #expect(indicator.superview === bar.buttonRow, "survives setRightItems")
        let second = UIView()
        bar.setRightAccessoryView(second)
        #expect(indicator.superview == nil)
        #expect(second.superview === bar.buttonRow)
        bar.setRightAccessoryView(nil)
        #expect(second.superview == nil)

        bar.title = "Pets"
        bar.largeTitleEnabled = true
        let badge = UIView()
        bar.setLargeTitleAccessoryView(badge)
        #expect(badge.superview === bar.largeTitleRow)
        bar.setLargeTitleAccessoryView(nil)
        #expect(badge.superview == nil)
    }

    @Test
    func `install pins the bar to the top of its parent once`() {
        let parent = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let bar = LMKNavigationBar()
        bar.title = "Items"
        bar.install(in: parent)
        bar.install(in: parent)
        parent.layoutIfNeeded()
        #expect(bar.superview === parent)
        #expect(bar.frame.minY == 0)
        #expect(bar.frame.width == 390)
        #expect(near(bar.frame.height, 44 + bar.separatorThickness))
        #expect(parent.constraints.count(where: { $0.firstItem === bar && $0.firstAttribute == .top }) == 1)
    }

    @Test
    func `pinScrollView places the scroll view below the bar or under it with a tracking inset`() {
        let parent = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let bar = LMKNavigationBar()
        bar.install(in: parent)
        let below = UIScrollView()
        parent.addSubview(below)
        below.snp.makeConstraints { $0.leading.trailing.bottom.equalToSuperview() }
        bar.pinScrollView(below)
        parent.layoutIfNeeded()
        #expect(near(below.frame.minY, bar.frame.maxY))
        #expect(!bar.hasScrollEdgeEffect)

        let under = UIScrollView()
        parent.addSubview(under)
        under.snp.makeConstraints { $0.leading.trailing.bottom.equalToSuperview() }
        bar.pinScrollView(under, edgeEffect: true)
        parent.layoutIfNeeded()
        #expect(under.frame.minY == 0)
        #expect(near(under.contentInset.top, bar.bounds.height))
        #expect(near(under.contentOffset.y, -bar.bounds.height))
        #expect(under.contentInsetAdjustmentBehavior == .never)
        if #available(iOS 26, *) {
            #expect(bar.hasScrollEdgeEffect)
            let interactions = bar.interactions.compactMap { $0 as? UIScrollEdgeElementContainerInteraction }
            #expect(interactions.count == 1)
            #expect(interactions.first?.scrollView === under)
            #expect(interactions.first?.edge == .top)
        }
        bar.largeTitleEnabled = true
        parent.layoutIfNeeded()
        #expect(near(under.contentInset.top, bar.bounds.height), "the inset follows the bar height")
        bar.detachScrollEdgeEffect()
        #expect(!bar.hasScrollEdgeEffect)
    }

    @Test
    func `Style controls colors, separator, metrics, and large title alignment`() {
        let bar = LMKNavigationBar(style: LMKNavigationBar.Style(
            surface: LMKSurfaceStyle(background: .solid(.red)),
            tintColor: .white,
            titleColor: .yellow,
            largeTitleColor: .green,
            showsSeparator: false,
            buttonRowHeight: 50,
            largeTitleRowHeight: 60,
            contentMargin: 20,
            largeTitleAlignment: .center
        ))
        bar.title = "T"
        bar.setRightItems([.init(systemName: "plus")])
        #expect(bar.backgroundColor == UIColor.red)
        #expect(bar.titleLabel.textColor == UIColor.yellow)
        #expect(bar.largeTitleLabel.textColor == UIColor.green)
        #expect(bar.rightItemButtons[0].style.tintColor == UIColor.white)
        #expect(bar.backButton.style.tintColor == UIColor.white)
        #expect(bar.separatorView.isHidden)
        #expect(bar.buttonRowHeight == 50)
        #expect(bar.largeTitleRowHeight == 60)
        #expect(bar.largeTitleStack.alignment == .center)
        #expect(bar.largeTitleLabel.textAlignment == .center)

        let parent = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        bar.install(in: parent)
        parent.layoutIfNeeded()
        #expect(near(bar.rightItemsStack.frame.maxX, 370))
        bar.style.showsSeparator = true
        bar.style.separatorColor = .blue
        bar.style.separatorThickness = 2
        #expect(!bar.separatorView.isHidden)
        #expect(bar.separatorView.backgroundColor == UIColor.blue)
        #expect(bar.separatorThickness == 2)
    }

    @Test
    func `theme.navigationBar supplies app-wide defaults`() {
        var theme = LMKTheme()
        theme.navigationBar = LMKNavigationBar.Style(tintColor: .magenta, titleColor: .purple)
        let bar = LMKNavigationBar()
        bar.title = "Themed"
        bar.setRightItems([.init(systemName: "plus")])
        let window = LMKThemeTesting.host(bar, theme: theme)
        defer { window.isHidden = true }
        #expect(bar.titleLabel.textColor == UIColor.purple)
        #expect(bar.rightItemButtons[0].style.tintColor == UIColor.magenta)
    }

    @Test
    func `Dynamic Type raises the row floors`() {
        let bar = LMKNavigationBar()
        bar.title = "Items"
        bar.subtitle = "Sub"
        let window = LMKThemeTesting.host(bar)
        defer { window.isHidden = true }
        let inlineFloor = bar.buttonRowHeight
        let largeFloor = bar.largeTitleRowHeight
        window.traitOverrides.preferredContentSizeCategory = .accessibilityExtraExtraExtraLarge
        bar.updateTraitsIfNeeded()
        #expect(bar.buttonRowHeight > inlineFloor)
        #expect(bar.largeTitleRowHeight > largeFloor)
        #expect(bar.titleLabel.font.pointSize > 17)
    }
}

// MARK: - Appearance

@MainActor
struct LMKNavigationBarAppearanceTests {
    private static func makeBar(_ appearance: LMKNavigationBar.Appearance?) -> (UIView, LMKNavigationBar) {
        let bar = LMKNavigationBar(style: LMKNavigationBar.Style(appearance: appearance))
        bar.title = "Items"
        let parent = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        bar.install(in: parent)
        return (parent, bar)
    }

    @Test
    func `Automatic follows the OS and classic pins the older look`() {
        let (_, automatic) = Self.makeBar(nil)
        if #available(iOS 26, *) {
            #expect(automatic.resolvedAppearance == .glass)
        } else {
            #expect(automatic.resolvedAppearance == .classic)
        }
        let (_, classic) = Self.makeBar(.classic)
        #expect(classic.resolvedAppearance == .classic)
        #expect(LMKNavigationBar.Appearance.allCases.count == 3)
    }

    @Test
    func `Classic: tinted items over a hairline, no glass`() {
        let (parent, bar) = Self.makeBar(.classic)
        bar.showsBackButton = true
        bar.setRightItems([.init(identifier: "add", systemName: "plus"), .init(identifier: "save", title: "Save", role: .prominent)])
        parent.layoutIfNeeded()
        #expect(bar.itemGlassViews.isEmpty)
        #expect(!bar.separatorView.isHidden)
        #expect(bar.backButton.style.tintColor === LMKColor.primary)
        #expect(bar.rightItemButtons[0].style.tintColor === LMKColor.primary)
        #expect(bar.rightItemButtons[1].style.variant == .filled)
        #expect(bar.rightItemsStack.spacing == LMKSpacing.xs)
        #expect(abs(bar.backButton.frame.minX - LMKSpacing.small) < 0.5)
    }

    @Test
    func `Glass: neighbours share a capsule, a prominent item takes its own, and the hairline goes`() throws {
        guard #available(iOS 26, *) else { return }
        let (parent, bar) = Self.makeBar(.glass)
        bar.showsBackButton = true
        bar.setRightItems([
            .init(identifier: "share", systemName: "square.and.arrow.up"),
            .init(identifier: "edit", systemName: "pencil"),
            .init(identifier: "save", title: "Save", role: .prominent),
        ])
        parent.layoutIfNeeded()

        #expect(bar.separatorView.isHidden)
        #expect(bar.itemGlassViews.count == 3, "share + edit, save, and the back chevron")
        #expect(bar.itemGlassViews.allSatisfy { !$0.isUserInteractionEnabled }, "the items take the touches")

        let share = try #require(bar.button(forItem: "share"))
        let edit = try #require(bar.button(forItem: "edit"))
        let save = try #require(bar.button(forItem: "save"))
        let shared = try #require(bar.itemGlassViews.first)
        let sharedFrame = shared.frame
        let shareFrame = share.convert(share.bounds, to: bar.buttonRow)
        let editFrame = edit.convert(edit.bounds, to: bar.buttonRow)
        let saveFrame = save.convert(save.bounds, to: bar.buttonRow)
        #expect(abs(sharedFrame.minX - shareFrame.minX) < 0.5)
        #expect(abs(sharedFrame.maxX - editFrame.maxX) < 0.5)
        #expect(abs(shareFrame.maxX - editFrame.minX) < 0.5, "items inside one capsule touch")
        #expect(abs(saveFrame.minX - editFrame.maxX - LMKSpacing.small) < 0.5, "capsules keep a gap")

        // The label color inside plain capsules; the prominent capsule carries the tint.
        #expect(share.style.tintColor === LMKColor.textPrimary)
        #expect(bar.backButton.style.tintColor === LMKColor.textPrimary)
        #expect(save.style.variant == .ghost)
        #expect(bar.itemGlassViews[1].style.tintColor === LMKColor.primary)
        #expect(bar.itemGlassViews[0].style.tintColor == nil)

        // The chevron's circle starts at the content margin.
        #expect(abs(bar.backButton.frame.minX - LMKSpacing.large) < 0.5)
        #expect(abs(bar.itemGlassViews[2].frame.width - LMKLayout.minimumTouchTarget) < 0.5)
    }

    @Test
    func `Glass capsules follow the items as they change`() {
        guard #available(iOS 26, *) else { return }
        let (_, bar) = Self.makeBar(.glass)
        #expect(bar.itemGlassViews.isEmpty)
        bar.setRightItems([.init(identifier: "add", systemName: "plus")])
        #expect(bar.itemGlassViews.count == 1)
        bar.setLeftItems([.init(identifier: "close", title: "Close")])
        #expect(bar.itemGlassViews.count == 2)
        bar.showsBackButton = true
        #expect(bar.itemGlassViews.count == 2, "left items replace the back button")
        bar.setLeftItems([])
        #expect(bar.itemGlassViews.count == 2, "the back button returns with its circle")
        bar.updateItem("add") { $0.role = .prominent }
        #expect(bar.itemGlassViews.first?.style.tintColor === LMKColor.primary)
        bar.style.appearance = .classic
        #expect(bar.itemGlassViews.isEmpty)
        #expect(!bar.separatorView.isHidden)
    }

    @Test
    func `Items group the way the system shares backgrounds`() {
        let items: [LMKNavigationBarItem] = [
            .init(identifier: "a", systemName: "plus"),
            .init(identifier: "b", systemName: "pencil"),
            .init(identifier: "c", title: "Save", role: .prominent),
            .init(identifier: "d", title: "Delete", role: .destructive),
            .init(identifier: "e", systemName: "ellipsis"),
        ]
        let groups = LMKNavigationBar.groups(for: items)
        #expect(groups.map(\.range) == [0 ..< 2, 2 ..< 3, 3 ..< 5])
        #expect(groups.map(\.isProminent) == [false, true, false])
        #expect(LMKNavigationBar.groups(for: []).isEmpty)
    }

    @Test
    func `A custom tint and separator still win on glass`() {
        guard #available(iOS 26, *) else { return }
        let bar = LMKNavigationBar(style: LMKNavigationBar.Style(appearance: .glass, tintColor: .systemOrange, showsSeparator: true))
        bar.setRightItems([.init(identifier: "add", systemName: "plus"), .init(identifier: "save", title: "Save", role: .prominent)])
        #expect(bar.rightItemButtons[0].style.tintColor == UIColor.systemOrange)
        #expect(!bar.separatorView.isHidden)
        #expect(bar.itemGlassViews.last?.style.tintColor == UIColor.systemOrange)
    }
}
